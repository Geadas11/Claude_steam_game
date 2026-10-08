class_name CoopPanel
extends MenuPanel
## "Jogar online": create a room (you are Daniel) or join one (you are Sofia).
## The host's game is the server for the session; on Steam the friend is
## invited through Steam, otherwise a room code carries the address.

var _status: Label
var _code: Label
var _info: Label
var _start: Button
var _invite: Button


func _ready() -> void:
	make("Jogar online", 640)
	Coop.status_changed.connect(func(t): if is_instance_valid(_status): _status.text = t)
	Coop.code_changed.connect(func(_c): _refresh())
	Coop.partner_changed.connect(func(_p): _refresh())
	if Coop.transport != null:
		_room_view()
	else:
		_choose_view()


func close() -> void:
	if not Coop.active:
		Coop.leave()
	super.close()


func _choose_view() -> void:
	UI.clear(body)
	body.add_child(UI.label("Dois jogadores, dois telemóveis, a mesma semana.", 17, "text", true))
	body.add_child(UI.label("Quem cria a sala é o Daniel, em Salgueira. Quem entra é a Sofia, a irmã, em Lisboa. O jogo de quem cria a sala serve de ponte entre os dois enquanto jogam.", 14, "dim", true))
	body.add_child(UI.label("Em construção: a história da Sofia existe por agora no capítulo 1. Nos outros capítulos, o telemóvel dela acompanha a conversa com o Daniel.", 13, "faint", true))
	body.add_child(UI.spacer(6))
	body.add_child(MenuPanel.menu_button("Criar sala — sou o Daniel", func():
		Coop.create_room()
		_room_view(), 19))
	body.add_child(UI.spacer(4))
	body.add_child(UI.label("Entrar numa sala — sou a Sofia", 15, "accent"))
	var h := UI.hbox(10)
	var le := LineEdit.new()
	le.placeholder_text = "Código da sala"
	le.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	le.custom_minimum_size = Vector2(0, 44)
	h.add_child(le)
	var go := func(_t = ""):
		if le.text.strip_edges() != "":
			Coop.join_room(le.text)
			_room_view()
	le.text_submitted.connect(go)
	h.add_child(UI.pill_button("Entrar", go, "surf2", "accent"))
	body.add_child(h)
	body.add_child(UI.label("Ligação: " + ("Steam" if Coop.uses_steam() else "direta (mesma rede ou porta aberta no router)"), 12, "faint", true))


func _room_view() -> void:
	UI.clear(body)
	body.add_child(UI.label("És o Daniel." if Coop.is_host else "És a Sofia.", 17, "accent"))
	_code = UI.label("", 28, "text")
	_code.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.add_child(_code)
	_info = UI.label("", 13, "dim", true)
	body.add_child(_info)
	_status = UI.label(Coop.status, 15, "text", true)
	body.add_child(_status)
	var h := UI.hbox(12)
	var copy := UI.pill_button("Copiar código", func():
		DisplayServer.clipboard_set(Coop.code)
		Events.toast_requested.emit("Código copiado"), "surf2", "text")
	copy.visible = Coop.is_host
	h.add_child(copy)
	_invite = UI.pill_button("Convidar amigo do Steam", func(): Coop.transport.invite(), "surf2", "text")
	h.add_child(_invite)
	_start = UI.pill_button("Começar", func(): Coop.start_game(), "surf2", "accent")
	h.add_child(_start)
	body.add_child(h)
	body.add_child(UI.pill_button("Sair da sala", func():
		Coop.leave()
		_choose_view(), "surf", "dim"))
	_refresh()


func _refresh() -> void:
	if not is_instance_valid(_code):
		return
	_code.text = Coop.code if Coop.is_host else ""
	_code.visible = Coop.is_host and Coop.code != ""
	# the code is already shown in big: keep only the explanation
	_info.text = Coop.describe().get_slice("\n", 1) if Coop.is_host and Coop.describe().contains("\n") else ""
	_start.visible = Coop.is_host
	_start.disabled = not Coop.partner_present
	_invite.visible = Coop.is_host and Coop.transport != null and Coop.transport.can_invite()
