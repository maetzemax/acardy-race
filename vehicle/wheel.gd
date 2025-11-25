extends VehicleWheel3D

# Friction-Werte für verschiedene Untergründe
var friction_values = {
	"track": 2.5,
	"grass": 0.9,
}

func _physics_process(_delta: float):
	_handle_friction()
	

func _handle_friction():
	var surface_type = _detect_surface()
	var friction = friction_values.get(surface_type)
	wheel_friction_slip = friction


func _detect_surface() -> String:
	var space_state = get_world_3d().direct_space_state
	var ray_origin = global_position
	var ray_end = ray_origin + Vector3.DOWN * 1.0
	
	var query = PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
	var result = space_state.intersect_ray(query)
	
	if result:
		var collider = result.get("collider")
		if collider:
			# Prüfe Gruppen
			if collider.is_in_group("grass"):
				return "grass"
			elif collider.is_in_group("track"):
				return "track"
	
	return "track"  # Default
