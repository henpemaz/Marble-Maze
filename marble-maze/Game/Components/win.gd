extends Area3D

@export var primed:bool = true
@export var monitor_body:PhysicsBody3D
@export var game:Node
@export var prime_area:Area3D
@export var unprime_area:Area3D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if prime_area:
		prime_area.body_entered.connect(_on_primearea_body_entered)
	if unprime_area:
		unprime_area.body_entered.connect(_on_unprimearea_body_entered)


func _on_body_entered(body: Node3D) -> void:
	if monitor_body == body:
		if primed:
			game.win()

func _on_primearea_body_entered(body: Node3D) -> void:
	if monitor_body == body:
		primed = true

func _on_unprimearea_body_entered(body: Node3D) -> void:
	if monitor_body == body:
		primed = false
