extends VehicleWheel3D

@export var is_back_wheel: bool

var is_off_track = false

# Friction-Werte für verschiedene Untergründe
var friction_values = {
	"track": 2.5,
	"grass": 0.9,
}

func _physics_process(_delta: float):
	_handle_friction()


func _handle_friction():
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
				var friction = friction_values.get("grass")
				wheel_friction_slip = friction * 0.75 if is_back_wheel else friction
				is_off_track = true
			elif collider.is_in_group("track"):
				var friction = friction_values.get("track")
				wheel_friction_slip = friction
				is_off_track = false
			else:
				var friction = friction_values.get("track")
				wheel_friction_slip = friction
				is_off_track = false
