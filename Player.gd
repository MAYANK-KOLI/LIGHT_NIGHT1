extends KinematicBody
var health = 1
export var speed = 10
export var acceleration = 5
export var gravity = 0.5
export var jump_power = 40

export var mouse_sensitivity = 0.3

var direction
var wall_normal
var dead_speed = 15

var grappling = false
var hookpoint = Vector3()
var hookpoint_get = false

onready var head = $Head
onready var camera = $Head/Camera
onready var timer = $Timer
onready var grapplecast = $Head/Camera/GrappleCast

const RESPAWN_TIME = 4
var dead_time = 0
var is_dead = false
var w_runnable = false
var globals
var fall = Vector3()
var velocity = Vector3()
var camera_x_rotation = 0
var can_slide = false

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _input(event):
	if is_dead:
		return
	if event is InputEventMouseMotion:
		head.rotate_y(deg2rad(-event.relative.x * mouse_sensitivity))

		var x_delta = event.relative.y * mouse_sensitivity
		if camera_x_rotation + x_delta > -90 and camera_x_rotation + x_delta < 90: 
			camera.rotate_x(deg2rad(-x_delta))
			camera_x_rotation += x_delta

func grapple():
	if Input.is_action_just_pressed("ability"):
		if grapplecast.is_colliding():
			if not grappling:
				grappling = true
	if grappling:
		gravity = 0
		if not hookpoint_get:
			hookpoint = grapplecast.get_collision_point()+Vector3(0, 2.25, 0)
			hookpoint_get = true
		if hookpoint.distance_to(transform.origin) > 1:
			if hookpoint_get:
				transform.origin = lerp(transform.origin, hookpoint, 0.05)
		else:
			grappling = false
			hookpoint_get = false

func wallrun():
	if w_runnable:
		if Input.is_action_pressed("jump"):
			if Input.is_action_pressed("front") and is_on_wall():
				wall_normal = get_slide_collision(0)
				velocity.y = 0

func _process(delta):
	if Input.is_action_just_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _physics_process(delta):
	grapple()
	wallrun()
	var head_basis = head.get_global_transform().basis
	
	direction = Vector3()
	if Input.is_action_pressed("front"):
		direction -= head_basis.z
	elif Input.is_action_pressed("back"):
		direction += head_basis.z
	if Input.is_action_pressed("slide"):
		speed = 20
		self.scale=Vector3(0.5,0.5,0.5)
	if Input.is_action_just_released("slide"):
			can_slide = true
			speed = 10
			self.scale=Vector3(1,1,1)
	if Input.is_action_pressed("left"):
		direction -= head_basis.x
	elif Input.is_action_pressed("right"):
		direction += head_basis.x
	if Input.is_action_pressed("slow"):
		Engine.time_scale = 0.05
	if Input.is_action_just_released("slow"):
		Engine.time_scale = 1.5
	

	direction = direction.normalized()
	
	velocity = velocity.linear_interpolate(direction * speed, acceleration * delta)
	velocity.y -= gravity
	
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y += jump_power
		w_runnable = true
		timer.start()



	velocity = move_and_slide(velocity, Vector3.UP)

func _on_Area_body_exited(body):
	
	get_tree().reload_current_scene()

func _on_Timer_timeout():
	w_runnable = false


