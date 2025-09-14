extends Area2D

func _on_body_entered(_body: Node2D) -> void:
	print("Got a coin!")
	queue_free()
