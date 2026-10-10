class_name SoundSynth
extends RefCounted
## Procedural sound generation. Every sound in the game is synthesised at
## runtime, so the repository has no binary audio assets and every cue can be
## tuned in code.

const RATE := 22050
const LOOPS := ["room", "night", "tension", "dread", "rain", "sea", "static", "ring", "ring_wrong", "dialtone", "menu", "memory", "lullaby", "hum"]

var _rng := RandomNumberGenerator.new()


func _init() -> void:
	_rng.seed = 1410


static func to_stream(buf: PackedFloat32Array, loop := false) -> AudioStreamWAV:
	var bytes := PackedByteArray()
	bytes.resize(buf.size() * 2)
	for i in buf.size():
		var s := int(clampf(buf[i], -1.0, 1.0) * 32767.0)
		bytes.encode_s16(i * 2, s)
	var st := AudioStreamWAV.new()
	st.format = AudioStreamWAV.FORMAT_16_BITS
	st.mix_rate = RATE
	st.stereo = false
	st.data = bytes
	if loop:
		st.loop_mode = AudioStreamWAV.LOOP_FORWARD
		st.loop_begin = 0
		st.loop_end = buf.size()
	return st


func make(sound_name: String) -> AudioStreamWAV:
	var buf := PackedFloat32Array()
	match sound_name:
		"msg": buf = _tones([[1318.5, 0.0, 0.16], [1760.0, 0.09, 0.3]], 0.42, 0.32)
		"notif": buf = _tones([[1046.5, 0.0, 0.3]], 0.35, 0.28)
		"mail": buf = _tones([[880.0, 0.0, 0.2], [1108.7, 0.08, 0.2], [1318.5, 0.16, 0.35]], 0.55, 0.22)
		"sent": buf = _swish(0.13, 3200.0, 0.25)
		"tap": buf = _click(0.03, 0.35, 2500.0)
		"key": buf = _click(0.028, 0.22, 1800.0 + _rng.randf() * 900.0)
		"unlock": buf = _tones([[660.0, 0.0, 0.1], [990.0, 0.06, 0.16]], 0.24, 0.22)
		"lock": buf = _click(0.09, 0.5, 600.0)
		"shutter": buf = _shutter()
		"app_open": buf = _swish(0.12, 1800.0, 0.12)
		"vibrate": buf = _vibrate(2)
		"vibrate_long": buf = _vibrate(5)
		"glitch": buf = _glitch(0.6)
		"glitch_short": buf = _glitch(0.22)
		"breath": buf = _breath()
		"knock": buf = _knock(3)
		"knock_one": buf = _knock(1)
		"footsteps": buf = _footsteps()
		"sub": buf = _sub()
		"heartbeat": buf = _heartbeat()
		"call_connect": buf = _tones([[425.0, 0.0, 0.12]], 0.15, 0.25)
		"call_end": buf = _tones([[620.0, 0.0, 0.12], [520.0, 0.14, 0.12], [420.0, 0.28, 0.18]], 0.5, 0.22)
		"beep": buf = _tones([[1000.0, 0.0, 0.45]], 0.5, 0.25)
		"error": buf = _buzz(0.32)
		"clue": buf = _clue()
		"boot": buf = _tones([[392.0, 0.0, 0.5], [523.25, 0.18, 0.6], [783.99, 0.36, 0.9]], 1.3, 0.18)
		"whisper": buf = _whisper(1.8)
		"voice": buf = _voice(2.2, 140.0)
		"voice_low": buf = _voice(2.4, 95.0)
		"scream": buf = _scream()
		"door": buf = _creak()
		"drop": buf = _drop()
		"water": buf = _water()
		"click_far": buf = _click(0.05, 0.15, 900.0)
		# --- the 3D house
		"step": buf = _step(false)
		"step_tile": buf = _step(true)
		"switch": buf = _switch()
		"flashlight": buf = _click(0.04, 0.4, 3200.0)
		"door_open": buf = _door(false)
		"door_close": buf = _door(true)
		"door_locked": buf = _rattle()
		# loops
		"room": buf = _room()
		"hum": buf = _hum()
		"night": buf = _night()
		"tension": buf = _drone([55.0, 55.4, 82.5], 8.0, 0.16)
		"dread": buf = _dread()
		"rain": buf = _rain()
		"sea": buf = _sea()
		"static": buf = _static(2.0)
		"ring": buf = _ringtone(false)
		"ring_wrong": buf = _ringtone(true)
		"dialtone": buf = _dialtone()
		"menu": buf = _music_menu()
		"memory": buf = _music_memory()
		"lullaby": buf = _music_lullaby()
		_:
			push_warning("unknown sound " + sound_name)
			buf = _click(0.02, 0.1, 1000.0)
	return to_stream(buf, LOOPS.has(sound_name))


# ---------------------------------------------------------------- primitives
func _alloc(secs: float) -> PackedFloat32Array:
	var b := PackedFloat32Array()
	b.resize(int(secs * RATE))
	return b


func _tones(notes: Array, total: float, vol: float) -> PackedFloat32Array:
	var b := _alloc(total)
	for n in notes:
		var f: float = n[0]
		var start := int(float(n[1]) * RATE)
		var length := int(float(n[2]) * RATE)
		for i in length:
			var idx := start + i
			if idx >= b.size():
				break
			var t := float(i) / RATE
			var env := minf(1.0, t * 300.0) * exp(-t * 9.0 / float(n[2]) * 0.6)
			b[idx] += (sin(TAU * f * t) + 0.25 * sin(TAU * f * 2.0 * t)) * env * vol
	return b


func _click(secs: float, vol: float, tone: float) -> PackedFloat32Array:
	var b := _alloc(secs)
	var lp := 0.0
	for i in b.size():
		var t := float(i) / RATE
		var env := exp(-t * 90.0)
		var n := _rng.randf_range(-1.0, 1.0)
		lp += (n - lp) * 0.35
		b[i] = (lp * 0.6 + sin(TAU * tone * t) * 0.4) * env * vol
	return b


func _swish(secs: float, cutoff: float, vol: float) -> PackedFloat32Array:
	var b := _alloc(secs)
	var lp := 0.0
	var a := clampf(cutoff / RATE * 2.0, 0.01, 0.9)
	for i in b.size():
		var t := float(i) / secs / RATE
		var env := sin(PI * t)
		lp += (_rng.randf_range(-1.0, 1.0) - lp) * a
		b[i] = lp * env * vol
	return b


func _shutter() -> PackedFloat32Array:
	var b := _alloc(0.22)
	for i in b.size():
		var t := float(i) / RATE
		var e1 := exp(-t * 60.0)
		var e2 := exp(-maxf(t - 0.09, 0.0) * 70.0) * (1.0 if t > 0.09 else 0.0)
		var n := _rng.randf_range(-1.0, 1.0)
		b[i] = n * (e1 + e2) * 0.45
	return b


func _vibrate(pulses: int) -> PackedFloat32Array:
	var b := _alloc(pulses * 0.45)
	for i in b.size():
		var t := float(i) / RATE
		var ph := fmod(t, 0.45)
		var on := 1.0 if ph < 0.3 else 0.0
		var env := on * minf(1.0, ph * 60.0) * minf(1.0, (0.3 - ph) * 60.0)
		var s := sin(TAU * 150.0 * t) + 0.5 * signf(sin(TAU * 75.0 * t)) * 0.4 + _rng.randf_range(-0.1, 0.1)
		b[i] = s * env * 0.35
	return b


func _glitch(secs: float) -> PackedFloat32Array:
	var b := _alloc(secs)
	var hold := 0.0
	var count := 0
	var seg_freq := 400.0
	for i in b.size():
		if count <= 0:
			count = _rng.randi_range(80, 1600)
			hold = _rng.randf_range(-1.0, 1.0)
			seg_freq = _rng.randf_range(60.0, 3000.0)
		count -= 1
		var t := float(i) / RATE
		var mode := int(t * 23.0) % 3
		var s := 0.0
		if mode == 0:
			s = hold
		elif mode == 1:
			s = signf(sin(TAU * seg_freq * t)) * 0.6
		else:
			s = _rng.randf_range(-1.0, 1.0)
		s = floor(s * 4.0) / 4.0
		var env := minf(1.0, (secs - t) * 20.0)
		b[i] = s * 0.22 * env
	return b


func _breath() -> PackedFloat32Array:
	var b := _alloc(3.2)
	var lp := 0.0
	var bp := 0.0
	for i in b.size():
		var t := float(i) / RATE
		var env := 0.0
		if t < 1.3:
			env = sin(PI * t / 1.3) * 0.7
		elif t > 1.6 and t < 3.1:
			env = sin(PI * (t - 1.6) / 1.5)
		var n := _rng.randf_range(-1.0, 1.0)
		lp += (n - lp) * 0.18
		bp += (lp - bp) * 0.05
		b[i] = (lp - bp) * env * 0.55
	return b


func _knock(count: int) -> PackedFloat32Array:
	var b := _alloc(0.35 * count + 0.6)
	for k in count:
		var start := int((0.05 + k * (0.32 + _rng.randf() * 0.05)) * RATE)
		for i in int(0.3 * RATE):
			var idx := start + i
			if idx >= b.size():
				break
			var t := float(i) / RATE
			var env := exp(-t * 28.0)
			b[idx] += (sin(TAU * 95.0 * t) * 0.8 + sin(TAU * 190.0 * t) * 0.2 + _rng.randf_range(-0.3, 0.3) * exp(-t * 120.0)) * env * 0.7
	return b


func _footsteps() -> PackedFloat32Array:
	var b := _alloc(3.4)
	for k in 6:
		var start := int((0.2 + k * 0.52) * RATE)
		var vol := 0.25 + k * 0.05
		for i in int(0.25 * RATE):
			var idx := start + i
			if idx >= b.size():
				break
			var t := float(i) / RATE
			var env := exp(-t * 35.0)
			b[idx] += (sin(TAU * 70.0 * t) + _rng.randf_range(-0.6, 0.6) * exp(-t * 80.0)) * env * vol
	return b


func _sub() -> PackedFloat32Array:
	var b := _alloc(2.0)
	var ph := 0.0
	for i in b.size():
		var t := float(i) / RATE
		var f := lerpf(70.0, 28.0, t / 2.0)
		ph += TAU * f / RATE
		b[i] = sin(ph) * minf(1.0, t * 20.0) * exp(-t * 1.4) * 0.8
	return b


func _heartbeat() -> PackedFloat32Array:
	var b := _alloc(1.6)
	for start_s in [0.05, 0.33, 0.85, 1.13]:
		var start := int(start_s * RATE)
		for i in int(0.22 * RATE):
			var idx := start + i
			if idx >= b.size():
				break
			var t := float(i) / RATE
			b[idx] += sin(TAU * 52.0 * t) * exp(-t * 22.0) * 0.8
	return b


func _buzz(secs: float) -> PackedFloat32Array:
	var b := _alloc(secs)
	for i in b.size():
		var t := float(i) / RATE
		var on := 1.0 if fmod(t, 0.16) < 0.11 else 0.0
		b[i] = signf(sin(TAU * 180.0 * t)) * on * 0.12
	return b


func _clue() -> PackedFloat32Array:
	var b := _alloc(0.5)
	var lp := 0.0
	for i in b.size():
		var t := float(i) / RATE
		lp += (_rng.randf_range(-1.0, 1.0) - lp) * 0.5
		var scratch := lp * exp(-t * 30.0) * 0.18
		var tone := sin(TAU * 587.3 * t) * exp(-t * 7.0) * 0.08 * minf(1.0, t * 200.0)
		b[i] = scratch + tone
	return b


func _whisper(secs: float) -> PackedFloat32Array:
	var b := _alloc(secs)
	var lp := 0.0
	var bp := 0.0
	for i in b.size():
		var t := float(i) / RATE
		var cut := 0.08 + 0.06 * sin(TAU * 3.1 * t) + 0.04 * sin(TAU * 7.3 * t)
		var n := _rng.randf_range(-1.0, 1.0)
		lp += (n - lp) * cut
		bp += (lp - bp) * 0.02
		var env := sin(PI * t / secs) * (0.6 + 0.4 * sin(TAU * 4.2 * t))
		b[i] = (lp - bp) * env * 0.5
	return b


func _voice(secs: float, f0: float) -> PackedFloat32Array:
	## Unintelligible voice through a phone line: pulse train + moving formants.
	var b := _alloc(secs)
	var ph := 0.0
	var f1 := 0.0
	var f2 := 0.0
	for i in b.size():
		var t := float(i) / RATE
		var f := f0 * (1.0 + 0.08 * sin(TAU * 1.7 * t) + 0.05 * sin(TAU * 5.3 * t))
		ph += f / RATE
		var pulse := 1.0 if fmod(ph, 1.0) < 0.12 else -0.13
		var a1 := 0.10 + 0.08 * sin(TAU * 3.7 * t)
		var a2 := 0.25 + 0.15 * sin(TAU * 2.3 * t + 1.0)
		f1 += (pulse - f1) * a1
		f2 += (pulse - f2) * a2
		var syl := maxf(0.0, sin(TAU * 3.3 * t)) * (0.5 + 0.5 * sin(TAU * 0.7 * t))
		var env := minf(1.0, t * 10.0) * minf(1.0, (secs - t) * 10.0)
		b[i] = (f1 * 0.7 + (f2 - f1) * 0.5) * syl * env * 0.5 + _rng.randf_range(-0.02, 0.02)
	return b


func _scream() -> PackedFloat32Array:
	## Someone crying out far away, the wind taking most of it.
	var secs := 1.6
	var b := _alloc(secs)
	var ph := 0.0
	var f1 := 0.0
	var f2 := 0.0
	var wind := 0.0
	for i in b.size():
		var t := float(i) / RATE
		var f := 520.0 + 260.0 * sin(PI * minf(t / 0.9, 1.0)) - 180.0 * maxf(0.0, t - 0.7)
		f *= 1.0 + 0.03 * sin(TAU * 6.5 * t)
		ph += f / RATE
		var pulse := 1.0 if fmod(ph, 1.0) < 0.2 else -0.25
		f1 += (pulse - f1) * 0.18
		f2 += (pulse - f2) * 0.45
		var gust := 0.55 + 0.45 * sin(TAU * 2.1 * t + 0.6) * sin(TAU * 0.9 * t)
		var env := minf(1.0, t * 14.0) * clampf((1.1 - t) * 2.5, 0.0, 1.0) * gust
		wind += (_rng.randf_range(-1.0, 1.0) - wind) * 0.03
		b[i] = (f1 * 0.5 + (f2 - f1) * 0.6) * env * 0.42 + wind * 0.25 * (1.0 - t / secs)
	return b


func _creak() -> PackedFloat32Array:
	var b := _alloc(1.8)
	var ph := 0.0
	var lp := 0.0
	for i in b.size():
		var t := float(i) / RATE
		var f := 38.0 + 14.0 * sin(TAU * 0.6 * t) + _rng.randf_range(-3.0, 3.0)
		ph += f / RATE
		var saw := fmod(ph, 1.0) * 2.0 - 1.0
		lp += (saw - lp) * 0.2
		var env := sin(PI * t / 1.8)
		b[i] = lp * env * 0.35
	return b


## One footstep: a soft thud for the wooden floor, a harder tap on tiles.
func _step(tile: bool) -> PackedFloat32Array:
	var b := _alloc(0.28)
	var lp := 0.0
	for i in b.size():
		var t := float(i) / RATE
		var n := _rng.randf_range(-1.0, 1.0)
		lp += (n - lp) * (0.5 if tile else 0.12)
		var thud := sin(TAU * (90.0 if tile else 62.0) * t) * exp(-t * 40.0)
		b[i] = (thud * (0.35 if tile else 0.55) + lp * exp(-t * (70.0 if tile else 30.0)) * (0.5 if tile else 0.6)) * 0.6
	# the old parquet sometimes answers with a small creak
	if not tile and _rng.randf() < 0.5:
		var ph := 0.0
		for i in int(0.12 * RATE):
			var t := float(i) / RATE
			ph += (300.0 + _rng.randf_range(-20.0, 20.0)) / RATE
			var idx := int(0.05 * RATE) + i
			if idx < b.size():
				b[idx] += (fmod(ph, 1.0) * 2.0 - 1.0) * sin(PI * t / 0.12) * 0.04
	return b


func _switch() -> PackedFloat32Array:
	var b := _alloc(0.12)
	for k in 2:
		var start := int(k * 0.035 * RATE)
		for i in int(0.04 * RATE):
			var t := float(i) / RATE
			if start + i < b.size():
				b[start + i] += (_rng.randf_range(-1.0, 1.0) * 0.5 + sin(TAU * 2400.0 * t) * 0.5) * exp(-t * 260.0) * (0.5 if k == 0 else 0.3)
	return b


## Interior door: a short hinge creak; closing ends with the latch.
func _door(closing: bool) -> PackedFloat32Array:
	var secs := 0.9
	var b := _alloc(secs + 0.3)
	var ph := 0.0
	var lp := 0.0
	for i in int(secs * RATE):
		var t := float(i) / RATE
		var f := 140.0 + 90.0 * sin(TAU * 0.9 * t) + _rng.randf_range(-12.0, 12.0)
		ph += f / RATE
		var saw := fmod(ph, 1.0) * 2.0 - 1.0
		lp += (saw - lp) * 0.08
		b[i] = lp * sin(PI * t / secs) * 0.16
	if closing:
		var start := int(secs * 0.85 * RATE)
		for i in int(0.25 * RATE):
			var t := float(i) / RATE
			if start + i < b.size():
				b[start + i] += (sin(TAU * 85.0 * t) * 0.7 + _rng.randf_range(-0.4, 0.4) * exp(-t * 90.0)) * exp(-t * 26.0) * 0.6
	return b


## The handle of a locked door: two or three short metallic rattles.
func _rattle() -> PackedFloat32Array:
	var b := _alloc(0.45)
	for k in 3:
		var start := int((k * 0.12 + _rng.randf() * 0.02) * RATE)
		for i in int(0.06 * RATE):
			var t := float(i) / RATE
			if start + i < b.size():
				b[start + i] += (sin(TAU * 1700.0 * t) * 0.3 + sin(TAU * 260.0 * t) * 0.4 + _rng.randf_range(-0.3, 0.3)) * exp(-t * 80.0) * 0.5
	return b


func _drop() -> PackedFloat32Array:
	var b := _alloc(0.6)
	for i in b.size():
		var t := float(i) / RATE
		b[i] = (sin(TAU * 120.0 * t) * 0.6 + _rng.randf_range(-1.0, 1.0) * 0.4) * exp(-t * 18.0) * 0.7
	return b


func _water() -> PackedFloat32Array:
	var b := _alloc(2.5)
	var lp := 0.0
	for i in b.size():
		var t := float(i) / RATE
		lp += (_rng.randf_range(-1.0, 1.0) - lp) * 0.06
		var bub := sin(TAU * (300.0 + 200.0 * sin(TAU * 9.0 * t)) * t) * 0.05 * maxf(0.0, sin(TAU * 4.0 * t))
		b[i] = (lp * 0.8 + bub) * sin(PI * t / 2.5) * 0.7
	return b


# ---------------------------------------------------------------- loops
func _room() -> PackedFloat32Array:
	var secs := 6.0
	var b := _alloc(secs)
	var lp := 0.0
	for i in b.size():
		var t := float(i) / RATE
		lp += (_rng.randf_range(-1.0, 1.0) - lp) * 0.012
		var hum := sin(TAU * 50.0 * t) * 0.012 + sin(TAU * 100.0 * t) * 0.006
		b[i] = lp * 0.5 + hum
	return _seam(b)


func _hum() -> PackedFloat32Array:
	var b := _alloc(4.0)
	for i in b.size():
		var t := float(i) / RATE
		b[i] = (sin(TAU * 50.0 * t) * 0.05 + sin(TAU * 150.0 * t) * 0.02 + sin(TAU * 250.0 * t) * 0.008)
	return b


func _night() -> PackedFloat32Array:
	var secs := 8.0
	var b := _alloc(secs)
	var lp := 0.0
	var lp2 := 0.0
	for i in b.size():
		var t := float(i) / RATE
		lp += (_rng.randf_range(-1.0, 1.0) - lp) * 0.02
		lp2 += (lp - lp2) * 0.3
		var wind := lp2 * (0.6 + 0.4 * sin(TAU * t / secs))
		var cricket := 0.0
		var cp := fmod(t * 1.3, 1.0)
		if cp < 0.12:
			cricket = sin(TAU * 4200.0 * t) * sin(TAU * 30.0 * t) * 0.012
		b[i] = wind * 0.8 + cricket
	return _seam(b)


func _drone(freqs: Array, secs: float, vol: float) -> PackedFloat32Array:
	var b := _alloc(secs)
	for i in b.size():
		var t := float(i) / RATE
		var s := 0.0
		for f in freqs:
			# frequencies chosen so they complete whole cycles over the loop
			var ff: float = round(f * secs) / secs
			s += sin(TAU * ff * t)
		var swell := 0.7 + 0.3 * sin(TAU * t / secs)
		b[i] = s / freqs.size() * vol * swell
	return b


func _dread() -> PackedFloat32Array:
	var secs := 8.0
	var b := _drone([41.0, 41.5, 61.5, 123.0], secs, 0.2)
	var lp := 0.0
	for i in b.size():
		var t := float(i) / RATE
		lp += (_rng.randf_range(-1.0, 1.0) - lp) * 0.008
		var whine := sin(TAU * (round(1780.0 * secs) / secs) * t) * 0.006 * (0.5 + 0.5 * sin(TAU * 2.0 * t / secs))
		b[i] += lp * 0.4 + whine
	return b


func _rain() -> PackedFloat32Array:
	var b := _alloc(6.0)
	var lp := 0.0
	for i in b.size():
		lp += (_rng.randf_range(-1.0, 1.0) - lp) * 0.25
		var drop := 0.0
		if _rng.randf() < 0.0009:
			drop = _rng.randf_range(0.2, 0.5)
		b[i] = lp * 0.12 + drop
	return _seam(b)


func _sea() -> PackedFloat32Array:
	var secs := 8.0
	var b := _alloc(secs)
	var lp := 0.0
	for i in b.size():
		var t := float(i) / RATE
		var cut := 0.02 + 0.05 * pow(maxf(0.0, sin(TAU * t / 4.0)), 2.0)
		lp += (_rng.randf_range(-1.0, 1.0) - lp) * cut
		var env := 0.25 + 0.75 * pow(maxf(0.0, sin(TAU * t / 4.0)), 1.5)
		b[i] = lp * env * 0.9
	return _seam(b)


func _static(secs: float) -> PackedFloat32Array:
	var b := _alloc(secs)
	var lp := 0.0
	for i in b.size():
		var t := float(i) / RATE
		lp += (_rng.randf_range(-1.0, 1.0) - lp) * 0.5
		var crackle := 0.0
		if _rng.randf() < 0.002:
			crackle = _rng.randf_range(-0.6, 0.6)
		b[i] = lp * 0.08 * (0.7 + 0.3 * sin(TAU * 0.5 * t)) + crackle
	return _seam(b)


func _ringtone(wrong: bool) -> PackedFloat32Array:
	var secs := 3.0
	var b := _alloc(secs)
	var notes := [659.25, 783.99, 987.77, 783.99, 659.25, 587.33]
	var detune := 0.97 if wrong else 1.0
	for k in notes.size():
		var start := int(k * 0.2 * RATE)
		var f: float = notes[k] * detune
		if wrong and k % 2 == 1:
			f *= 0.94
		for i in int(0.32 * RATE):
			var idx := start + i
			if idx >= b.size():
				break
			var t := float(i) / RATE
			var env := minf(1.0, t * 200.0) * exp(-t * 6.0)
			b[idx] += (sin(TAU * f * t) + 0.3 * sin(TAU * f * 3.0 * t)) * env * 0.25
	if wrong:
		for i in b.size():
			b[i] = floor(b[i] * 10.0) / 10.0
	return b


func _dialtone() -> PackedFloat32Array:
	var b := _alloc(4.0)
	for i in b.size():
		var t := float(i) / RATE
		var on := 1.0 if t < 1.0 else 0.0
		b[i] = sin(TAU * 425.0 * t) * on * 0.12 * minf(1.0, t * 100.0) * minf(1.0, (1.0 - t) * 100.0 if t < 1.0 else 1.0)
	return b


func _pluck(b: PackedFloat32Array, start_s: float, f: float, dur: float, vol: float) -> void:
	var start := int(start_s * RATE)
	for i in int(dur * RATE):
		var idx := (start + i) % b.size()  # wrap the tail so loops are seamless
		var t := float(i) / RATE
		var env := minf(1.0, t * 80.0) * exp(-t * 2.2)
		b[idx] += (sin(TAU * f * t) + 0.35 * sin(TAU * f * 2.0 * t) * exp(-t * 3.0) + 0.1 * sin(TAU * f * 3.0 * t)) * env * vol


func _music_menu() -> PackedFloat32Array:
	var secs := 19.2
	var b := _alloc(secs)
	# A minor, slow and sparse; one note slightly out of place each bar.
	var seq := [[0.0, 220.0], [1.2, 261.63], [2.4, 329.63], [3.6, 293.66],
		[4.8, 220.0], [6.0, 261.63], [7.2, 311.13], [8.4, 293.66],
		[9.6, 174.61], [10.8, 220.0], [12.0, 261.63], [13.2, 246.94],
		[14.4, 164.81], [15.6, 207.65], [16.8, 246.94], [18.0, 220.0]]
	for n in seq:
		_pluck(b, n[0], n[1], 3.0, 0.14)
		_pluck(b, n[0], n[1] * 0.5, 3.0, 0.05)
	return b


func _music_memory() -> PackedFloat32Array:
	var secs := 14.4
	var b := _alloc(secs)
	var seq := [[0.0, 392.0], [0.9, 329.63], [1.8, 261.63], [3.6, 293.66], [4.5, 246.94],
		[7.2, 392.0], [8.1, 329.63], [9.0, 261.63], [10.8, 220.0], [11.7, 196.0]]
	for n in seq:
		_pluck(b, n[0], n[1], 2.6, 0.11)
	for k in 4:
		_pluck(b, k * 3.6, 130.81, 3.6, 0.05)
	return b


## A music box slightly out of tune, as if the tape were stretching: the
## "Dorme, Daniel" theme for the quiet endings.
func _music_lullaby() -> PackedFloat32Array:
	var secs := 16.0
	var b := _alloc(secs)
	# D minor; the last note of the phrase lands a semitone too low.
	var seq := [[0.0, 587.33], [0.5, 698.46], [1.0, 880.0], [2.0, 783.99], [2.5, 698.46], [3.0, 659.25],
		[4.0, 587.33], [4.5, 698.46], [5.0, 880.0], [6.0, 1046.5], [7.0, 932.33],
		[8.0, 587.33], [8.5, 698.46], [9.0, 880.0], [10.0, 783.99], [10.5, 698.46], [11.0, 659.25],
		[12.0, 587.33], [13.0, 554.37]]
	for n in seq:
		var start := int(n[0] * RATE)
		var f: float = n[1]
		for i in int(2.2 * RATE):
			var idx := (start + i) % b.size()
			var t := float(i) / RATE
			# tape wow: slow pitch wobble that grows towards the end of the loop
			var wow := 1.0 + 0.004 * sin(TAU * 0.6 * (float(start + i) / RATE)) * (0.5 + float(start) / b.size())
			var env := minf(1.0, t * 300.0) * exp(-t * 3.4)
			b[idx] += (sin(TAU * f * wow * t) + 0.25 * sin(TAU * f * 3.0 * wow * t) * exp(-t * 6.0)) * env * 0.13
	for k in 4:
		_pluck(b, k * 4.0, 146.83, 4.0, 0.06)
	return b


## Crossfade the end of a buffer into its start for seamless looping.
func _seam(b: PackedFloat32Array) -> PackedFloat32Array:
	var n := mini(int(0.25 * RATE), b.size() / 4)
	var size := b.size()
	for i in n:
		var a := float(i) / n
		b[i] = b[i] * a + b[size - n + i] * (1.0 - a)
	b.resize(size - n)
	return b
