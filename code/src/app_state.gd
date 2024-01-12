extends Node3D

@export var worker_thread_id = 0
@export var busy = false
@export var tiles_storage: StringName = "user://"
@export var speed = 0
@export var webserver: Webserver
@export var world: World 
@export var main: Main
var car
var player = car



# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#get_tree().root.add_child.call_deferred(main)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
