extends Control

@onready var line_container = $LineContainer
var lines = []

func _ready():
	await get_tree().process_frame
	var center = Vector2(get_viewport_rect().end.x / 2, get_viewport_rect().end.y / 2)
	var bottom_center = Vector2(get_viewport_rect().end.x / 2, get_viewport_rect().end.y)
	var bottom_right = Vector2(get_viewport_rect().end.x / 3 * 2, get_viewport_rect().end.y)
	
	#var file = FileAccess.open("user://rules.txt", FileAccess.READ)
	#var content = file.get_as_text()
	#lines = generate(bottom_center, 5, 0.6, Color(0.9, 0.6, 1.0, 0.7), 2.0, FractalTree.new())
	#lines = generate(center, 15, 0.8, 1, Color(0.5, 1, 1, 1.0), 1, DragonCurve.new())
	#lines = generate(center, 2, 0.3, 1, Color.GREEN, 1, GosperCurve.new())
	#lines = generate(bottom_right, 6, 0.7, Color.RED, 2.0, SierpinskiTriangle.new())
	#lines = generate(bottom_center, 5, 0.57, 0.98, Color(0.2, 0.7, 1.0), 10.0, FractalPlant.new())
	#lines = generate(bottom_center, 5, 0.5, Color(0.5, 1, 1, 1.0), 5, CochCurve.new())
	lines = generate(bottom_center, 14, 1, 0.8, Color.SADDLE_BROWN, Color.GREEN, 15.0, RandomTree.new())


func _process(delta):
	if lines.is_empty():
		return
	var lines_per_frame = 100
	for index in lines_per_frame:
		var line: Line2D = lines.pop_front()
		line_container.add_child(line)
		
		if lines.is_empty():
			break


func generate(start_position, iterations, length_reduction, width_reduction, start_color, end_color, initial_width, rule):
	var length = -200
	var arrangement = rule.axiom
	var width = initial_width
	var color = start_color
	var color_add = (end_color-start_color)/iterations/3
	
	for i in iterations:
		length *= length_reduction
		var new_arrangement = ""
		for character in arrangement:
			new_arrangement += rule.get_character(character)
		arrangement = new_arrangement
	
	var lines = []
	var from = start_position
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
				lines.push_back(line)
				line.begin_cap_mode = Line2D.LINE_CAP_ROUND
				line.end_cap_mode = Line2D.LINE_CAP_ROUND
				from = to
				width = width * width_reduction
				color = color + color_add
				length = length / 1.2
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
	
	return lines


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
		self.axiom = "XF"
		self.angle = 60
		self.start_angle = 0
		self.rules = {
			"X" : "X+YF++YF−FX−−FXFX−YF+",
			"Y" : "−FX+YFYF++YF+FX−−FX−Y",
		}
		self.actions = {
			"F" : "draw_forward",
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
