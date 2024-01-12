extends Node3D

#var main
var once = true
var ctr = 0
var carres = load("res://car.tscn") as PackedScene
var webres = load("res://webserver.tscn") as PackedScene
var worldres = load("res://world.tscn") as PackedScene
var mainres = load("res://main.tscn") as PackedScene
@export var webserver: Webserver = webres.instantiate()
@export var world: World = worldres.instantiate()
@export var car = carres.instantiate()
@export var main = mainres.instantiate()
@export var player = car

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if main == null:
		main = mainres.instantiate()
	if !webserver.is_inside_tree():
		get_tree().root.add_child.call_deferred(webserver)
	if !world.is_inside_tree():
		get_tree().root.add_child.call_deferred(world)
	if !car.is_inside_tree():
		get_tree().root.add_child.call_deferred(car)
	if !main.is_inside_tree():
		get_tree().root.add_child.call_deferred(main)
	AppState.webserver = webserver
	AppState.world = world
	AppState.car = car
	AppState.main = main
	#main.has_method("load")
	#if typeof(main.load) == TYPE_CALLABLE:
	#	main.load()
	#main = load("res://main.tscn") as PackedScene
	#main.resource_name = "Main"
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	ctr = ctr + 1
	if !webserver.is_inside_tree():
		get_tree().root.add_child.call_deferred(webserver)
	if !world.is_inside_tree():
		get_tree().root.add_child.call_deferred(world)
	if !car.is_inside_tree():
		get_tree().root.add_child.call_deferred(car)
	if !main.is_inside_tree():
		get_tree().root.add_child.call_deferred(main)
	else:
		if once:
			once = false
			#AppState.worker_thread_id = WorkerThreadPool.add_task(main.load)		
	AppState.webserver = webserver
	AppState.world = world
	AppState.car = car
	AppState.main = main
	#var node = get_node_or_null("/root/Main")
		#if node != null:
			#node._load()
	#AppState.main = node
	if once:
		once = false
		#AppState.worker_thread_id = WorkerThreadPool.add_task(main._load)		
		#get_tree().root.add_child(main.instantiate())
		
func run():
	AppState.node._load()
