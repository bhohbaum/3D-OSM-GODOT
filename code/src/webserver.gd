class_name Webserver 

extends Node


@export var current_x = 0
@export var current_y = 0
@export var offset_x = 0
@export var offset_y = 0
@export var http_request = HTTPRequest.new()
@export var download_list = PackedStringArray()
@export var download_http = "https://tiles.streets.gl/vector/16/"
@export var download_local = AppState.tiles_storage
@export var busy = AppState.busy
		


signal download_completed(success, x, y, offset_x, offset_y)


func _ready() -> void:
	AppState.busy = false
	http_request.use_threads = true
	http_request.request_completed.connect(_on_request_completed)
	call_deferred("add_child", http_request)


func download_file(x, y, offset_x, offset_y):
	var json = JSON.stringify([x, y, offset_x, offset_y])
	download_list.append(json)

func _process(delta: float) -> void:
	AppState.busy = download_list.size() > 2
#	if AppState.busy:
#		return
	if http_request.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		return
	var json = null
	if !download_list.is_empty():
		json = download_list[0]
		download_list.remove_at(0)
	else:
		return
	self.current_x = JSON.parse_string(json)[0]
	self.current_y = JSON.parse_string(json)[1]
	self.offset_x = JSON.parse_string(json)[2]
	self.offset_y = JSON.parse_string(json)[3]
	#call_deferred("add_child", http_request)
	download_http = "https://tiles.streets.gl/vector/16/" + str(self.current_x) + "/" + str(self.current_y)
	download_local = AppState.tiles_storage + str(self.current_x) + str(self.current_y)
	http_request.download_file = download_local
	if FileAccess.file_exists(download_local):
		await emit_signal("download_completed", true, current_x, current_y, offset_x, offset_y)
		return

	var id = WorkerThreadPool.add_task(_run_request)

func _run_request():
	await http_request.request(download_http)
	
# parameters are required regardles of usage
# gdlint:ignore = unused-argument
func _on_request_completed(result, response_code, headers, body):
	if WorkerThreadPool.get_instance_id() != AppState.worker_thread_id:
		WorkerThreadPool.wait_for_task_completion(AppState.worker_thread_id)
	if response_code == 200:
		await emit_signal("download_completed", true, current_x, current_y, offset_x, offset_y)
	else:
		await emit_signal("download_completed", false, current_x, current_y, offset_x, offset_y)
	#remove_child(http_request)




