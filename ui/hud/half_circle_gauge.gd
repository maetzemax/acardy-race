@tool
class_name HalfCircleGauge
extends Control

var _min_value: float = 0.0
var _max_value: float = 350.0
var _value: float = 0.0
var _invert_progress: bool = false
var _fill_clockwise: bool = false
var _fill_gradient: Gradient = Gradient.new()
const GRADIENT_SEGMENTS: int = 64

@export var min_value: float = 0.0:
	set(value):
		_min_value = value
		_value = clamp(_value, _min_value, _max_value)
		queue_redraw()
	get:
		return _min_value

@export var max_value: float = 350.0:
	set(value):
		_max_value = max(value, _min_value + 0.01)
		_value = clamp(_value, _min_value, _max_value)
		queue_redraw()
	get:
		return _max_value

@export var value: float = 0.0:
	set(val):
		_value = clamp(val, _min_value, _max_value)
		queue_redraw()
	get:
		return _value

@export var invert_progress: bool = false:
	set(val):
		_invert_progress = val
		queue_redraw()
	get:
		return _invert_progress

@export var fill_clockwise: bool = false:
	set(val):
		_fill_clockwise = val
		queue_redraw()
	get:
		return _fill_clockwise

@export var fill_gradient: Gradient:
	set(val):
		_fill_gradient = val if val != null else Gradient.new()
		queue_redraw()
	get:
		return _fill_gradient
@export var stroke_width: float = 18.0
@export var background_color: Color = Color(0.12, 0.12, 0.12, 0.8)
@export var fill_color: Color = Color(0.25, 0.85, 1.0, 0.9)
@export var tick_color: Color = Color(1.0, 1.0, 1.0, 0.25)
@export var tick_count: int = 7

func _ready():
	custom_minimum_size = Vector2(260, 140)


func _draw():
	var arc_radius = min(size.x * 0.5, size.y - stroke_width)
	if arc_radius <= 0:
		return
	var center = Vector2(size.x * 0.5, size.y)
	var base_start = PI
	var base_end = TAU
	var start_angle = base_end if _fill_clockwise else base_start
	var end_angle = base_start if _fill_clockwise else base_end
	var points = 96
	# background arc
	draw_arc(center, arc_radius, start_angle, end_angle, points, background_color, stroke_width)
	_draw_ticks(center, arc_radius, start_angle, end_angle)
	# fill arc
	var ratio = 0.0
	if max_value - min_value > 0.0:
		ratio = (value - min_value) / (max_value - min_value)
	if _invert_progress:
		ratio = 1.0 - ratio
	var current_angle = lerp(start_angle, end_angle, ratio)
	if _fill_gradient and _fill_gradient.get_point_count() > 0:
		_draw_gradient_fill(center, arc_radius, start_angle, end_angle, ratio)
	else:
		draw_arc(center, arc_radius, start_angle, current_angle, points, fill_color, stroke_width)



func _draw_ticks(center: Vector2, radius: float, start_angle: float, end_angle: float) -> void:
	if tick_count <= 0:
		return
	for i in range(tick_count + 1):
		var t = float(i) / tick_count
		var angle = lerp(start_angle, end_angle, t)
		var outer = center + Vector2(cos(angle), sin(angle)) * (radius + stroke_width * 0.5)
		var inner = center + Vector2(cos(angle), sin(angle)) * (radius - stroke_width * 0.5)
		draw_line(inner, outer, tick_color, 2.0)


func _draw_gradient_fill(center: Vector2, radius: float, start_angle: float, end_angle: float, ratio: float) -> void:
	if ratio <= 0.0:
		return
	
	# Draw with many small segments for smooth gradient appearance
	var num_segments = max(1, int(ceil(128 * ratio)))
	
	for i in range(num_segments):
		var t0 = (float(i) / num_segments) * ratio
		var t1 = (float(i + 1) / num_segments) * ratio
		var angle0 = lerp(start_angle, end_angle, t0)
		var angle1 = lerp(start_angle, end_angle, t1)
		
		# Sample gradient at current position
		var gradient_sample = (t0 + t1) * 0.5
		var color = _fill_gradient.sample(gradient_sample)
		
		# Draw with more points per segment for smoothness
		draw_arc(center, radius, angle0, angle1, 8, color, stroke_width, true)
