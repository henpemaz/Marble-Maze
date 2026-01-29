extends Node
class_name SettingsManager

var _configFile : ConfigFile = ConfigFile.new()
const _CONFIG_PATH = "user://settings.ini"

static var _settings : Array[Setting]

class Setting:
	extends Resource
	var category: String
	var key: String
	var value: Variant:
		set(value_):
			value = value_
			if on_change.is_valid():
				on_change.call(value_)
	var default: Variant
	var on_change: Callable
	
	func _init(category_: String, key_: String, default_: Variant, on_change_: Callable = Callable()):
		self.category = category_
		self.key = key_
		self.default = default_
		self.value = default_
		self.on_change = on_change_
		SettingsManager._settings.append(self)

#region video
# Its hilarious how each of these video settings points to a different thing in godot???
var window_mode := Setting.new("video", "window_mode", Window.Mode.MODE_FULLSCREEN,
	func(value):
		get_window().mode = value
)

var render_scale := Setting.new("video", "render_scale", 100.0,
	func(value):
		get_viewport().scaling_3d_scale = value/100.0
)

var vsync := Setting.new("video", "vsync", DisplayServer.VSyncMode.VSYNC_ADAPTIVE,
	func(value):
		DisplayServer.window_set_vsync_mode(value)
)

var fps_limit := Setting.new("video", "fps_limit", 60,
	func(value):
		Engine.max_fps = value
)
#endregion
#region audio
var master_volume := Setting.new("audio", "master_volume", 100.0,
	func(value):
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), linear_to_db(value/100.0))
)

var music_volume := Setting.new("audio", "music_volume", 100.0,
	func(value):
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), linear_to_db(value/100.0))
)

var sfx_volume := Setting.new("audio", "sfx_volume", 100.0,
	func(value):
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Sfx"), linear_to_db(value/100.0))
)
#endregion


func _ready() -> void:
	read_config()

func read_config():
	print("read_config")
	_configFile.clear()
	
	for setting in _settings:
		_configFile.set_value(setting.category, setting.key, setting.default)
	
	if FileAccess.file_exists(_CONFIG_PATH):
		_configFile.load(_CONFIG_PATH)
	else:
		_configFile.save(_CONFIG_PATH)
	
	for setting in _settings:
		setting.value = _configFile.get_value(setting.category, setting.key, setting.default)

func save_config():
	print("save_config")
	for setting in _settings:
		_configFile.set_value(setting.category, setting.key, setting.value)
	
	_configFile.save(_CONFIG_PATH)

func reset_config():
	print("reset_config")
	for setting in _settings:
		setting.value = setting.default
	
	save_config()

func any_changed()->bool:
	for setting in _settings:
		if setting.value != _configFile.get_value(setting.category, setting.key, setting.default):
			return true
	return false

func any_nondefault()->bool:
	for setting in _settings:
		if setting.value != setting.default:
			return true
	return false
