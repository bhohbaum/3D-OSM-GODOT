extends VehicleBody3D
#class_name Car

@export var STEER_SPEED = 1.5
@export var STEER_LIMIT = 0.6
var steer_target = 0
@export var engine_force_value = 40
var thread: Thread = Thread.new()

var ctr= 0

signal update_speed(speed)


func _ready() -> void:
	set_physics_process(false)
	pass
	

func _physics_process(delta):
	var speed = linear_velocity.length()*Engine.get_frames_per_second()*delta
	#call_thread_safe("traction", speed)
	if !is_inside_tree():
		return
	#if super.has_method("traction"):
	#use_as_traction(speed)
	AppState.speed = speed
	emit_signal("update_speed")
	#$Hud/speed.call_thread_safe("set_text", str(round(speed*3.8))+"  Km/h")

	var fwd_mps = transform.basis.x.x
	steer_target = Input.get_action_strength("ui_left") - Input.get_action_strength("ui_right")
	steer_target *= STEER_LIMIT
	if Input.is_action_pressed("ui_down"):
	# Increase engine force at low speeds to make the initial acceleration faster.

		if speed < 20 and speed != 0:
			engine_force = clamp(engine_force_value * 3 / speed, 0, 300)
		else:
			engine_force = engine_force_value
	else:
		engine_force = 0
	if Input.is_action_pressed("ui_up"):
		# Increase engine force at low speeds to make the initial acceleration faster.
		if fwd_mps >= -1:
			if speed < 30 and speed != 0:
				engine_force = -clamp(engine_force_value * 10 / speed, 0, 300)
			else:
				engine_force = -engine_force_value
		else:
			brake = 1
	else:
		brake = 0.0
		
	if Input.is_action_pressed("ui_select"):
		brake=3
		$wheal2.wheel_friction_slip=0.8
		$wheal3.wheel_friction_slip=0.8
	else:
		$wheal2.wheel_friction_slip=3
		$wheal3.wheel_friction_slip=3
	steering = move_toward(steering, steer_target, STEER_SPEED * delta)

	if Input.is_action_pressed("respawn"):
		call_thread_safe("respawn")

func respawn():
	linear_velocity.move_toward(Vector3(30, 4, 2), 10)
	set_global_transform(Transform3D(Basis.IDENTITY, Vector3(30, 4, 2)))
	apply_central_force(Vector3.DOWN)


func freeze():
	AppState.main.locked = true
	pass


func unfreeze():
	AppState.main.locked = false
	pass



func _on_main_unfreeze_car() -> void:
	unfreeze()
	pass # Replace with function body.


func _on_tree_entered() -> void:
	AppState.worker_thread_id = WorkerThreadPool.add_task(AppState.main.render_geometries)
	#AppState.main.call_deferred("render_geometries")
	pass # Replace with function body.
