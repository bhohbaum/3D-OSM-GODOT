extends Node3D

############################
#Set start position here
#const START_X = 48440
#const START_Y =  8700
###########################

const START_X = 34319
const START_Y = 22950

#DO NOT TOUCH!!!
const MVT_READER = preload("res://addons/geo-tile-loader/vector_tile_loader.gd")
#const WEBSERVER = preload("res://src/webserver.gd")
const CONSTANTS = preload("res://src/common/constants.gd")
const POLYGON_VECTOR_CALCULATOR = preload("res://src/polygons/calculate_polygon_vectors.gd")
const POLYGON_HEIGHT_CALCULATOR = preload("res://src/polygons/calculate_polygon_heights.gd")
const POLYGON_BUILDER = preload("res://src/polygons/build_polygons.gd")
const LINESTRING_VECTOR_CALCULATOR = preload(
	"res://src/linestrings/calculate_linestring_vectors.gd"
)
const LINESTRING_BUILDER = await preload("res://src/linestrings/build_linestrings.gd")
const POINTS = preload("res://src/points/pois.gd")
const FLOOR_BUILDER = preload("res://src/common/create_floor.gd")

@export var preload_distance = 2
@export var world_nodes = PackedStringArray()


@onready var webserver = $Webserver
@onready var world = $World

var tiles_loaded_x_max = 2
var tiles_loaded_x_min = -2
var tiles_loaded_y_max = 2
var tiles_loaded_y_min = -2

#updated process points
var process_x = null
var process_y = null

var steps_x = 0
var steps_y = 0

var tile_distance_x = 0
var tile_distance_y = 0

var init_i = -2
var init_j = -2

var current_x = 0
var current_y = 0
var offset_x = 0
var offset_y = 0

var tile_node_current = Node3D

func _ready():
#loading of initial 4*4 area
	process_x = START_X
	process_y = START_Y
	AppState.worker_thread_id = WorkerThreadPool.add_task(_cleanup_worker)	
	

func _on_download_completed(success, current_x, current_y, offset_x, offset_y):
	self.current_x = current_x
	self.current_y = current_y
	self.offset_x = offset_x
	self.offset_y = offset_y	
	if success:
		print("download successfull for: x=", current_x, ", ", current_y)
		var current_tile_node_path = str(current_x) + str(current_y)
		tile_node_current = $World.get_node(current_tile_node_path)

		if tile_node_current == null:
			$Webserver.download_file(current_x, current_y, offset_x, offset_y)
			return
		AppState.worker_thread_id = WorkerThreadPool.add_task(render_geometries)
	else:
		print("Download failed or timed out.")
	#AppState.busy = false

func render_geometries():
	var tilepath = AppState.tiles_storage + str(current_x) + str(current_y)
	var tile = MVT_READER.load_tile(tilepath)

	#var current_tile_node_path = str(current_x) + str(current_y)

	FLOOR_BUILDER.build_floor(tile_node_current, offset_x, offset_y)

	for layer in tile.layers():
		print("Layer " + layer.name() + "\n")
		if layer.name() == CONSTANTS.HIGHWAYS:
			for feature in layer.features():
				for i in range(0, feature.tags(layer).size(), 1):
					print_debug(feature.tags(layer))
					print("\n")
				var width = null
				if feature.tags(layer).has("pathType"):
					if CONSTANTS.WIDTHS.has(feature.tags(layer).pathType):
						width = CONSTANTS.WIDTHS[feature.tags(layer).pathType]
					
				var linestring_geometries = (
					LINESTRING_VECTOR_CALCULATOR.build_linestring_geometries(feature.geometry())
				)
				LINESTRING_BUILDER.generate_paths(
					linestring_geometries,
					tile_node_current,
					Color(0, 0, 0, 1),
					offset_x,
					offset_y,
					width
				)

		if layer.name() == CONSTANTS.BUILDINGS:
			for feature in layer.features():
				var polygon_height = POLYGON_HEIGHT_CALCULATOR.get_polygon_height(feature, layer)

				var sanitized_geometries = POLYGON_VECTOR_CALCULATOR.build_polygon_geometries(
					feature.geometry()
				)
				var polygon_geometries = POLYGON_VECTOR_CALCULATOR.calculate_polygon_vectors(
					sanitized_geometries
				)

				POLYGON_BUILDER.generate_polygons(
					polygon_geometries,
					tile_node_current,
					Color(0.5, 0.5, 0.5, 1.0),
					offset_x,
					offset_y,
					polygon_height
				)

		if layer.name() == CONSTANTS.COMMON:
			for feature in layer.features():
				var sanitized_geometries = POLYGON_VECTOR_CALCULATOR.build_polygon_geometries(
					feature.geometry()
				)
				var polygon_geometries = POLYGON_VECTOR_CALCULATOR.calculate_polygon_vectors(
					sanitized_geometries
				)

				POLYGON_BUILDER.generate_polygons(
					polygon_geometries,
					tile_node_current,
					Color(0.133, 0.545, 0.133, 1.0),
					offset_x,
					offset_y,
					0.5
				)

		if layer.name() == CONSTANTS.WATER:
			for feature in layer.features():
				var type = feature.geom_type()
				if type["GeomType"] == "LINESTRING":
					var linestring_geometries = (
						LINESTRING_VECTOR_CALCULATOR.build_linestring_geometries(feature.geometry())
					)
					LINESTRING_BUILDER.generate_paths(
						linestring_geometries,
						tile_node_current,
						Color(0.004, 0.34, 0.61, 0.4),
						offset_x,
						offset_y
					)

				if type["GeomType"] == "POLYGON":
					var sanitized_geometries = POLYGON_VECTOR_CALCULATOR.build_polygon_geometries(
						feature.geometry()
					)
					var polygon_geometries = POLYGON_VECTOR_CALCULATOR.calculate_polygon_vectors(
						sanitized_geometries
					)

					POLYGON_BUILDER.generate_polygons(
						polygon_geometries,
						tile_node_current,
						Color(0.004, 0.34, 0.61, 0.4),
						offset_x,
						offset_y
					)

		if layer.name() == CONSTANTS.POINT:
			POINTS.generate_pois(tile, tile_node_current, offset_x, offset_y)

		if layer.name() == CONSTANTS.NATURAL:
			for feature in layer.features():
				var sanitized_geometries = POLYGON_VECTOR_CALCULATOR.build_polygon_geometries(
					feature.geometry()
				)
				var polygon_geometries = POLYGON_VECTOR_CALCULATOR.calculate_polygon_vectors(
					sanitized_geometries
				)

				POLYGON_BUILDER.generate_polygons(
					polygon_geometries,
					tile_node_current,
					Color(0.21, 0.42, 0.21, 1),
					offset_x,
					offset_y,
					0.5
				)

# _process needs an argument, even if its never used
# gdlint:ignore = unused-argument
func _process(delta):
	if init_i < 2 && init_j < 2:
		var tile_node = Node3D.new()
		tile_node.name = str(START_X + init_i) + str(START_Y + init_j)
		$World.add_child(tile_node)
		if !$Webserver.is_connected("download_completed", _on_download_completed):
			$Webserver.connect("download_completed", _on_download_completed)
		process_x = START_X + init_i
		process_y = START_Y + init_j
		$Webserver.download_file(
			process_x, process_y, CONSTANTS.OFFSET * init_i, CONSTANTS.OFFSET * init_j
		)
		init_i += 1
		if init_i == 2:
			init_i = -2
			init_j += 1
	else:
		tile_distance_x = int($Player.position.x / CONSTANTS.OFFSET)
		tile_distance_y = int($Player.position.z / CONSTANTS.OFFSET)
		if !AppState.busy:
			AppState.worker_thread_id = WorkerThreadPool.add_task(_load)


func _load():
	#load tiles if going to wards positive x loaded border
	if tile_distance_x > (tiles_loaded_x_max - preload_distance):
		tiles_loaded_x_max += 1
		tiles_loaded_x_min += 1
		process_x = process_x + 2

		steps_x += 1

		for i in range(-2, 2, 1):
			var tile_node = Node3D.new()
			await world.call_deferred("add_child", tile_node)
			tile_node.name = str(process_x) + str(process_y + i)
			await webserver.call_deferred("download_file",
				process_x,
				process_y + i,
				CONSTANTS.OFFSET * (tiles_loaded_x_max - 1),
				CONSTANTS.OFFSET * (i + steps_y)
			)

			await world.call_deferred("remove_child", await world.call_deferred("get_node", str(process_x + i) + str(process_y + 4)))

		process_x = process_x - 1

	#load tiles of going towards negative x border
	if tile_distance_x < (tiles_loaded_x_min + preload_distance):
		tiles_loaded_x_max -= 1
		tiles_loaded_x_min -= 1
		process_x = process_x - 3

		steps_x -= 1

		for i in range(-2, 2, 1):
			var tile_node = Node3D.new()
			await world.call_deferred("add_child", tile_node)
			tile_node.name = str(process_x) + str(process_y + i)
			await webserver.call_deferred("download_file",
				process_x,
				process_y + i,
				CONSTANTS.OFFSET * (tiles_loaded_x_min),
				CONSTANTS.OFFSET * (i + steps_y)
			)

			await world.call_deferred("remove_child", await world.call_deferred("get_node", str(process_x + i) + str(process_y + 4)))

		process_x = process_x + 2

	#load tiles if going towards positive y border
	if tile_distance_y > (tiles_loaded_y_max - preload_distance):
		tiles_loaded_y_max += 1
		tiles_loaded_y_min += 1
		process_y = process_y + 2

		steps_y += 1

		for i in range(-2, 2, 1):
			var tile_node = Node3D.new()
			await world.call_deferred("add_child", tile_node)
			tile_node.name = str(process_x + i) + str(process_y)
			await webserver.call_deferred("download_file",
				process_x + i,
				process_y,
				CONSTANTS.OFFSET * (i + steps_x),
				CONSTANTS.OFFSET * (tiles_loaded_y_max - 1)
			)

			await world.call_deferred("remove_child", await world.call_deferred("get_node", str(process_x + i) + str(process_y + 4)))

		process_y = process_y - 1

	#load tiles if going towards negative y border
	if tile_distance_y < (tiles_loaded_y_min + preload_distance):
		tiles_loaded_y_max -= 1
		tiles_loaded_y_min -= 1
		process_y = process_y - 3

		steps_y -= 1

		for i in range(-2, 2, 1):
			var tile_node = Node3D.new()
			await world.call_deferred("add_child", tile_node)
			tile_node.name = str(process_x + i) + str(process_y)
			await webserver.call_deferred("download_file",
				process_x + i,
				process_y,
				CONSTANTS.OFFSET * (i + steps_x),
				CONSTANTS.OFFSET * tiles_loaded_y_min
			)

			await world.call_deferred("remove_child", await world.call_deferred("get_node", str(process_x + i) + str(process_y + 4)))

		process_y = process_y + 2

	
func _cleanup_worker():
	for node in world_nodes:
		if str(int(node.name)) != node.name:
			WorkerThreadPool.wait_for_task_completion(AppState.worker_thread_id)
			world.call_deferred("remove_child", node)
