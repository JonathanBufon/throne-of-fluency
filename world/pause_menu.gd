extends CanvasLayer

@onready var resume_button: TextureButton = $bg_overlay/menu_holder/resume_button
@onready var quit_button: TextureButton = $bg_overlay/menu_holder/quit_button
@onready var animator: AnimationPlayer = $animator
	

func _ready():
	visible = false


func _unhandled_input(event):
	if event.is_action_pressed("ui_cancel"):
		visible = true
		animator.play("pause_game")
		get_tree().paused = true	
		resume_button.grab_focus()
