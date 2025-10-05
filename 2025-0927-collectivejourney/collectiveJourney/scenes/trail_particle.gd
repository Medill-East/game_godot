extends MeshInstance3D

@export var fade_duration: float = 1.0

var _elapsed: float = 0.0
var _base_color: Color

func _ready():
	var mat: Material = material_override
	if mat is StandardMaterial3D:
		var s: StandardMaterial3D = mat as StandardMaterial3D
		_base_color = s.albedo_color
	else:
		_base_color = Color(1, 1, 1, 1)

func _process(delta: float) -> void:
	_elapsed += delta
	var t: float = clamp(_elapsed / fade_duration, 0.0, 1.0)
	var mat: Material = material_override
	if mat is StandardMaterial3D:
		var s: StandardMaterial3D = mat as StandardMaterial3D
		s.albedo_color = Color(_base_color.r, _base_color.g, _base_color.b, 1.0 - t)
	if t >= 1.0:
		queue_free()
