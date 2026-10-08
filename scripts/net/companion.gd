extends Node
## "Telemóvel real": the player's own phone joins the game through a web page.
##
## The game hosts a tiny HTTP server (the page) and a WebSocket server (live
## events) on the local network. The player scans a QR code on the PC; their
## phone then receives the in-game messages, notifications, calls and
## vibrations, and can answer them. The page runs in the phone's browser only:
## the game never reads anything from the real phone.

signal clients_changed(count: int)

const HTTP_PORT := 8317
const WS_PORT := 8417
const PAGE := "res://companion/index.html"
const MAX_MESSAGES := 60

var running := false
var persist_token := true   # tests turn this off (no writes to the player's settings)
var http_port := 0
var ws_port := 0
var token := ""

var _http: TCPServer
var _ws: TCPServer
var _http_conns: Array = []   # [{peer, buf, t}]
var _pending_ws: Array = []   # WebSocketPeer not yet authenticated
var _clients: Array = []      # authenticated WebSocketPeer
var _page_cache := ""
var _last_minute := -1


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Events.message_added.connect(_on_message)
	Events.message_changed.connect(func(th, _id): _send_thread(th))
	Events.thread_typing.connect(func(th, who, typing): broadcast({"t": "typing", "thread": th, "who": GameState.contact_name(who), "on": typing}))
	Events.choice_offered.connect(func(th): _send_choice(th))
	Events.choice_cleared.connect(func(th): broadcast({"t": "choice", "thread": th, "options": []}))
	Events.notification_posted.connect(_on_notification)
	Events.call_incoming.connect(func(c): broadcast({"t": "call", "state": "ringing", "name": _call_name(c)}))
	Events.call_started.connect(func(c): broadcast({"t": "call", "state": "connected", "name": _call_name(c)}))
	Events.call_line.connect(func(who, text): broadcast({"t": "call_line", "who": GameState.contact_name(who) if who != "" else "", "text": text}))
	Events.call_ended.connect(func(_c): broadcast({"t": "call", "state": "ended"}))
	Events.vibrate_requested.connect(func(n): broadcast({"t": "vibrate", "n": n}))
	Events.glitch_requested.connect(func(i, d): broadcast({"t": "glitch", "i": i, "d": d}))
	Events.screen_off_requested.connect(func(d): broadcast({"t": "screen_off", "d": d}))
	Events.time_changed.connect(_on_time)
	Events.state_loaded.connect(func(): _send_state_all())
	Events.chapter_started.connect(func(_c): _send_state_all())
	Events.content_changed.connect(func(k): if k == "contacts": _send_state_all())
	Events.phone_state_changed.connect(func(): broadcast({"t": "status", "battery": int(GameState.data.get("battery", 100))}))


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
	if path == "/" or path == "/index.html":
		body = _page().to_utf8_buffer()
	elif path == "/favicon.ico":
		status = "204 No Content"
		body = PackedByteArray()
	else:
		status = "404 Not Found"
		ctype = "text/plain"
		body = "404".to_utf8_buffer()
	var head := "HTTP/1.1 %s\r\nContent-Type: %s\r\nContent-Length: %d\r\nCache-Control: no-store\r\nConnection: close\r\n\r\n" % [status, ctype, body.size()]
	peer.put_data(head.to_utf8_buffer())
	if body.size() > 0:
		peer.put_data(body)


func _page() -> String:
	if _page_cache == "":
		_page_cache = FileAccess.get_file_as_string(PAGE)
	return _page_cache.replace("__WS_PORT__", str(ws_port))


func _poll_ws() -> void:
	while _ws.is_connection_available():
		var peer := WebSocketPeer.new()
		peer.inbound_buffer_size = 1 << 16
		peer.outbound_buffer_size = 1 << 20
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
				_send(ws, _state())
				clients_changed.emit(_clients.size())
				Events.toast_requested.emit("Telemóvel ligado")
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


# ================================================================= inbound
func _handle(ws: WebSocketPeer, msg: Dictionary) -> void:
	Clock.notify_activity()
	match str(msg.get("t", "")):
		"open":
			# the PC phone follows what the player opens on the real phone
			var th := str(msg.get("thread", ""))
			if GameState.data.threads.has(th) and GameState.in_game:
				Events.open_app_requested.emit("messages", {"param": th, "forced": true})
		"choose":
			Director.pick_choice(str(msg.get("thread", "")), int(msg.get("index", 0)))
		"answer":
			Events.call_response.emit(true)
		"decline":
			Events.call_response.emit(false)
		"hangup":
			Events.call_hangup_requested.emit()
		"sync":
			_send(ws, _state())


# ================================================================= outbound
func broadcast(msg: Dictionary) -> void:
	if _clients.is_empty():
		return
	var text := JSON.stringify(msg)
	for ws in _clients:
		ws.send_text(text)


func _send(ws: WebSocketPeer, msg: Dictionary) -> void:
	ws.send_text(JSON.stringify(msg))


func _send_state_all() -> void:
	if not _clients.is_empty():
		broadcast(_state())


func _state() -> Dictionary:
	var threads: Array = []
	if GameState.in_game:
		for th in GameState.data.thread_order:
			if GameState.data.hidden_threads.has(th) or not GameState.data.threads.has(th):
				continue
			threads.append(_thread_dict(th))
	return {
		"t": "state",
		"in_game": GameState.in_game,
		"time": Clock.fmt_time(Clock.now()) if GameState.in_game else "",
		"battery": int(GameState.data.get("battery", 100)),
		"threads": threads,
	}


func _thread_dict(th: String) -> Dictionary:
	var data: Dictionary = GameState.data.threads[th]
	var msgs: Array = []
	var all: Array = data.get("messages", [])
	for i in range(maxi(0, all.size() - MAX_MESSAGES), all.size()):
		msgs.append(_msg_dict(th, all[i]))
	return {
		"id": th,
		"name": GameState.contact_name(th),
		"unread": int(data.get("unread", 0)),
		"group": Content.character(th).get("group", false),
		"messages": msgs,
		"options": _options(th),
	}


func _msg_dict(th: String, m: Dictionary) -> Dictionary:
	var d := {
		"id": str(m.get("id", "")),
		"me": m.get("from", "") == "me",
		"from": GameState.contact_name(str(m.get("from", th))),
		"text": "" if m.get("del", false) else str(m.get("text", "")),
		"deleted": m.get("del", false),
		"time": Clock.fmt_time(float(m.get("t", 0))),
		"day": _day_label(float(m.get("t", 0))),
	}
	if m.has("att"):
		d.att = str(m.att.get("type", ""))
	return d


func _options(th: String) -> Array:
	var pending: Dictionary = GameState.data.choices.get(th, {})
	var out: Array = []
	for o in pending.get("options", []):
		out.append({"index": int(o.index), "text": str(o.text).trim_prefix("[").trim_suffix("]"), "silent": str(o.text).begins_with("[")})
	return out


func _send_thread(th: String) -> void:
	if not _clients.is_empty() and GameState.data.threads.has(th):
		broadcast({"t": "thread", "thread": _thread_dict(th)})


func _send_choice(th: String) -> void:
	broadcast({"t": "choice", "thread": th, "options": _options(th)})


func _on_message(th: String, m: Dictionary) -> void:
	if _clients.is_empty():
		return
	broadcast({"t": "msg", "thread": th, "name": GameState.contact_name(th), "msg": _msg_dict(th, m)})


func _on_notification(n: Dictionary) -> void:
	broadcast({"t": "notif", "app": str(n.get("app", "")), "title": str(n.get("title", "")), "body": str(n.get("body", "")), "thread": str(n.get("thread", ""))})


func _on_time(unix: float) -> void:
	var minute := int(unix / 60.0)
	if minute == _last_minute:
		return
	_last_minute = minute
	broadcast({"t": "status", "time": Clock.fmt_time(unix), "battery": int(GameState.data.get("battery", 100))})


func _call_name(c: Dictionary) -> String:
	if c.get("unknown", false):
		return str(c.get("number", "Desconhecido"))
	return GameState.contact_name(str(c.get("who", "")))


static func _day_label(t: float) -> String:
	var day := floori(t / 86400.0)
	var now_day := floori(Clock.now() / 86400.0)
	if day == now_day:
		return "Hoje"
	if day == now_day - 1:
		return "Ontem"
	return Clock.fmt_date_long(t)
