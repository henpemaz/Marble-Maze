extends AudioStreamPlayer

var tween:Tween
var current:AudioStream

const duration = 1.2

func request_music(music:AudioStream):
	if music == current:
		return
	current = music
	if tween != null && tween.is_valid():
		tween.kill()
	tween = create_tween()
	if playing:
		tween.tween_method(func(v): volume_db = linear_to_db(v), volume_linear, 0.0, duration * volume_linear)
	if current:
		tween.tween_callback(func(): stop(); stream = current; print("now playing: " + current.resource_path); volume_linear = 0.0; play())
		tween.tween_method(func(v): volume_db = linear_to_db(v), 0.0, 1.0, duration)
