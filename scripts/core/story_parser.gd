class_name StoryParser
extends RefCounted
## Parses the .story narrative DSL into beats made of linear op lists.
##
## A beat is compiled to a flat program (if/else become jumps) so the Director
## can save a program counter and resume a beat exactly where it stopped.
## See docs/STORY_FORMAT.md for the full syntax.

const COMMANDS := {
	"notify": 3, "sound": 1, "ambient": 1, "music": 1, "stopsounds": 0,
	"vibrate": 0, "glitch": 2, "time": 1, "rate": 1,
	"photo": 1, "variant": 2, "edit": 3, "delete": 2, "unsend": 2,
	"contact": 1, "rename": 2, "contactset": 3,
	"email": 1, "file": 1, "note": 1, "voicemail": 1,
	"history": 1, "unlock": 1, "clue": 1, "calllog": 3,
	"open": 1, "lock": 0, "screenoff": 1, "restart": 0, "reflection": 0,
	"battery": 1, "location": 1, "camera": 1, "achieve": 1,
	"autotype": 2, "checkpoint": 0, "endchapter": 0, "ending": 1,
	"deduction": 0, "typing": 3, "toast": 1, "hiddenapp": 2,
	"setting": 2, "read": 1, "alarm": 2, "home": 0, "clearchoice": 1,
	"retime": 3, "hidethread": 1, "showthread": 1, "mapmark": 1,
}

var errors: Array = []
var _lines: PackedStringArray
var _i := 0
var _file := ""


static func parse_file(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {"errors": ["missing " + path], "beats": [], "calls": []}
	return parse_text(FileAccess.get_file_as_string(path), path)


static func parse_text(text: String, file := "<text>") -> Dictionary:
	var p := StoryParser.new()
	p._file = file
	return p._parse(text)


func _err(msg: String) -> void:
	errors.append("%s:%d %s" % [_file.get_file(), _i + 1, msg])


func _parse(text: String) -> Dictionary:
	_lines = text.split("\n")
	var out := {"id": "", "title": "", "start": "", "beats": [], "calls": [], "errors": errors}
	_i = 0
	while _i < _lines.size():
		var line := _clean(_lines[_i])
		if line == "":
			_i += 1
			continue
		if line.begins_with("@chapter "):
			out.id = line.substr(9).strip_edges()
		elif line.begins_with("@title "):
			out.title = line.substr(7).strip_edges()
		elif line.begins_with("@start "):
			out.start = line.substr(7).strip_edges()
		elif line.begins_with("@beat ") or line.begins_with("@call "):
			var block := _parse_block(line)
			if block.kind == "call":
				out.calls.append(block)
			else:
				out.beats.append(block)
			continue
		else:
			_err("unexpected top-level line: " + line)
		_i += 1
	# duplicate id check
	var seen := {}
	for b in out.beats:
		if seen.has(b.id):
			errors.append("%s duplicate beat id %s" % [_file.get_file(), b.id])
		seen[b.id] = true
	return out


static func _clean(raw: String) -> String:
	var s := raw.strip_edges()
	if s.begins_with("#") or s.begins_with("//"):
		return ""
	return s


func _parse_block(header: String) -> Dictionary:
	var parts := header.split(" ", false)
	var block := {"id": "", "kind": "beat", "when": "true", "repeat": false, "ops": [], "who": "", "line": _i + 1}
	if parts[0] == "@call":
		block.kind = "call"
		block.who = parts[1] if parts.size() > 1 else ""
		block.id = parts[2] if parts.size() > 2 else "call_" + block.who + "_" + str(_i)
	else:
		block.id = parts[1] if parts.size() > 1 else "beat_" + str(_i)
	_i += 1
	var ops: Array = []
	var if_stack: Array = []  # each: {"jif": index, "ends": [indices of jmp to patch]}
	while _i < _lines.size():
		var line := _clean(_lines[_i])
		if line == "":
			_i += 1
			continue
		if line == "@end":
			_i += 1
			break
		if line.begins_with("@when "):
			block.when = line.substr(6).strip_edges()
		elif line == "@repeat":
			block.repeat = true
		elif line.begins_with("@beat ") or line.begins_with("@call "):
			_err("missing @end before new block")
			break
		elif line.begins_with("if "):
			ops.append({"op": "jif", "expr": line.substr(3).strip_edges(), "to": -1})
			if_stack.append({"jif": ops.size() - 1, "ends": []})
		elif line.begins_with("elif "):
			if if_stack.is_empty():
				_err("elif without if")
			else:
				var top: Dictionary = if_stack[-1]
				ops.append({"op": "jmp", "to": -1})
				top.ends.append(ops.size() - 1)
				ops[top.jif].to = ops.size()
				ops.append({"op": "jif", "expr": line.substr(5).strip_edges(), "to": -1})
				top.jif = ops.size() - 1
		elif line == "else":
			if if_stack.is_empty():
				_err("else without if")
			else:
				var top2: Dictionary = if_stack[-1]
				ops.append({"op": "jmp", "to": -1})
				top2.ends.append(ops.size() - 1)
				ops[top2.jif].to = ops.size()
				top2.jif = -1
		elif line == "endif":
			if if_stack.is_empty():
				_err("endif without if")
			else:
				var top3: Dictionary = if_stack.pop_back()
				if top3.jif >= 0:
					ops[top3.jif].to = ops.size()
				for e in top3.ends:
					ops[e].to = ops.size()
		elif line.begins_with("choice "):
			ops.append(_parse_choice(line))
			continue
		elif line.begins_with("call "):
			ops.append(_parse_call(line))
			continue
		else:
			var op := _parse_op(line, block.kind == "call")
			if not op.is_empty():
				ops.append(op)
		_i += 1
	if not if_stack.is_empty():
		_err("unclosed if in block " + block.id)
	block.ops = ops
	return block


func _parse_op(line: String, in_call: bool) -> Dictionary:
	# call dialogue line  who: text | dur
	if in_call:
		var cl := _parse_call_line(line)
		if not cl.is_empty():
			return cl
	if line.begins_with("wait "):
		return {"op": "wait", "s": float(line.substr(5))}
	if line.begins_with("set "):
		return {"op": "set", "vals": _parse_kv(line.substr(4))}
	if line.begins_with("inc "):
		var a := _split_args(line.substr(4))
		return {"op": "inc", "key": a[0], "n": float(a[1]) if a.size() > 1 else 1.0}
	var gt := line.find(">")
	var sp := line.find(" ")
	if gt > 0 and (sp == -1 or gt < sp):
		return _parse_msg(line, gt)
	var args := _split_args(line)
	var name: String = args[0]
	args.remove_at(0)
	if not COMMANDS.has(name):
		_err("unknown command '%s'" % name)
		return {}
	if args.size() < int(COMMANDS[name]):
		_err("command '%s' needs %d args" % [name, COMMANDS[name]])
	return {"op": "cmd", "name": name, "args": args}


func _parse_msg(line: String, gt: int) -> Dictionary:
	var left := line.substr(0, gt)
	var text := line.substr(gt + 1).strip_edges()
	var thread := left
	var from := left
	if left.contains("@"):
		var p := left.split("@")
		from = p[0]
		thread = p[1]
	elif left.contains(":"):
		var p2 := left.split(":")
		thread = p2[0]
		from = p2[1]
	var op := {"op": "msg", "thread": thread, "from": from, "text": "", "id": "", "att": {}, "opts": {}}
	# leading tokens: #id  {opt=..}  [kind:id]
	var guard := 0
	while text != "" and guard < 10:
		guard += 1
		if text.begins_with("#"):
			var e := text.find(" ")
			if e == -1:
				op.id = text.substr(1)
				text = ""
			else:
				op.id = text.substr(1, e - 1)
				text = text.substr(e + 1).strip_edges()
		elif text.begins_with("{"):
			var e2 := text.find("}")
			if e2 == -1:
				_err("unclosed {")
				break
			for kv in text.substr(1, e2 - 1).split(",", false):
				var pair := kv.strip_edges().split("=")
				op.opts[pair[0].strip_edges()] = _value(pair[1].strip_edges()) if pair.size() > 1 else true
			text = text.substr(e2 + 1).strip_edges()
		elif text.begins_with("[") and text.find(":") > 0 and text.find("]") > text.find(":"):
			var e3 := text.find("]")
			var inner := text.substr(1, e3 - 1).split(":")
			op.att = {"type": inner[0], "id": inner[1]}
			text = text.substr(e3 + 1).strip_edges()
		else:
			break
	op.text = text.replace("\\n", "\n")
	return op


func _parse_call_line(line: String) -> Dictionary:
	if line.begins_with("[sfx ") and line.ends_with("]"):
		return {"op": "sfx", "name": line.substr(5, line.length() - 6).strip_edges()}
	if line.begins_with("- "):
		return {"op": "line", "who": "", "text": line.substr(2).strip_edges(), "dur": 0.0}
	var c := line.find(":")
	var sp := line.find(" ")
	if c > 0 and (sp == -1 or c < sp) and line.substr(0, c).is_valid_identifier():
		var who := line.substr(0, c)
		var rest := line.substr(c + 1).strip_edges()
		var dur := 0.0
		var bar := rest.rfind("|")
		if bar != -1:
			dur = float(rest.substr(bar + 1))
			rest = rest.substr(0, bar).strip_edges()
		return {"op": "line", "who": who, "text": rest.replace("\\n", "\n"), "dur": dur}
	return {}


func _parse_choice(header: String) -> Dictionary:
	var a := _split_args(header.substr(7))
	var op := {"op": "choice", "thread": a[0], "id": a[1] if a.size() > 1 else "c" + str(_i), "options": []}
	_i += 1
	while _i < _lines.size():
		var line := _clean(_lines[_i])
		_i += 1
		if line == "":
			continue
		if line == "end":
			break
		if not line.begins_with(">"):
			_err("choice option must start with '>' : " + line)
			continue
		var body := line.substr(1).strip_edges()
		var opt := {"text": "", "set": {}, "inc": {}, "cond": ""}
		if body.begins_with("{if "):
			var e := body.find("}")
			opt.cond = body.substr(4, e - 4).strip_edges()
			body = body.substr(e + 1).strip_edges()
		var bar := body.find(" | ")
		if bar != -1:
			var tail := body.substr(bar + 3).strip_edges()
			body = body.substr(0, bar).strip_edges()
			_parse_option_tail(tail, opt)
		opt.text = body.replace("\\n", "\n")
		op.options.append(opt)
	if op.options.is_empty():
		_err("choice without options")
	return op


## Option effects: "set a=1 b=true inc trust_x 2 inc other" (set/inc may repeat).
func _parse_option_tail(tail: String, opt: Dictionary) -> void:
	var toks := _split_args(tail)
	var i := 0
	while i < toks.size():
		var t: String = toks[i]
		if t == "set":
			i += 1
			continue
		if t == "inc":
			if i + 1 >= toks.size():
				_err("inc without key")
				break
			var key: String = toks[i + 1]
			var n := 1.0
			if i + 2 < toks.size() and str(toks[i + 2]).is_valid_float():
				n = float(toks[i + 2])
				i += 1
			opt.inc[key] = float(opt.inc.get(key, 0.0)) + n
			i += 2
			continue
		var eq := t.find("=")
		if eq == -1:
			opt.set[t] = true
		else:
			opt.set[t.substr(0, eq)] = _value(t.substr(eq + 1))
		i += 1


func _parse_call(header: String) -> Dictionary:
	var a := _split_args(header.substr(5))
	var op := {"op": "call", "who": a[0], "id": "", "ring": 14.0, "unknown": false, "number": "", "lines": [], "missable": true, "autoanswer": false}
	for i in range(1, a.size()):
		var t: String = a[i]
		if t == "unknown":
			op.unknown = true
		elif t == "forced":
			op.missable = false
		elif t == "autoanswer":
			op.autoanswer = true
		elif t == "outgoing":
			op.outgoing = true
			op.autoanswer = true
		elif t.contains("="):
			var kv := t.split("=")
			match kv[0]:
				"id": op.id = kv[1]
				"ring": op.ring = float(kv[1])
				"number": op.number = kv[1]
	if op.id == "":
		op.id = "call_%s_%d" % [op.who, _i]
	_i += 1
	while _i < _lines.size():
		var line := _clean(_lines[_i])
		_i += 1
		if line == "":
			continue
		if line == "end":
			break
		if line.begins_with("wait "):
			op.lines.append({"op": "wait", "s": float(line.substr(5))})
			continue
		var cl := _parse_call_line(line)
		if cl.is_empty():
			_err("bad call line: " + line)
		else:
			op.lines.append(cl)
	return op


func _parse_kv(s: String) -> Dictionary:
	var out := {}
	for tok in _split_args(s):
		var eq: int = tok.find("=")
		if eq == -1:
			out[tok] = true
		else:
			out[tok.substr(0, eq)] = _value(tok.substr(eq + 1))
	return out


static func _value(s: String):
	if s == "true":
		return true
	if s == "false":
		return false
	if s.is_valid_int():
		return int(s)
	if s.is_valid_float():
		return float(s)
	if s.length() >= 2 and s.begins_with("\"") and s.ends_with("\""):
		return s.substr(1, s.length() - 2)
	return s


## Splits on spaces, keeping "quoted strings" together (quotes removed).
static func _split_args(s: String) -> Array:
	var out: Array = []
	var cur := ""
	var in_q := false
	var had_q := false
	for ch in s:
		if ch == "\"":
			in_q = not in_q
			had_q = true
			continue
		if ch == " " and not in_q:
			if cur != "" or had_q:
				out.append(cur)
			cur = ""
			had_q = false
			continue
		cur += ch
	if cur != "" or had_q:
		out.append(cur)
	return out
