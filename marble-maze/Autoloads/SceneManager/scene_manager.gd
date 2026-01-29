extends CanvasLayer

#@export_file("*.tscn") var main_menu: String
@export var _loading_screen: PackedScene

@onready var _fade_rect: ColorRect = $FadeRect
@export var _default_fade_out_time = .2
@export var _loading_fade_in_time = .2
@export var _loading_fade_out_time = .1
@export var _default_fade_in_time = .2
@export var _boot_fade_in_time = .5

enum LoadingStage {
	NONE,
	FADEOUT_ACTIVE,
	FADEIN_LOADING,
	LOADING_SCREEN,
	FADEOUT_LOADING,
	WAIT_LOADING,
	FADEIN_NEW
}

var upcoming_scene: String
var loading_stage: LoadingStage
var _progress: float
var _fade: float
var _fade_speed: float
var _use_loading_screen: bool

func _ready() -> void:
	_fade = 1;
	_set_fade_speed(_boot_fade_in_time)
	loading_stage = LoadingStage.FADEIN_NEW
	
	print("stage_manager started")

func _process(delta: float) -> void:
	# statemachine update current step
	match loading_stage:
		LoadingStage.FADEOUT_ACTIVE:
			_fade_out(delta)
			pass
		LoadingStage.FADEIN_LOADING:
			_fade_in(delta)
			_update_progress(delta)
			pass
		LoadingStage.LOADING_SCREEN:
			_update_progress(delta)
			pass
		LoadingStage.FADEOUT_LOADING:
			_fade_out(delta)
			_update_progress(delta)
			pass
		LoadingStage.WAIT_LOADING:
			_update_progress(delta)
			pass
		LoadingStage.FADEIN_NEW:
			_fade_in(delta)
			pass

func _step_completed() -> void:
	#print("stage_manager step complete: " + str(loading_stage))
	# statemachine next-step
	match loading_stage:
		LoadingStage.FADEOUT_ACTIVE:
			get_tree().unload_current_scene()
			if _use_loading_screen:
				loading_stage = LoadingStage.FADEIN_LOADING
				_set_fade_speed(_loading_fade_in_time)
				_loadLoadingScreen()
			else:
				loading_stage = LoadingStage.WAIT_LOADING
		LoadingStage.FADEIN_LOADING:
			loading_stage = LoadingStage.LOADING_SCREEN
		LoadingStage.LOADING_SCREEN:
			loading_stage = LoadingStage.FADEOUT_LOADING
			_set_fade_speed(_loading_fade_out_time)
		LoadingStage.FADEOUT_LOADING:
			loading_stage = LoadingStage.FADEIN_NEW
			_set_fade_speed(_default_fade_in_time)
			_loadNextScene()
		LoadingStage.WAIT_LOADING:
			loading_stage = LoadingStage.FADEIN_NEW
			_set_fade_speed(_default_fade_in_time)
			_loadNextScene()
		LoadingStage.FADEIN_NEW:
			loading_stage = LoadingStage.NONE

func _update_progress(delta:float) -> void:
	
	_time_elapsed += delta
	
	var progress = []
	var status = ResourceLoader.load_threaded_get_status(upcoming_scene, progress)
	_progress = min(progress[0], _time_elapsed/_fake_loading_time)
	if (_time_elapsed > _fake_loading_time) && (status == ResourceLoader.ThreadLoadStatus.THREAD_LOAD_LOADED):
		if(_use_loading_screen): # skip straight into FADEOUT_LOADING
			while(loading_stage < LoadingStage.FADEOUT_LOADING):
				_step_completed()
		else:
			_step_completed() # from WAIT_LOADING to FADEIN_NEW

# If you thought of unifying these two into one method, you have code-autism
func _fade_out(delta : float) -> void:
	_fade = min(1.0, _fade + _fade_speed * delta)
	_updateFadeRect()
	if _fade == 1.0:
		_step_completed()
		
func _fade_in(delta : float) -> void:
	_fade = max(0.0, _fade - _fade_speed * delta)
	_updateFadeRect()
	if _fade == 0.0:
		_step_completed()
		
func _updateFadeRect():
	_fade_rect.color.a = _fade
	_fade_rect.visible = _fade != 0.0

func _loadLoadingScreen()-> void:
	get_tree().change_scene_to_packed(_loading_screen)

func _loadNextScene() -> void:
	var new_scene = ResourceLoader.load_threaded_get(upcoming_scene)
	upcoming_scene = ""
	get_tree().change_scene_to_packed(new_scene)

func _set_fade_speed(fromTime: float) -> void:
	_fade_speed = 1.0/max(fromTime, 0.001)

# API
## Start a fade transition to another scene
func request_scene_switch(new_scene: String, fade_out_time: float = -1, use_loading_screen: bool = true) -> Error:
	if new_scene.is_empty():
		push_error("new scene is empty!")
		return Error.FAILED
	new_scene = ResourceUID.ensure_path(new_scene)
	print("stage_manager new scene requested: " + new_scene)
	if upcoming_scene != "":
		print("stage_manager already has upcoming scene: " + upcoming_scene)
		return Error.FAILED
	if fade_out_time == -1:
		fade_out_time = _default_fade_out_time
	var err = ResourceLoader.load_threaded_request(new_scene)
	if err != Error.OK:
		print("stage_manager failed request with: " + error_string(err))
		return err
	upcoming_scene = new_scene
	loading_stage = LoadingStage.FADEOUT_ACTIVE
	_set_fade_speed(fade_out_time)
	_use_loading_screen = use_loading_screen
	
	if get_tree().current_scene.has_method("on_shutdown"):
		get_tree().current_scene.on_shutdown()
	
	#print("stage_manager successfully requested")
	return Error.OK

func set_fade_time(time: float) -> void:
	_set_fade_speed(time)
	
var _fake_loading_time:float
var _time_elapsed:float
func set_fake_loading_time(in_seconds:float):
	_fake_loading_time = in_seconds
	_time_elapsed = 0

func get_progress()->float:
	return _progress
