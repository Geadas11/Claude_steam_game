extends Node
## Online co-op, "Dois telemóveis" (see docs/COOP.md).
##
## The host plays Daniel and his game is the server for the session: it owns
## the clock, the chapters and the saves. The guest plays Sofia, running her
## own story (data/sofia/) on a clock that follows the host's.
##
## The conversation between the two siblings is shared: what one sends, the
## other receives. Story scripts can ask coop() and exchange variables with
## the "coopset" command. Everything else stays local to each phone — which is
## the point: the ECO can rewrite Daniel's phone, not Sofia's.

signal status_changed(text: String)
signal code_changed(code: String)
signal partner_changed(present: bool)
signal failed(reason: String)
signal start_requested(as_host: bool)   # main starts the game for this role
signal ended(reason: String)

const PROTOCOL := 1
const LINK := {"daniel": "sofia", "sofia": "daniel"}   # role -> thread with the other player

var transport: NetTransport
var is_host := false
var partner_present := false
var active := false          # a co-op game is being played
var code := ""
var partner_busy := false
var partner_idle := 0.0
var status := ""

var _tick := 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	status_changed.connect(func(t): status = t)
	Events.message_added.connect(_on_local_message)
	Events.chapter_ended.connect(func(ch): if active and is_host: _send({"t": "chapter_end", "ch": ch}))
	Events.chapter_started.connect(func(ch): if active and is_host: _send({"t": "chapter", "ch": ch, "time": Clock.now()}))
	Events.ending_reached.connect(func(id): if active and is_host: _send({"t": "ending", "id": id}))


# ================================================================= rooms
func uses_steam() -> bool:
	return SteamTransport.available()


func create_room() -> void:
	_reset()
	is_host = true
	transport = SteamTransport.new() if uses_steam() else DirectTransport.new()
	_wire()
	status_changed.emit("A criar a sala…")
	transport.host()


func join_room(room_code: String) -> void:
	_reset()
	is_host = false
	transport = SteamTransport.new() if uses_steam() else DirectTransport.new()
	_wire()
	status_changed.emit("A ligar…")
	transport.join(room_code)


func leave(reason := "") -> void:
	if transport:
		_send({"t": "bye"})
		transport.poll()
	var was_active := active
	_reset()
	if was_active:
		ended.emit(reason)


func describe() -> String:
	return transport.describe() if transport else ""


func _reset() -> void:
	if transport:
		transport.close()
	transport = null
	partner_present = false
	active = false
	code = ""
	partner_busy = false
	Clock.external = false


func _wire() -> void:
	transport.hosted.connect(func(c):
		code = c
		code_changed.emit(c)
		status_changed.emit("À espera do outro jogador…"))
	transport.code_changed.connect(func(c):
		code = c
		code_changed.emit(c))
	transport.partner_joined.connect(func(): status_changed.emit("Alguém está a entrar…"))
	transport.connected.connect(func():
		_send({"t": "hello", "protocol": PROTOCOL, "version": ProjectSettings.get_setting("application/config/version", "")})
		status_changed.emit("Ligado. À espera de que o anfitrião comece…"))
	transport.partner_left.connect(_on_partner_left)
	transport.failed.connect(func(r):
		status_changed.emit(r)
		failed.emit(r))
	transport.received.connect(_on_received)


func _on_partner_left() -> void:
	partner_present = false
	partner_changed.emit(false)
	if active:
		Events.toast_requested.emit("O outro jogador saiu.")
		if not is_host:
			leave("O anfitrião saiu do jogo.")
	else:
		status_changed.emit("À espera do outro jogador…")


## Host: both players are here, start the story.
func start_game() -> void:
	if not is_host or not partner_present:
		return
	active = true
	# tell the guest first, so it is already in the story when the first
	# messages of the chapter arrive
	_send({"t": "start"})
	start_requested.emit(true)
	_send({"t": "time", "v": Clock.now()})


# ================================================================= per frame
func _process(delta: float) -> void:
	if transport == null:
		return
	transport.poll()
	if not active:
		return
	_tick += delta
	if _tick < 0.5:
		return
	_tick = 0.0
	if is_host:
		_send({"t": "time", "v": Clock.now()})
	else:
		_send({"t": "tick", "busy": not Director.waiting_on_clock(), "idle": Clock.idle_seconds()})


# ================================================================= inbound
func _on_received(m: Dictionary) -> void:
	match str(m.get("t", "")):
		"hello":
			if not is_host:
				return
			if int(m.get("protocol", 0)) != PROTOCOL:
				_send({"t": "refused", "why": "Versões diferentes do jogo. Atualizem os dois."})
				return
			partner_present = true
			partner_changed.emit(true)
			status_changed.emit("A Sofia chegou. Podem começar.")
			_send({"t": "welcome"})
		"welcome":
			partner_present = true
			partner_changed.emit(true)
		"refused":
			failed.emit(str(m.get("why", "")))
			leave()
		"start":
			if is_host:
				return
			active = true
			start_requested.emit(false)
			Clock.external = true
		"time":
			if not is_host and active:
				GameState.data.time = float(m.get("v", GameState.data.time))
		"tick":
			partner_busy = bool(m.get("busy", false))
			partner_idle = float(m.get("idle", 0.0))
		"msg":
			_on_remote_message(m)
		"var":
			GameState.set_var(str(m.k), m.v)
		"chapter_end":
			if not is_host and active and GameState.data.chapter == str(m.ch) and not GameState.data.get("chapter_complete", false):
				Director._end_chapter()
		"chapter":
			if not is_host and active and GameState.data.chapter != str(m.ch) and not GameState.data.get("chapter_complete", false):
				Director.start_chapter(str(m.ch))
				Clock.set_time(float(m.get("time", Clock.now())))
		"ending":
			if not is_host:
				Events.ending_reached.emit(str(m.id))
		"bye":
			_on_partner_left()


# ================================================================= the shared conversation
func my_role() -> String:
	return "daniel" if is_host else "sofia"


func link_thread() -> String:
	return LINK[my_role()]


func _on_local_message(th: String, msg: Dictionary) -> void:
	if not active or th != link_thread() or msg.get("net", false):
		return
	var author := ""
	if msg.get("from", "") == "me":
		author = my_role()
	elif is_host and msg.get("from", "") == "sofia":
		# a scripted Sofia line (chapters she has no script for yet): her
		# phone shows it as sent by her
		author = "sofia"
	if author == "":
		return
	var out := {"t": "msg", "author": author, "text": str(msg.get("text", ""))}
	if msg.has("att"):
		out.att = msg.att
	_send(out)


func _on_remote_message(m: Dictionary) -> void:
	var th := link_thread()
	var author := str(m.get("author", ""))
	var from: String = "me" if author == my_role() else str(LINK[my_role()])
	var msg := {"from": from, "text": str(m.get("text", "")), "t": Clock.now(), "net": true}
	if m.has("att"):
		msg.att = m.att
	var added := GameState.add_message(th, msg, from != "me")
	if from != "me":
		GameState.inc_var("net_in")
		Director._announce_message(th, added)
		Audio.play("msg")
	Events.message_added.emit(th, added)
	Director.notify_player_action()


# ================================================================= story hooks
## "coopset name value" in a story: set here and on the other phone.
func share_var(k: String, value) -> void:
	GameState.set_var(k, value)
	if active:
		_send({"t": "var", "k": k, "v": value})


func _send(m: Dictionary) -> void:
	if transport:
		transport.send(m)
