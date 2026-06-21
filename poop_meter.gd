extends Control

@onready var strip_material: ShaderMaterial = $Guage.material

func set_value(v: float) -> void:
    # v expected in 0.0–1.0; clamp defensively

    strip_material.set_shader_parameter("value", lerp(0.71, 0.172, clampf(v, 0.0, 1.0)))
