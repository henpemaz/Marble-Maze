extends Resource
class_name MenuTransition

@export var do_fadeout: bool = false
@export var fadeout: float = 0.06
@export var do_fadein: bool = false
@export var fadein: float = 0.12
@export var animation: String = ""
@export var animation_speed: float = 1


func backwards()->MenuTransition:
	var _new = MenuTransition.new()
	_new.do_fadeout = do_fadein
	_new.fadeout = fadein
	_new.do_fadein = do_fadeout
	_new.fadein = fadeout
	_new.animation = animation
	_new.animation_speed = -animation_speed
	return _new
