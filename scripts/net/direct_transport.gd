class_name DirectTransport
extends NetTransport
## Direct connection over ENet (UDP). The host's game is the server for the
## session. On the same network it just works; over the internet the host's
## router must forward the port — we try to open it automatically with UPnP.

const PORT := 8517

var _peer: ENetMultiplayerPeer
var _port := 0
var _lan_code := ""
var _net_code := ""
var _upnp_thread: Thread
var _upnp: UPNP
var _was_connected := false


func host() -> void:
	is_host = true
	_peer = ENetMultiplayerPeer.new()
	var err := ERR_CANT_CREATE
	for p in range(PORT, PORT + 10):
		err = _peer.create_server(p, 1)
		if err == OK:
			_port = p
			break
	if err != OK:
		failed.emit("Não foi possível abrir a porta %d (está ocupada?)." % PORT)
		return
	_peer.peer_connected.connect(func(_id): partner_joined.emit())
	_peer.peer_disconnected.connect(func(_id): partner_left.emit())
	_lan_code = RoomCode.from_address(Companion.lan_ip(), _port)
	hosted.emit(_lan_code)
	# try to open the port on the router so friends outside the house can join
	_upnp_thread = Thread.new()
	_upnp_thread.start(_open_router_port)


func _open_router_port() -> void:
	var u := UPNP.new()
	if u.discover(2000, 2, "InternetGatewayDevice") != UPNP.UPNP_RESULT_SUCCESS:
		return
	var gw := u.get_gateway()
	if gw == null or not gw.is_valid_gateway():
		return
	if u.add_port_mapping(_port, _port, "UNKNOWN", "UDP", 0) != UPNP.UPNP_RESULT_SUCCESS:
		return
	var ext := u.query_external_address()
	if ext == "" or ext.contains(":"):
		return
	_upnp = u
	_net_code = RoomCode.from_address(ext, _port)
	call_deferred("emit_signal", "code_changed", _net_code)


func join(code: String) -> void:
	is_host = false
	var addr := RoomCode.to_address(code)
	if addr.is_empty() or str(addr.ip) == "":
		failed.emit("Código inválido.")
		return
	_peer = ENetMultiplayerPeer.new()
	var err := _peer.create_client(str(addr.ip), int(addr.port) if int(addr.port) > 0 else PORT)
	if err != OK:
		failed.emit("Não foi possível iniciar a ligação.")
		return
	_peer.peer_connected.connect(func(_id):
		_was_connected = true
		connected.emit())
	_peer.peer_disconnected.connect(func(_id): partner_left.emit())


func send(msg: Dictionary) -> void:
	if _peer == null or _peer.get_connection_status() != MultiplayerPeer.CONNECTION_CONNECTED:
		return
	_peer.set_target_peer(MultiplayerPeer.TARGET_PEER_BROADCAST)
	_peer.transfer_mode = MultiplayerPeer.TRANSFER_MODE_RELIABLE
	_peer.put_packet(pack(msg))


func poll() -> void:
	if _peer == null:
		return
	_peer.poll()
	if not is_host and not _was_connected and _peer.get_connection_status() == MultiplayerPeer.CONNECTION_DISCONNECTED:
		_peer = null
		failed.emit("Não foi possível ligar ao anfitrião. Confirma o código e que estão na mesma rede (ou que a porta está aberta no router dele).")
		return
	while _peer and _peer.get_available_packet_count() > 0:
		var m := unpack(_peer.get_packet())
		if not m.is_empty():
			received.emit(m)


func close() -> void:
	if _peer:
		_peer.close()
		_peer = null
	if _upnp_thread:
		_upnp_thread.wait_to_finish()
		_upnp_thread = null
	if _upnp:
		_upnp.delete_port_mapping(_port, "UDP")
		_upnp = null


func describe() -> String:
	if _net_code != "":
		return "Código: %s\n(na mesma casa também serve: %s)" % [_net_code, _lan_code]
	return "Código: %s\nFunciona na mesma rede. Para jogar com alguém fora de casa, o teu router tem de deixar passar a porta UDP %d." % [_lan_code, _port]
