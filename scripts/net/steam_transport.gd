class_name SteamTransport
extends NetTransport
## Co-op through Steam (GodotSteam): the host's game is still the server, but
## Steam finds the friend (lobby + invite) and relays the traffic, so nobody
## has to open ports. Needs the GodotSteam build of Godot and a real App ID.
##
## NOTE: written against the GodotSteam 4.x API but NOT yet tested — it can
## only run once the game has an App ID. Calls go through the singleton by
## name so the project compiles without GodotSteam.

const CHANNEL := 0
const SEND_RELIABLE := 8   # k_nSteamNetworkingSend_Reliable

var _steam: Object
var _lobby := 0
var _partner := 0
var _me := 0


static func available() -> bool:
	# Steam is initialised once, by Achievements (scripts/core/achievements.gd)
	return Achievements.steam_ok


func _init() -> void:
	_steam = Engine.get_singleton("Steam") if Engine.has_singleton("Steam") else null
	if _steam:
		_me = int(_steam.call("getSteamID"))
		_connect("lobby_created", _on_lobby_created)
		_connect("lobby_joined", _on_lobby_joined)
		_connect("lobby_chat_update", _on_lobby_chat_update)
		_connect("join_requested", _on_join_requested)
		_connect("network_messages_session_request", _on_session_request)


func _connect(sig: String, cb: Callable) -> void:
	if _steam.has_signal(sig) and not _steam.is_connected(sig, cb):
		_steam.connect(sig, cb)


func host() -> void:
	is_host = true
	if _steam == null:
		failed.emit("O Steam não está disponível.")
		return
	# 1 = LOBBY_TYPE_FRIENDS_ONLY, 2 players
	_steam.call("createLobby", 1, 2)


func join(code: String) -> void:
	is_host = false
	if _steam == null:
		failed.emit("O Steam não está disponível.")
		return
	var id := RoomCode.to_lobby(code)
	if id <= 0:
		failed.emit("Código inválido.")
		return
	_steam.call("joinLobby", id)


func send(msg: Dictionary) -> void:
	if _steam == null or _partner == 0:
		return
	_steam.call("sendMessageToUser", _partner, pack(msg), SEND_RELIABLE, CHANNEL)


func poll() -> void:
	if _steam == null:
		return
	var msgs: Array = _steam.call("receiveMessagesOnChannel", CHANNEL, 32)
	for m in msgs:
		var payload = m.get("payload", PackedByteArray())
		var d := unpack(payload if payload is PackedByteArray else str(payload).to_utf8_buffer())
		if not d.is_empty():
			received.emit(d)


func close() -> void:
	if _steam and _lobby != 0:
		_steam.call("leaveLobby", _lobby)
	if _steam and _partner != 0:
		_steam.call("closeSessionWithUser", _partner)
	_lobby = 0
	_partner = 0


func can_invite() -> bool:
	return _steam != null and _lobby != 0


func invite() -> void:
	if can_invite():
		_steam.call("activateGameOverlayInviteDialog", _lobby)


func describe() -> String:
	if _lobby == 0:
		return "A criar a sala no Steam…"
	return "Código: %s\nOu convida um amigo pela lista de amigos do Steam." % RoomCode.from_lobby(_lobby)


# ---------------------------------------------------------------- callbacks
func _on_lobby_created(result: int, lobby_id: int) -> void:
	if result != 1:
		failed.emit("O Steam não conseguiu criar a sala (%d)." % result)
		return
	_lobby = lobby_id
	_steam.call("setLobbyData", lobby_id, "game", "ainda_estas_acordado")
	_steam.call("setLobbyJoinable", lobby_id, true)
	hosted.emit(RoomCode.from_lobby(lobby_id))


func _on_lobby_joined(lobby_id: int, _permissions: int, _locked: bool, response: int) -> void:
	if response != 1:
		failed.emit("Não foi possível entrar na sala (%d)." % response)
		return
	_lobby = lobby_id
	if is_host:
		return
	_partner = int(_steam.call("getLobbyOwner", lobby_id))
	# say hello so the host's session request fires
	connected.emit()


func _on_lobby_chat_update(lobby_id: int, changed_id: int, _making_change: int, chat_state: int) -> void:
	if lobby_id != _lobby or changed_id == _me:
		return
	if chat_state == 1:  # entered
		if is_host:
			_partner = changed_id
			partner_joined.emit()
	elif changed_id == _partner:
		partner_left.emit()


func _on_join_requested(lobby_id: int, _friend_id: int) -> void:
	# accepted an invite from the Steam overlay / friends list
	is_host = false
	_steam.call("joinLobby", lobby_id)


func _on_session_request(remote_id) -> void:
	var id := int(remote_id)
	if id == _partner or _partner == 0:
		_partner = id
		_steam.call("acceptSessionWithUser", id)
