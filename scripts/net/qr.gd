class_name QR
extends RefCounted
## Minimal QR Code encoder (byte mode, error correction level L, versions 1–9).
## Enough for a pairing URL. encode() returns an Array of rows of bools
## (true = dark module), without the quiet zone.

# version: [ec codewords per block, blocks, data codewords per block] (level L)
const BLOCKS := {
	1: [7, 1, 19], 2: [10, 1, 34], 3: [15, 1, 55], 4: [20, 1, 80], 5: [26, 1, 108],
	6: [18, 2, 68], 7: [20, 2, 78], 8: [24, 2, 97], 9: [30, 2, 116],
}
const ALIGN := {
	1: [], 2: [6, 18], 3: [6, 22], 4: [6, 26], 5: [6, 30], 6: [6, 34],
	7: [6, 22, 38], 8: [6, 24, 42], 9: [6, 26, 46],
}

static var _exp: PackedInt32Array
static var _log: PackedInt32Array


static func encode(text: String) -> Array:
	var data := text.to_utf8_buffer()
	var version := 0
	for v in range(1, 10):
		var cap: int = BLOCKS[v][1] * BLOCKS[v][2]
		if 4 + 8 + data.size() * 8 <= cap * 8:
			version = v
			break
	if version == 0:
		push_error("QR: text too long")
		return []
	var codewords := _codewords(data, version)
	var size := 17 + version * 4
	var best: Array = []
	var best_score := -1
	for mask in 8:
		var m := _build(size, version, codewords, mask)
		var score := _penalty(m)
		if best_score < 0 or score < best_score:
			best_score = score
			best = m
	return best


# ---------------------------------------------------------------- data
static func _codewords(data: PackedByteArray, version: int) -> PackedByteArray:
	var ec_n: int = BLOCKS[version][0]
	var nblocks: int = BLOCKS[version][1]
	var per: int = BLOCKS[version][2]
	var total := nblocks * per
	var bits: Array[int] = []
	_push_bits(bits, 0b0100, 4)  # byte mode
	_push_bits(bits, data.size(), 8)
	for b in data:
		_push_bits(bits, b, 8)
	for i in mini(4, total * 8 - bits.size()):
		bits.append(0)
	while bits.size() % 8 != 0:
		bits.append(0)
	var bytes := PackedByteArray()
	for i in range(0, bits.size(), 8):
		var v := 0
		for j in 8:
			v = (v << 1) | bits[i + j]
		bytes.append(v)
	var pad := [0xEC, 0x11]
	var k := 0
	while bytes.size() < total:
		bytes.append(pad[k % 2])
		k += 1
	# split into blocks, compute error correction, interleave
	var blocks: Array = []
	var ecs: Array = []
	for bi in nblocks:
		var blk := bytes.slice(bi * per, (bi + 1) * per)
		blocks.append(blk)
		ecs.append(_rs(blk, ec_n))
	var out := PackedByteArray()
	for i in per:
		for blk in blocks:
			out.append(blk[i])
	for i in ec_n:
		for ec in ecs:
			out.append(ec[i])
	return out


static func _push_bits(bits: Array[int], value: int, n: int) -> void:
	for i in range(n - 1, -1, -1):
		bits.append((value >> i) & 1)


static func _gf_init() -> void:
	if _exp.size() > 0:
		return
	_exp.resize(512)
	_log.resize(256)
	var x := 1
	for i in 255:
		_exp[i] = x
		_log[x] = i
		x <<= 1
		if x & 0x100:
			x ^= 0x11D
	for i in range(255, 512):
		_exp[i] = _exp[i - 255]


static func _gf_mul(a: int, b: int) -> int:
	if a == 0 or b == 0:
		return 0
	return _exp[_log[a] + _log[b]]


static func _rs(data: PackedByteArray, n: int) -> PackedByteArray:
	_gf_init()
	# generator polynomial (x - a^0)(x - a^1)...(x - a^(n-1)), highest degree first
	var gen: Array[int] = [1]
	for i in n:
		var next: Array[int] = []
		next.resize(gen.size() + 1)
		next.fill(0)
		for j in gen.size():
			next[j] ^= gen[j]
			next[j + 1] ^= _gf_mul(gen[j], _exp[i])
		gen = next
	var rem: Array[int] = []
	rem.resize(n)
	rem.fill(0)
	for d in data:
		var factor: int = d ^ rem[0]
		rem.pop_front()
		rem.append(0)
		for j in n:
			rem[j] ^= _gf_mul(gen[j + 1], factor)
	var out := PackedByteArray()
	for r in rem:
		out.append(r)
	return out


# ---------------------------------------------------------------- matrix
static func _build(size: int, version: int, codewords: PackedByteArray, mask: int) -> Array:
	var m: Array = []
	var fn: Array = []  # function-pattern modules (not data)
	for y in size:
		var row: Array[bool] = []
		row.resize(size)
		row.fill(false)
		m.append(row)
		var frow: Array[bool] = []
		frow.resize(size)
		frow.fill(false)
		fn.append(frow)
	# finders + separators
	for c in [[0, 0], [size - 7, 0], [0, size - 7]]:
		for dy in range(-1, 8):
			for dx in range(-1, 8):
				var x: int = c[0] + dx
				var y: int = c[1] + dy
				if x < 0 or y < 0 or x >= size or y >= size:
					continue
				var on := dx >= 0 and dx <= 6 and dy >= 0 and dy <= 6 and (dx == 0 or dx == 6 or dy == 0 or dy == 6 or (dx >= 2 and dx <= 4 and dy >= 2 and dy <= 4))
				m[y][x] = on
				fn[y][x] = true
	# timing
	for i in range(8, size - 8):
		m[6][i] = i % 2 == 0
		m[i][6] = i % 2 == 0
		fn[6][i] = true
		fn[i][6] = true
	# alignment
	var al: Array = ALIGN[version]
	for ai in al.size():
		for aj in al.size():
			var last := al.size() - 1
			if (ai == 0 and aj == 0) or (ai == 0 and aj == last) or (ai == last and aj == 0):
				continue  # would overlap a finder pattern
			var ay: int = al[ai]
			var ax: int = al[aj]
			for dy in range(-2, 3):
				for dx in range(-2, 3):
					m[ay + dy][ax + dx] = maxi(absi(dx), absi(dy)) != 1
					fn[ay + dy][ax + dx] = true
	# dark module + reserve format areas
	m[size - 8][8] = true
	fn[size - 8][8] = true
	for i in 9:
		fn[8][i] = true
		fn[i][8] = true
	for i in 8:
		fn[8][size - 1 - i] = true
		fn[size - 1 - i][8] = true
	# version info (v >= 7)
	if version >= 7:
		var vbits := _version_bits(version)
		for i in 18:
			var bit := (vbits >> i) & 1 == 1
			var a := i / 3
			var b := size - 11 + i % 3
			m[a][b] = bit
			m[b][a] = bit
			fn[a][b] = true
			fn[b][a] = true
	# data, zigzag from the bottom-right
	var bit_i := 0
	var total_bits := codewords.size() * 8
	var x := size - 1
	var upward := true
	while x > 0:
		if x == 6:
			x -= 1
		for k in size:
			var y := size - 1 - k if upward else k
			for dx in 2:
				var cx := x - dx
				if fn[y][cx]:
					continue
				var dark := false
				if bit_i < total_bits:
					dark = (codewords[bit_i >> 3] >> (7 - (bit_i & 7))) & 1 == 1
				bit_i += 1
				if _mask_hit(mask, cx, y):
					dark = not dark
				m[y][cx] = dark
		upward = not upward
		x -= 2
	# format info (level L = 01); m[y][x]
	var fbits := _format_bits((0b01 << 3) | mask)
	for i in 15:
		var bit := (fbits >> i) & 1 == 1
		# first copy, around the top-left finder
		if i < 6:
			m[i][8] = bit
		elif i == 6:
			m[7][8] = bit
		elif i == 7:
			m[8][8] = bit
		elif i == 8:
			m[8][7] = bit
		else:
			m[8][14 - i] = bit
		# second copy: top-right row, then bottom-left column
		if i < 8:
			m[8][size - 1 - i] = bit
		else:
			m[size - 15 + i][8] = bit
	m[size - 8][8] = true
	return m


static func _mask_hit(mask: int, x: int, y: int) -> bool:
	match mask:
		0: return (x + y) % 2 == 0
		1: return y % 2 == 0
		2: return x % 3 == 0
		3: return (x + y) % 3 == 0
		4: return (y / 2 + x / 3) % 2 == 0
		5: return (x * y) % 2 + (x * y) % 3 == 0
		6: return ((x * y) % 2 + (x * y) % 3) % 2 == 0
		_: return ((x + y) % 2 + (x * y) % 3) % 2 == 0


static func _format_bits(data: int) -> int:
	var v := data << 10
	for i in range(14, 9, -1):
		if (v >> i) & 1:
			v ^= 0x537 << (i - 10)
	return ((data << 10) | v) ^ 0x5412


static func _version_bits(version: int) -> int:
	var v := version << 12
	for i in range(17, 11, -1):
		if (v >> i) & 1:
			v ^= 0x1F25 << (i - 12)
	return (version << 12) | v


static func _penalty(m: Array) -> int:
	var n := m.size()
	var score := 0
	# rule 1: runs of 5+ in rows and columns; rule 3: finder-like patterns
	for horizontal in [true, false]:
		for a in n:
			var run := 1
			for b in range(1, n):
				var cur: bool = m[a][b] if horizontal else m[b][a]
				var prev: bool = m[a][b - 1] if horizontal else m[b - 1][a]
				if cur == prev:
					run += 1
				else:
					if run >= 5:
						score += run - 2
					run = 1
			if run >= 5:
				score += run - 2
			for b in range(0, n - 10):
				var s := ""
				for k in 11:
					s += "1" if (m[a][b + k] if horizontal else m[b + k][a]) else "0"
				if s == "10111010000" or s == "00001011101":
					score += 40
	# rule 2: 2x2 blocks
	for y in n - 1:
		for x in n - 1:
			var c: bool = m[y][x]
			if m[y][x + 1] == c and m[y + 1][x] == c and m[y + 1][x + 1] == c:
				score += 3
	# rule 4: dark ratio
	var dark := 0
	for row in m:
		for v in row:
			if v:
				dark += 1
	var pct := dark * 100 / (n * n)
	score += absi(pct - 50) / 5 * 10
	return score
