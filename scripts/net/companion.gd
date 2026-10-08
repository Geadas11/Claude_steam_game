extends Node
## "O teu telemóvel": the player's own phone becomes the phone of the game.
##
## When the player chooses their own phone at the start of a session, the
## in-game phone is rendered off-screen (see Main.set_phone_mode) and this
## node streams it to the player's phone as JPEG frames over a WebSocket on the
## local network. Touches, typing and the back gesture come back and are
## applied to the in-game phone, so every app works exactly as in the game.
## The page (companion/index.html) runs in the phone's browser, full screen;
## the game never reads anything from the real phone.

signal clients_changed(count: int)

const HTTP_PORT := 8317
const WS_PORT := 8417
const PAGE := "res://companion/index.html"
const FPS_ACTIVE := 20.0     # right after a touch
const FPS_IDLE := 8.0
const JPEG_QUALITY := 0.82

var running := false
var persist_token := true   # tests turn this off (no writes to the player's settings)
var http_port := 0
var ws_port := 0
var token := ""
## The SubViewport holding the in-game phone while it is streamed (null = not streaming).
var stream_vp: SubViewport
## Called when the phone's back gesture is used (set by Main).
var on_back: Callable

var _http: TCPServer
var _ws: TCPServer
var _http_conns: Array = []   # [{peer, buf, t}]
var _pending_ws: Array = []   # WebSocketPeer not yet authenticated
var _clients: Array = []      # authenticated WebSocketPeer
var _page_cache := ""
var _icon_cache := {}

# streaming
var _last_capture := 0
var _last_input := -100000
var _last_raw := PackedByteArray()
var _encoding := false
var _frame_task := -1
var _frame_out := PackedByteArray()
var _need_full := false       # a new client needs a frame even if nothing changed
var frames_sent := 0

# remote touch
var _t_down := false
var _t_start := Vector2.ZERO
var _t_last := Vector2.ZERO
var _t_mode := ""             # "" (maybe a tap), "scroll", "drag"
var _t_scroll: ScrollContainer
var _t_last_tap := 0
var _t_last_tap_pos := Vector2.ZERO
var _kbd_owner: Control


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Events.notification_posted.connect(func(n): broadcast({"t": "notif", "app": str(n.get("app", ""))}))
	Events.call_incoming.connect(func(_c): broadcast({"t": "ring", "on": true}))
	Events.call_started.connect(func(_c): broadcast({"t": "ring", "on": false}))
	Events.call_ended.connect(func(_c): broadcast({"t": "ring", "on": false}))
	Events.vibrate_requested.connect(func(n): broadcast({"t": "vibrate", "n": n}))
	Events.glitch_requested.connect(func(_i, _d): broadcast({"t": "vibrate", "n": 1}))


# ================================================================= lifecycle
func start() -> bool:
	if running:
		return true
	# a stable code lets an already-paired phone reconnect after a restart
	token = str(Settings.get_value("companion_token", "")) if persist_token else ""
	if token == "":
		token = "%08x" % (randi() & 0x7fffffff)
		if persist_token:
			Settings.set_value("companion_token", token)
	_http = TCPServer.new()
	_ws = TCPServer.new()
	http_port = _listen(_http, HTTP_PORT)
	ws_port = _listen(_ws, WS_PORT)
	if http_port == 0 or ws_port == 0:
		stop()
		return false
	running = true
	return true


func stop() -> void:
	for c in _clients:
		c.close()
	_clients.clear()
	_pending_ws.clear()
	_http_conns.clear()
	if _http:
		_http.stop()
	if _ws:
		_ws.stop()
	running = false
	clients_changed.emit(0)


func _listen(server: TCPServer, base: int) -> int:
	for p in range(base, base + 10):
		if server.listen(p, "*") == OK:
			return p
	return 0


func client_count() -> int:
	return _clients.size()


## The address the phone should open (best guess of this PC's LAN address).
func url() -> String:
	return "http://%s:%d/?k=%s" % [lan_ip(), http_port, token]


static func lan_ip() -> String:
	var best := ""
	var best_rank := 99
	for a in IP.get_local_addresses():
		if a.contains(":") or a.begins_with("127.") or a.begins_with("169.254."):
			continue
		var rank := 3
		if a.begins_with("192.168."):
			rank = 0
		elif a.begins_with("10."):
			rank = 1
		elif a.begins_with("172."):
			var second := int(a.split(".")[1])
			rank = 2 if second >= 16 and second <= 31 else 3
		if rank < best_rank:
			best_rank = rank
			best = a
	return best if best != "" else "127.0.0.1"


# ================================================================= polling
func _process(_delta: float) -> void:
	if not running:
		return
	_poll_http()
	_poll_ws()
	_stream()


func _poll_http() -> void:
	while _http.is_connection_available():
		_http_conns.append({"peer": _http.take_connection(), "buf": "", "t": Time.get_ticks_msec()})
	for c in _http_conns.duplicate():
		var peer: StreamPeerTCP = c.peer
		peer.poll()
		if peer.get_status() != StreamPeerTCP.STATUS_CONNECTED or Time.get_ticks_msec() - int(c.t) > 5000:
			_http_conns.erase(c)
			continue
		var n := peer.get_available_bytes()
		if n > 0:
			c.buf += peer.get_utf8_string(n)
		if c.buf.contains("\r\n\r\n"):
			_serve(peer, c.buf)
			peer.disconnect_from_host()
			_http_conns.erase(c)


func _serve(peer: StreamPeerTCP, request: String) -> void:
	var first := request.get_slice("\r\n", 0)
	var path := first.get_slice(" ", 1).get_slice("?", 0)
	var body: PackedByteArray
	var ctype := "text/html; charset=utf-8"
	var status := "200 OK"
	match path:
		"/", "/index.html":
			body = _page().to_utf8_buffer()
		"/manifest.webmanifest":
			ctype = "application/manifest+json"
			body = JSON.stringify({
				"name": "Ainda estás acordado?", "short_name": "Acordado?",
				"display": "fullscreen", "orientation": "portrait",
				"background_color": "#000000", "theme_color": "#000000",
				"start_url": "/", "icons": [
					{"src": "/icon-192.png", "sizes": "192x192", "type": "image/png"},
					{"src": "/icon-512.png", "sizes": "512x512", "type": "image/png"}],
			}).to_utf8_buffer()
		"/icon-192.png", "/icon-512.png", "/apple-touch-icon.png":
			ctype = "image/png"
			body = _icon(512 if path == "/icon-512.png" else (180 if path == "/apple-touch-icon.png" else 192))
		"/favicon.ico":
			status = "204 No Content"
			body = PackedByteArray()
		_:
			status = "404 Not Found"
			ctype = "text/plain"
			body = "404".to_utf8_buffer()
	var cache := "no-store" if ctype.begins_with("text/") else "max-age=3600"
	var head := "HTTP/1.1 %s\r\nContent-Type: %s\r\nContent-Length: %d\r\nCache-Control: %s\r\nConnection: close\r\n\r\n" % [status, ctype, body.size(), cache]
	peer.put_data(head.to_utf8_buffer())
	if body.size() > 0:
		peer.put_data(body)


func _page() -> String:
	if _page_cache == "":
		_page_cache = FileAccess.get_file_as_string(PAGE)
	return _page_cache.replace("__WS_PORT__", str(ws_port))


## The game's icon as PNG (home-screen icon on the phone).
func _icon(px: int) -> PackedByteArray:
	if _icon_cache.has(px):
		return _icon_cache[px]
	var tex: Texture2D = load("res://icon.svg")
	var img := tex.get_image() if tex else null
	if img == null:
		return PackedByteArray()
	if img.is_compressed():
		img.decompress()
	img.resize(px, px, Image.INTERPOLATE_LANCZOS)
	_icon_cache[px] = img.save_png_to_buffer()
	return _icon_cache[px]


func _poll_ws() -> void:
	while _ws.is_connection_available():
		var peer := WebSocketPeer.new()
		peer.inbound_buffer_size = 1 << 16
		peer.outbound_buffer_size = 1 << 22
		if peer.accept_stream(_ws.take_connection()) == OK:
			_pending_ws.append({"ws": peer, "t": Time.get_ticks_msec()})
	for p in _pending_ws.duplicate():
		var ws: WebSocketPeer = p.ws
		ws.poll()
		var st := ws.get_ready_state()
		if st == WebSocketPeer.STATE_CLOSED or Time.get_ticks_msec() - int(p.t) > 10000:
			_pending_ws.erase(p)
			continue
		while st == WebSocketPeer.STATE_OPEN and ws.get_available_packet_count() > 0:
			var msg = JSON.parse_string(ws.get_packet().get_string_from_utf8())
			if typeof(msg) == TYPE_DICTIONARY and msg.get("t", "") == "hello" and str(msg.get("k", "")) == token:
				_pending_ws.erase(p)
				_clients.append(ws)
				_send(ws, _screen_info())
				_need_full = true
				_kbd_owner = null
				clients_changed.emit(_clients.size())
			else:
				ws.close(4001, "token")
				_pending_ws.erase(p)
			break
	for ws in _clients.duplicate():
		ws.poll()
		if ws.get_ready_state() == WebSocketPeer.STATE_CLOSED:
			_clients.erase(ws)
			clients_changed.emit(_clients.size())
			continue
		while ws.get_available_packet_count() > 0:
			var msg = JSON.parse_string(ws.get_packet().get_string_from_utf8())
			if typeof(msg) == TYPE_DICTIONARY:
				_handle(ws, msg)


func _screen_info() -> Dictionary:
	var sz := stream_vp.size if stream_vp else Vector2i(0, 0)
	return {"t": "screen", "w": sz.x, "h": sz.y, "on": stream_vp != null}


## Main calls this when streaming starts or stops.
func stream_changed() -> void:
	_last_raw = PackedByteArray()
	_need_full = true
	_kbd_owner = null
	_t_down = false
	broadcast(_screen_info())


# ================================================================= inbound
func _handle(ws: WebSocketPeer, msg: Dictionary) -> void:
	Clock.notify_activity()
	match str(msg.get("t", "")):
		"touch":
			_last_input = Time.get_ticks_msec()
			if stream_vp:
				var p := Vector2(float(msg.get("x", 0)), float(msg.get("y", 0))) * Vector2(stream_vp.size)
				_touch(str(msg.get("a", "")), p)
		"text":
			_last_input = Time.get_ticks_msec()
			_set_text(str(msg.get("value", "")))
		"enter":
			_last_input = Time.get_ticks_msec()
			if _kbd_owner is LineEdit and is_instance_valid(_kbd_owner):
				var le := _kbd_owner as LineEdit
				le.text_submitted.emit(le.text)
		"back":
			_last_input = Time.get_ticks_msec()
			if on_back.is_valid():
				on_back.call()
		"sync":
			_send(ws, _screen_info())
			_need_full = true


# ---------------------------------------------------------------- touch → phone
## A finger on the real phone becomes taps, scrolls and drags on the in-game
## phone. Inside scrolling lists a drag scrolls (and never clicks what is
## under the finger); elsewhere (sliders, the photo viewer) it drags.
func _touch(a: String, p: Vector2) -> void:
	match a:
		"down":
			_t_down = true
			_t_start = p
			_t_last = p
			_t_mode = ""
			_t_scroll = _scroll_ancestor(_control_at(p))
			_mouse_move(p, 0)
			if _t_scroll == null:
				_t_mode = "drag"
				_mouse_button(p, true, _is_double(p))
		"move":
			if not _t_down:
				return
			if _t_mode == "drag":
				_mouse_move(p, MOUSE_BUTTON_MASK_LEFT)
			elif _t_mode == "" and p.distance_to(_t_start) > 14.0:
				_t_mode = "scroll"
			if _t_mode == "scroll" and is_instance_valid(_t_scroll):
				var k := _scale_of(_t_scroll)
				_t_scroll.scroll_vertical -= int(round((p.y - _t_last.y) / k))
				_t_scroll.scroll_horizontal -= int(round((p.x - _t_last.x) / k))
			_t_last = p
		"up":
			if not _t_down:
				return
			_t_down = false
			if _t_mode == "drag":
				_mouse_button(p, false)
			elif _t_mode == "":
				# a tap inside a list: press and release where the finger went down
				_mouse_button(_t_start, true, _is_double(_t_start))
				_mouse_button(_t_start, false)
			_t_mode = ""
			_mouse_move(Vector2(-50, -50), 0)   # a finger leaves no hover behind
		"cancel":
			if _t_down and _t_mode == "drag":
				_mouse_button(_t_last, false)
			_t_down = false
			_t_mode = ""


func _is_double(p: Vector2) -> bool:
	var now := Time.get_ticks_msec()
	var dbl := now - _t_last_tap < 350 and p.distance_to(_t_last_tap_pos) < 40.0
	_t_last_tap = now
	_t_last_tap_pos = p
	return dbl


func _mouse_move(p: Vector2, mask: int) -> void:
	var ev := InputEventMouseMotion.new()
	ev.position = p
	ev.global_position = p
	ev.button_mask = mask
	stream_vp.push_input(ev)


func _mouse_button(p: Vector2, down: bool, double := false) -> void:
	var ev := InputEventMouseButton.new()
	ev.position = p
	ev.global_position = p
	ev.button_index = MOUSE_BUTTON_LEFT
	ev.pressed = down
	ev.double_click = double and down
	ev.button_mask = MOUSE_BUTTON_MASK_LEFT if down else 0
	stream_vp.push_input(ev)


static func _scale_of(c: Control) -> float:
	return maxf(0.01, c.get_global_transform().get_scale().y)


## The topmost visible control under a point that takes mouse input.
func _control_at(p: Vector2) -> Control:
	if stream_vp == null:
		return null
	var best: Control = null
	for n in stream_vp.find_children("*", "Control", true, false):
		var c := n as Control
		if c.mouse_filter == Control.MOUSE_FILTER_IGNORE or not c.is_visible_in_tree():
			continue
		if c.get_global_rect().has_point(p):
			best = c   # tree order: later siblings are drawn on top
	return best


static func _scroll_ancestor(c: Control) -> ScrollContainer:
	var n: Node = c
	while n:
		if n is Range:
			return null   # sliders drag, they do not scroll their list
		if n is ScrollContainer:
			var sc := n as ScrollContainer
			var child := sc.get_child(0) as Control if sc.get_child_count() > 0 else null
			if child and (child.size.y > sc.size.y + 1 or child.size.x > sc.size.x + 1):
				return sc
		n = n.get_parent()
	return null


# ---------------------------------------------------------------- keyboard
## When a text field of the in-game phone gets the focus, the real phone opens
## its own keyboard; what is typed there is written into that field.
func _check_keyboard() -> void:
	var f := stream_vp.gui_get_focus_owner() if stream_vp else null
	var editable: Control = null
	if (f is LineEdit and (f as LineEdit).editable) or (f is TextEdit and (f as TextEdit).editable):
		editable = f
	if editable == _kbd_owner:
		return
	_kbd_owner = editable
	if editable == null:
		broadcast({"t": "kbd", "on": false})
		return
	var le := editable as LineEdit
	broadcast({"t": "kbd", "on": true, "text": str(editable.get("text")), "multi": editable is TextEdit,
		"secret": le != null and le.secret, "hint": str(editable.get("placeholder_text")),
		"digits": le != null and le.virtual_keyboard_type == LineEdit.KEYBOARD_TYPE_NUMBER})


func _set_text(value: String) -> void:
	if not is_instance_valid(_kbd_owner):
		return
	if _kbd_owner is LineEdit:
		var le := _kbd_owner as LineEdit
		if le.max_length > 0:
			value = value.left(le.max_length)
		le.text = value
		le.caret_column = value.length()
		le.text_changed.emit(value)
	elif _kbd_owner is TextEdit:
		var te := _kbd_owner as TextEdit
		te.text = value
		var last := te.get_line_count() - 1
		te.set_caret_line(last)
		te.set_caret_column(te.get_line(last).length())
		te.text_changed.emit()


# ================================================================= outbound
func broadcast(msg: Dictionary) -> void:
	if _clients.is_empty():
		return
	var text := JSON.stringify(msg)
	for ws in _clients:
		ws.send_text(text)


func _send(ws: WebSocketPeer, msg: Dictionary) -> void:
	ws.send_text(JSON.stringify(msg))


## Captures the in-game phone and sends it when it changed. The JPEG is
## encoded on a worker thread so the game never stutters.
func _stream() -> void:
	if stream_vp == null or _clients.is_empty():
		return
	_check_keyboard()
	if _encoding:
		if WorkerThreadPool.is_task_completed(_frame_task):
			WorkerThreadPool.wait_for_task_completion(_frame_task)
			_encoding = false
			if _frame_out.size() > 0:
				for ws in _clients:
					if ws.get_current_outbound_buffered_amount() < (1 << 21):   # a slow network skips frames
						ws.send(_frame_out, WebSocketPeer.WRITE_MODE_BINARY)
				frames_sent += 1
		return
	var now := Time.get_ticks_msec()
	var fps := FPS_ACTIVE if now - _last_input < 1500 or _t_down else FPS_IDLE
	if now - _last_capture < int(1000.0 / fps):
		return
	_last_capture = now
	var img := stream_vp.get_texture().get_image()
	if img == null:
		return
	var raw := img.get_data()
	if raw == _last_raw and not _need_full:
		return
	_last_raw = raw
	_need_full = false
	_encoding = true
	_frame_task = WorkerThreadPool.add_task(func():
		img.convert(Image.FORMAT_RGB8)
		_frame_out = img.save_jpg_to_buffer(JPEG_QUALITY))
