class_name NetTransport
extends RefCounted
## A way for two copies of the game to talk. Coop only sees this interface;
## DirectTransport (IP / local network) and SteamTransport (lobbies + relay)
## implement it.

signal hosted(code: String)          # host: room ready, code to share
signal code_changed(code: String)    # host: a better code became available (e.g. UPnP)
signal partner_joined                # host: the other player arrived
signal connected                     # guest: reached the host
signal partner_left
signal failed(reason: String)
signal received(msg: Dictionary)

var is_host := false


func host() -> void:
	pass


func join(_code: String) -> void:
	pass


func send(_msg: Dictionary) -> void:
	pass


func poll() -> void:
	pass


func close() -> void:
	pass


## Human-readable description of how the other player can join.
func describe() -> String:
	return ""


func can_invite() -> bool:
	return false


func invite() -> void:
	pass


static func pack(msg: Dictionary) -> PackedByteArray:
	return JSON.stringify(msg).to_utf8_buffer()


static func unpack(bytes: PackedByteArray) -> Dictionary:
	var d = JSON.parse_string(bytes.get_string_from_utf8())
	return d if typeof(d) == TYPE_DICTIONARY else {}
