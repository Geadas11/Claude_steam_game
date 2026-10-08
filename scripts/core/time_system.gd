extends Node
## In-game clock. Time is stored in GameState.data.time as unix seconds
## (treated as local time, no timezone conversion).
##
## By default one game minute passes every `seconds_per_minute` real seconds.
## When the player is idle and the narrative is only waiting on the clock, the
## clock accelerates so that nobody has to stare at a frozen phone.

const WEEKDAYS := ["domingo", "segunda-feira", "terça-feira", "quarta-feira", "quinta-feira", "sexta-feira", "sábado"]
const MONTHS := ["janeiro", "fevereiro", "março", "abril", "maio", "junho", "julho", "agosto", "setembro", "outubro", "novembro", "dezembro"]

var seconds_per_minute := 5.0
var rate := 1.0            # narrative multiplier (story `rate` command)
var running := false
var idle_boost := 1.0
var frozen_display := ""   # when set, the status bar shows this instead (impossible time)
var _last_minute := -1
var _idle_time := 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE


func _input(event: InputEvent) -> void:
	# _input sees GUI clicks too (unlike _unhandled_input), so tapping around
	# the phone counts as activity.
	if event is InputEventMouseButton or event is InputEventKey or event is InputEventJoypadButton:
		_idle_time = 0.0
	elif event is InputEventMouseMotion and event.relative.length() > 4.0:
		_idle_time = minf(_idle_time, 10.0)


func notify_activity() -> void:
	_idle_time = 0.0


func _process(delta: float) -> void:
	if not running or not GameState.in_game:
		return
	_idle_time += delta
	GameState.data.playtime = float(GameState.data.playtime) + delta
	idle_boost = 1.0
	if _idle_time > 25.0 and Director.waiting_on_clock():
		idle_boost = 6.0
	var speed := rate * idle_boost / maxf(seconds_per_minute, 0.01)
	GameState.data.time = float(GameState.data.time) + delta * speed * 60.0
	var m := int(GameState.data.time / 60.0)
	if m != _last_minute:
		_last_minute = m
		Events.time_changed.emit(GameState.data.time)


func now() -> float:
	return float(GameState.data.time)


func set_time(unix: float) -> void:
	GameState.data.time = unix
	_last_minute = -1
	Events.time_changed.emit(unix)


func advance_minutes(m: float) -> void:
	set_time(now() + m * 60.0)


## Sets the clock to the next occurrence of HH:MM (today or tomorrow).
func set_clock(hhmm: String) -> void:
	set_time(next_occurrence(hhmm, now()))


func next_occurrence(hhmm: String, from_unix: float) -> float:
	var p := hhmm.split(":")
	var h := int(p[0])
	var mi := int(p[1]) if p.size() > 1 else 0
	var day_start := floorf(from_unix / 86400.0) * 86400.0
	var t := day_start + h * 3600 + mi * 60
	if t < from_unix - 30.0:
		t += 86400.0
	return t


static func parse_datetime(s: String) -> float:
	## "2026-10-08 21:30" -> unix seconds
	var parts := s.strip_edges().split(" ")
	var d := parts[0].split("-")
	var dict := {"year": int(d[0]), "month": int(d[1]), "day": int(d[2]), "hour": 0, "minute": 0, "second": 0}
	if parts.size() > 1:
		var hm := parts[1].split(":")
		dict.hour = int(hm[0])
		dict.minute = int(hm[1])
	return float(Time.get_unix_time_from_datetime_dict(dict))


static func fmt_time(unix: float) -> String:
	var d := Time.get_datetime_dict_from_unix_time(int(unix))
	return "%02d:%02d" % [d.hour, d.minute]


static func fmt_date_long(unix: float) -> String:
	var d := Time.get_datetime_dict_from_unix_time(int(unix))
	return "%s, %d de %s" % [WEEKDAYS[d.weekday], d.day, MONTHS[d.month - 1]]


static func fmt_date_short(unix: float) -> String:
	var d := Time.get_datetime_dict_from_unix_time(int(unix))
	return "%02d/%02d/%04d" % [d.day, d.month, d.year]


## "Agora", "14:02", "Ontem", "seg", "12/03/2025" relative to the game clock.
func fmt_relative(unix: float) -> String:
	var n := now()
	var diff := n - unix
	if diff < 0:
		# a timestamp from the future — show it plainly. That's the horror.
		return fmt_date_short(unix) + " " + fmt_time(unix)
	if diff < 60:
		return "Agora"
	var day_now := floori(n / 86400.0)
	var day_t := floori(unix / 86400.0)
	if day_now == day_t:
		return fmt_time(unix)
	if day_now - day_t == 1:
		return "Ontem"
	if day_now - day_t < 7:
		var d := Time.get_datetime_dict_from_unix_time(int(unix))
		return WEEKDAYS[d.weekday].substr(0, 3)
	return fmt_date_short(unix)


func display_time() -> String:
	if frozen_display != "":
		return frozen_display
	return fmt_time(now())


func hour() -> int:
	return Time.get_datetime_dict_from_unix_time(int(now())).hour
