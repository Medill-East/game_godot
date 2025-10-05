extends Node2D

func _ready():
	var label = Label.new()
	label.text = "Hello World"
	label.position = Vector2(100, 100)
	add_child(label)
