class_name Dialogo_Acao_Input extends Control

## Emitido quando o jogador confirma a entrada.
## [param text] é o texto digitado. [param correct] indica se estava certo.
signal submitted(text: String, correct: bool)

# ──────────────────────────────────────────────
#  Exportáveis — configure no Inspetor
# ──────────────────────────────────────────────
@export var hint_text: String = "What is the action to open the door?"
@export var correct_answer: String = "open"
@export var max_chars: int = 32
@export var cursor_blink_speed: float = 0.55   # segundos por ciclo

# ──────────────────────────────────────────────
#  Nós internos (devem existir na cena)
# ──────────────────────────────────────────────
@onready var hint_label: Label       = $MarginContainer/VBoxContainer/HintLabel
@onready var input_label: Label      = $MarginContainer/VBoxContainer/InputRow/InputLabel
@onready var cursor_label: Label     = $MarginContainer/VBoxContainer/InputRow/CursorLabel
@onready var feedback_label: Label   = $MarginContainer/VBoxContainer/FeedBackLabel
@onready var anim_player: AnimationPlayer = $AnimationPlayer

# ──────────────────────────────────────────────
#  Estado interno
# ──────────────────────────────────────────────
var _typed: String = ""
var _cursor_visible: bool = true
var _cursor_timer: float = 0.0
var _accepting: bool = false   # bloqueia input durante feedback

# ──────────────────────────────────────────────
#  Ciclo de vida
# ──────────────────────────────────────────────
func _ready() -> void:
	hint_label.text = hint_text
	_refresh_display()
	feedback_label.text = ""
	feedback_label.modulate.a = 0.0
	set_process_unhandled_key_input(false)
	hide()


func _process(delta: float) -> void:
	# Piscar do cursor
	_cursor_timer += delta
	if _cursor_timer >= cursor_blink_speed:
		_cursor_timer = 0.0
		_cursor_visible = !_cursor_visible
		cursor_label.visible = _cursor_visible


func _unhandled_key_input(event: InputEvent) -> void:
	if _accepting:
		return

	if not event is InputEventKey or not event.pressed:
		return

	if event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER:
		_confirm()
		return

	if event.keycode == KEY_BACKSPACE:
		if _typed.length() > 0:
			_typed = _typed.left(_typed.length() - 1)
			_refresh_display()
		return

	if event.keycode == KEY_ESCAPE:
		_cancel()
		return

	# Aceita apenas caracteres imprimíveis
	var ch: String = char(event.unicode)
	if ch.length() > 0 and event.unicode >= 32 and _typed.length() < max_chars:
		_typed += ch
		_refresh_display()


# ──────────────────────────────────────────────
#  API pública
# ──────────────────────────────────────────────

## Abre o modal e aguarda o jogador confirmar.
## Retorna [code]true[/code] se a resposta estava correta.
func ask() -> bool:
	_typed = ""
	_accepting = false
	feedback_label.text = ""
	feedback_label.modulate.a = 0.0
	_refresh_display()
	show()
	set_process_unhandled_key_input(true)

	# Animação de entrada (se existir)
	if anim_player and anim_player.has_animation("open"):
		anim_player.play("open")

	var result: Array = await submitted
	return result[1]   # correct


# ──────────────────────────────────────────────
#  Lógica interna
# ──────────────────────────────────────────────
func _refresh_display() -> void:
	input_label.text = _typed


func _confirm() -> void:
	_accepting = true
	set_process_unhandled_key_input(false)

	var correct: bool = _typed.strip_edges().to_lower() == correct_answer.strip_edges().to_lower()

	if correct:
		_show_feedback("✦  The Door Creaks and opens ✦", true)
	else:
		_show_feedback("✗  Wrong Action", false)

	# Aguarda o feedback ser lido antes de fechar
	await get_tree().create_timer(1.8).timeout
	_close(correct)


func _cancel() -> void:
	set_process_unhandled_key_input(false)
	_close(false)


func _close(correct: bool) -> void:
	if anim_player and anim_player.has_animation("close"):
		anim_player.play("close")
		await anim_player.animation_finished

	submitted.emit(_typed, correct)
	hide()


func _show_feedback(msg: String, success: bool) -> void:
	feedback_label.text = msg
	feedback_label.add_theme_color_override(
		"font_color",
		Color(0.0, 0.21, 0.269, 1.0) if success else Color(0.85, 0.3, 0.3)
	)
	# Fade-in simples via tween
	var tw: Tween = create_tween()
	tw.tween_property(feedback_label, "modulate:a", 1.0, 0.3)
