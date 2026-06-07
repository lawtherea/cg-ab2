extends CharacterBody3D


const SPEED = 500.0
const JUMP_VELOCITY = 10.0

@onready var animator = get_node("teste1jogador/AnimationPlayer") as AnimationPlayer

@export var view : Node3D
var gravity = 0
var moviment_velocity : Vector3
var rotation_direction : float

func _physics_process(delta: float) -> void:
	handle_input(delta)
	apply_gravity(delta)
	jump(delta)
	handle_animations()
	
	var applied_velocity : Vector3 
	applied_velocity = velocity.lerp(moviment_velocity, delta * 10)
	applied_velocity.y = -gravity
	
	velocity = applied_velocity

	move_and_slide()
	
	if Vector2(velocity.z, velocity.x).length() > 0:
		rotation_direction = Vector2(velocity.z, velocity.x).angle()
		
	rotation.y = lerp_angle(rotation.y, rotation_direction, delta * 10)
	
	
	
func handle_input(delta):
	var input := Vector3.ZERO
	input.x = Input.get_axis("move_left", "move_right")
	input.z = Input.get_axis("move_forward", "move_backward")
	
	input = input.rotated(Vector3.UP, view.rotation.y).normalized()
	
	velocity = input * SPEED * delta
	
func handle_animations():
		if abs(velocity.x) > 1 or abs(velocity.z) > 1:
			animator.play("slow run", 0.3)
		else :
			animator.play("idle", 0.3)
		
	
func apply_gravity(delta):
	if not is_on_floor():
			gravity += 25 * delta
	
func jump(delta):
	if Input.is_action_just_pressed("jump") and is_on_floor():
		gravity = -JUMP_VELOCITY
		
	if gravity > 0 and is_on_floor():
		gravity = 0
	
