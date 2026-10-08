class_name RoomCode
extends RefCounted
## Short codes players can read out to each other. A direct-connection code
## packs an IPv4 address and a port (48 bits); a Steam code packs a lobby id
## (64 bits). Crockford base32: no I, L, O, U, so it survives being dictated.

const ALPHABET := "0123456789ABCDEFGHJKMNPQRSTVWXYZ"


static func encode_int(value: int, digits: int) -> String:
	var out := ""
	for i in digits:
		out = ALPHABET[value & 31] + out
		value = value >> 5
	# groups of 4 or 5 for readability
	var g := 5 if digits % 5 == 0 else 4
	var parts: PackedStringArray = []
	for i in range(0, out.length(), g):
		parts.append(out.substr(i, g))
	return "-".join(parts)


static func decode_int(code: String) -> int:
	var c := code.to_upper().replace("-", "").replace(" ", "")
	c = c.replace("O", "0").replace("I", "1").replace("L", "1")
	var value := 0
	for ch in c:
		var d := ALPHABET.find(ch)
		if d < 0:
			return -1
		value = (value << 5) | d
	return value


## "192.168.1.20", 8517 -> "C0A80-11421-AU" style code (10 digits).
static func from_address(ip: String, port: int) -> String:
	var p := ip.split(".")
	if p.size() != 4:
		return ""
	var v := 0
	for x in p:
		v = (v << 8) | (int(x) & 255)
	v = (v << 16) | (port & 0xFFFF)
	return encode_int(v, 10)


## Code (or a plain "ip:port") -> {ip, port}; empty on error.
static func to_address(code: String) -> Dictionary:
	var s := code.strip_edges()
	if s.contains(".") or s.contains(":"):
		var host := s.get_slice(":", 0)
		var port := int(s.get_slice(":", 1)) if s.contains(":") else 0
		return {"ip": host, "port": port}
	var c := s.to_upper().replace("-", "").replace(" ", "")
	if c.length() != 10:
		return {}
	var v := decode_int(c)
	if v < 0:
		return {}
	var port := v & 0xFFFF
	v = v >> 16
	var ip := "%d.%d.%d.%d" % [(v >> 24) & 255, (v >> 16) & 255, (v >> 8) & 255, v & 255]
	return {"ip": ip, "port": port}


## Steam lobby id (64-bit) -> 13-digit code.
static func from_lobby(lobby_id: int) -> String:
	return encode_int(lobby_id, 13)


static func to_lobby(code: String) -> int:
	var c := code.to_upper().replace("-", "").replace(" ", "")
	if c.length() != 13:
		return -1
	return decode_int(c)
