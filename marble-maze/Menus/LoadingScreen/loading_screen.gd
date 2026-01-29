extends Control

var _progress_bar: ProgressBar

func _ready() -> void:
	_progress_bar = $ProgressBar

func _process(_delta: float) -> void:
	_progress_bar.value = SceneManager.get_progress()*100
