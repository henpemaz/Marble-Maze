extends Control

@onready var window_mode: OptionButton = $TabContainer/Graphics/MarginContainer/ScrollContainer/VBoxContainer/MarginContainer/WindowMode
@onready var render_scale: HSlider = $TabContainer/Graphics/MarginContainer/ScrollContainer/VBoxContainer/MarginContainer2/RenderScale
@onready var v_sync: OptionButton = $TabContainer/Graphics/MarginContainer/ScrollContainer/VBoxContainer/MarginContainer3/VSync
@onready var fps_limit: HSlider = $TabContainer/Graphics/MarginContainer/ScrollContainer/VBoxContainer/MarginContainer4/FPSLimit
@onready var master_volume: HSlider = $TabContainer/Audio/MarginContainer/ScrollContainer/VBoxContainer/MarginContainer2/MasterVolume
@onready var music_volume: HSlider = $TabContainer/Audio/MarginContainer/ScrollContainer/VBoxContainer/MarginContainer3/MusicVolume
@onready var sfx_volume: HSlider = $TabContainer/Audio/MarginContainer/ScrollContainer/VBoxContainer/MarginContainer4/SfxVolume

func _ready() -> void:
	show_config()
	
func show_config():
	window_mode.select(window_mode.get_item_index(Settings.window_mode.value))
	render_scale.set_value_no_signal(Settings.render_scale.value)
	v_sync.select(v_sync.get_item_index(Settings.vsync.value))
	fps_limit.set_value_no_signal(Settings.fps_limit.value)
	master_volume.set_value_no_signal(Settings.master_volume.value)
	music_volume.set_value_no_signal(Settings.music_volume.value)
	sfx_volume.set_value_no_signal(Settings.sfx_volume.value)

func _process(_delta: float) -> void:
	$BottomRow/HBoxContainer/Save.disabled = !Settings.any_changed()
	$BottomRow/HBoxContainer/RestoreDefaults.disabled = !Settings.any_nondefault()

func _on_save_pressed() -> void:
	Settings.save_config()
	show_config()

func _on_restore_defaults_pressed() -> void:
	Settings.reset_config()
	show_config()

func menu_inactive() -> void:
	Settings.read_config()
	show_config()


func _on_window_mode_item_selected(index: int) -> void:
	Settings.window_mode.value = window_mode.get_item_id(index) as Window.Mode


func _on_render_scale_value_changed(value: float) -> void:
	Settings.render_scale.value = value


func _on_v_sync_item_selected(index: int) -> void:
	Settings.vsync.value = v_sync.get_item_id(index) as DisplayServer.VSyncMode


func _on_fps_limit_value_changed(value: float) -> void:
	Settings.fps_limit.value = value


func _on_master_volume_value_changed(value: float) -> void:
	Settings.master_volume.value = value


func _on_music_volume_value_changed(value: float) -> void:
	Settings.music_volume.value = value


func _on_sfx_volume_value_changed(value: float) -> void:
	Settings.sfx_volume.value = value
