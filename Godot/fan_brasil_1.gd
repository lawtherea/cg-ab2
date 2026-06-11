extends Node3D

@onready var animator = get_node("AnimationPlayer") as AnimationPlayer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	animator.play("mixamo_com")
