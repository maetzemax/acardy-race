extends Camera3D

# Referenz zum Fahrzeug
@export var target: Node3D

# Kamera-Offset und Position
@export_group("Camera Position")
@export var default_offset: Vector3 = Vector3(0, 2.5, -5.0)
@export var smoothing_speed: float = 10.0
@export var speed_adaptive_smoothing: bool = true  # Passt Smoothing an Geschwindigkeit an
@export var max_distance: float = 8.0  # Maximaler Abstand zum Fahrzeug

# Zoom-Einstellungen
@export_group("Zoom Settings")
@export var zoom_min: float = 3.0
@export var zoom_max: float = 15.0
@export var zoom_speed: float = 1.0
var current_zoom: float = 5.0

# Maus-Drag Einstellungen
@export_group("Mouse Look")
@export var mouse_sensitivity: float = 0.3
@export var rotation_smoothing: float = 8.0
@export var max_pitch: float = 60.0  # Max nach oben/unten schauen (Grad)
@export var min_pitch: float = -20.0

# Interne Variablen
var is_dragging: bool = false
var camera_rotation_x: float = 0.0  # Pitch (hoch/runter)
var camera_rotation_y: float = 0.0  # Yaw (links/rechts)
var target_rotation_x: float = 0.0
var target_rotation_y: float = 0.0


func _ready():
	# Wenn kein Target gesetzt, versuche VehicleBody3D zu finden
	if target == null:
		target = get_parent()
	
	# Initialisiere Zoom
	current_zoom = default_offset.length()
	
	# Stelle sicher, dass Maus sichtbar ist
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _input(event):
	# Maus-Drag mit rechter Maustaste
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			is_dragging = event.pressed
			if is_dragging:
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			else:
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	# Mausbewegung während Drag
	if event is InputEventMouseMotion and is_dragging:
		target_rotation_y -= event.relative.x * mouse_sensitivity
		target_rotation_x += event.relative.y * mouse_sensitivity  # + statt - für richtige Richtung
		target_rotation_x = clamp(target_rotation_x, min_pitch, max_pitch)
	
	# Scroll-Zoom
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			current_zoom = clamp(current_zoom - zoom_speed, zoom_min, zoom_max)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			current_zoom = clamp(current_zoom + zoom_speed, zoom_min, zoom_max)


func _physics_process(delta):
	if target == null:
		return
	
	# Smooth Rotation mit Lerp
	camera_rotation_x = lerp(camera_rotation_x, target_rotation_x, delta * rotation_smoothing)
	camera_rotation_y = lerp(camera_rotation_y, target_rotation_y, delta * rotation_smoothing)
	
	# Berechne Kamera-Offset mit Zoom
	var zoom_factor = current_zoom / default_offset.length()
	var offset = default_offset * zoom_factor
	
	# Starte mit der Rotation des Fahrzeugs (folgt der Fahrzeug-Ausrichtung)
	var target_basis = target.global_transform.basis
	
	# Wende zusätzliche Maus-Rotation an
	var rotation_transform = Transform3D()
	rotation_transform = rotation_transform.rotated(Vector3.UP, deg_to_rad(camera_rotation_y))
	rotation_transform = rotation_transform.rotated(rotation_transform.basis.x, deg_to_rad(camera_rotation_x))
	
	# Kombiniere Fahrzeug-Rotation mit Maus-Rotation
	var final_offset = target_basis * (rotation_transform * offset)
	
	# Zielposition berechnen
	var target_position = target.global_position + final_offset
	
	# Begrenze den Abstand zum Fahrzeug (verhindert zu großen Abstand bei hoher Geschwindigkeit)
	var distance_to_target = (target_position - target.global_position).length()
	if distance_to_target > max_distance:
		var direction = (target_position - target.global_position).normalized()
		target_position = target.global_position + direction * max_distance
	
	# Dynamisches Smoothing basierend auf Geschwindigkeit
	var current_smoothing = smoothing_speed
	if speed_adaptive_smoothing and target is RigidBody3D:
		var speed = target.linear_velocity.length()
		# Je schneller das Fahrzeug, desto schneller folgt die Kamera
		current_smoothing = smoothing_speed * (1.0 + speed * 0.02)
	
	# Smooth Follow mit Lerp
	global_position = global_position.lerp(target_position, delta * current_smoothing)
	
	# Schaue zum Target
	look_at(target.global_position + Vector3(0, 1.0, 0), Vector3.UP)


func reset_camera():
	"""Setzt die Kamera auf Standard-Einstellungen zurück"""
	target_rotation_x = 0.0
	target_rotation_y = 0.0
	camera_rotation_x = 0.0
	camera_rotation_y = 0.0
	current_zoom = default_offset.length()
