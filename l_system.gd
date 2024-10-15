extends Control

@onready var line_container = $LineContainer
var lines = []

func _ready():
	#var file = FileAccess.open("user://rules.txt", FileAccess.READ)
	#var content = file.get_as_text()
	
	#lines = generate(14, 1, 1, 1, Color(0.5, 1, 1, 1.0), Color(0.5, 1, 1, 1.0), DragonCurve.new())
	#lines = generate(6, 1, 1, 1, Color.GREEN, Color.GREEN, GosperCurve.new())
	#lines = generate(9, 1, 1, 3.0, Color.RED, Color.DARK_BLUE, SierpinskiTriangle.new())
	#lines = generate(8, 1, 0.99, 10.0, Color(0.2, 0.7, 1.0), Color(0.2, 0.7, 1.0), FractalPlant.new())
	#lines = generate(6, 1, 1, 5, Color(0.5, 1, 1, 1.0), Color(0.5, 1, 1, 1.0), CochCurve.new())
	lines = generate(12, 0.9, 0.7, 15.0, Color.SADDLE_BROWN, Color.LAWN_GREEN, RandomTree.new())


func _process(delta):
	if lines.is_empty():
		return
	var lines_per_frame = 10
	for index in lines_per_frame:
		var line: Line2D = lines.pop_front()
		line_container.add_child(line)
		
		if lines.is_empty():
			break


func generate(iterations, length_reduction, width_reduction, initial_width, start_color, end_color, rule):
	var length = -1
	var arrangement = rule.axiom
	var width = initial_width
	var color = start_color
	var color_add = (end_color-start_color)/iterations
	
	for i in iterations:
		var new_arrangement = ""
		for character in arrangement:
			new_arrangement += rule.get_character(character)
		arrangement = new_arrangement
	
	var from = Vector2.ZERO
	var rot = rule.start_angle
	var cache_queue = []
	for index in arrangement:
		match rule.get_action(index):
			"draw_forward":
				var to = from + Vector2(0, length).rotated(deg_to_rad(rot))
				var line = Line2D.new()
				line.default_color = color
				line.antialiased = true
				line.width = width
				line.add_point(from)
				line.add_point(to)
				line.begin_cap_mode = Line2D.LINE_CAP_ROUND
				line.end_cap_mode = Line2D.LINE_CAP_ROUND
				lines.push_back(line)
				from = to
				width = max(1, width * width_reduction)
				color = color + color_add
				length = length * length_reduction
			"rotate_right":
				rot += rule.angle
			"rotate_left":
				rot -= rule.angle
			"rotate_right_random":
				rot += randi_range(1, rule.angle)
			"rotate_left_random":
				rot -= randi_range(1, rule.angle)
			"store":
				cache_queue.push_back([from, rot, width, color, length])
			"load":
				var cached_data = cache_queue.pop_back()
				from = cached_data[0]
				rot = cached_data[1]
				width = cached_data[2]
				color = cached_data[3]
				length = cached_data[4]
	
	var scale_and_offset = calculate_scale_factor()
	scale_lines(scale_and_offset)
	return lines


func calculate_scale_factor():
	var min_point = Vector2.INF
	var max_point = -Vector2.INF
	
	for line in lines:
		min_point = min_point.min(line.points[0]).min(line.points[1])
		max_point = max_point.max(line.points[0]).max(line.points[1])
	
	var content_size = max_point - min_point
	
	var window_size = get_viewport_rect().size
	
	var scale_x = window_size.x / content_size.x
	var scale_y = window_size.y / content_size.y
	
	var scale_factor = min(scale_x, scale_y)
	
	var offset
	if scale_factor == scale_x:
		offset = -min_point*scale_factor + Vector2(0, window_size.y/2 - (max_point.y-min_point.y)/2 * scale_factor)
	else:
		offset = -min_point*scale_factor + Vector2(window_size.x/2 - (max_point.x-min_point.x)/2 * scale_factor, 0)
	
	return [scale_factor, offset]


func scale_lines(scale_and_offset):
	for i in range(lines.size()):
		lines[i].points[0] = lines[i].points[0] * scale_and_offset[0] + scale_and_offset[1]
		lines[i].points[1] = lines[i].points[1] * scale_and_offset[0] + scale_and_offset[1]


class Rule:
	var axiom
	var rules = {}
	var actions = {}
	var angle
	var start_angle = 0
	
	func get_character(character):
		if rules.has(character):
			return rules.get(character)
		return character
	
	func get_action(character):
		return actions.get(character)


class DragonCurve extends Rule:
	func _init():
		self.axiom = "FX"
		self.angle = 90
		self.rules = {
			"X" : "X+YF+",
			"Y" : "-FX-Y"
		}
		self.actions = {
			"F" : "draw_forward",
			"+" : "rotate_right",
			"-" : "rotate_left"
		}


class CochCurve extends Rule:
	func _init():
		self.axiom = "F"
		self.angle = 60
		self.start_angle = 90
		self.rules = {
			"F" : "F-F++F-F",
		}
		self.actions = {
			"F" : "draw_forward",
			"+" : "rotate_right",
			"-" : "rotate_left"
		}


class SierpinskiTriangle extends Rule:
	func _init():
		self.axiom = "F-G-G"
		self.angle = 120
		self.rules = {
			"F" : "F-G+F+G-F",
			"G" : "GG"
		}
		self.actions = {
			"F" : "draw_forward",
			"G" : "draw_forward",
			"+" : "rotate_right",
			"-" : "rotate_left"
		}


class FractalPlant extends Rule:
	func _init():
		self.axiom = "X"
		self.angle = 25
		self.rules = {
			"X" : "F+[[X]-X]-F[-FX]+X",
			"F" : "FF"
		}
		self.actions = {
			"F" : "draw_forward",
			"+" : "rotate_right",
			"-" : "rotate_left",
			"[" : "store",
			"]" : "load"
		}


class GosperCurve extends Rule:
	func _init():
		self.axiom = "A"
		self.angle = 60
		self.start_angle = 0
		self.rules = {
			"A" : "A-B--B+A++AA+B-",
			"B" : "+A-BB--B-A++A+B",
		}
		self.actions = {
			"A" : "draw_forward",
			"B" : "draw_forward",
			"+" : "rotate_right",
			"-" : "rotate_left",
		}



class RandomTree extends Rule:
	func _init():
		self.axiom = "X"
		self.angle = 45
		self.start_angle = 0
		self.rules = {
			"X" : "F[[-X]+X]",
		}
		self.actions = {
			"F" : "draw_forward",
			"+" : "rotate_right_random",
			"-" : "rotate_left_random",
			"[" : "store",
			"]" : "load"
		}
