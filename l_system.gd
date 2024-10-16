extends Control

@onready var line_container = $LineContainer
var lines = []

var iterations = 12
var initial_width = 15
var length_reduction = 0.9
var width_reduction = 0.7
var rule = RandomTree.new()
var start_color = Color.SADDLE_BROWN
var end_color = Color.LAWN_GREEN

var lines_per_frame = 10

@onready var end_color_picker: ColorPickerButton = $VBoxContainer/MarginContainer/HBoxContainer/EndColor
@onready var start_color_picker: ColorPickerButton = $VBoxContainer/MarginContainer/HBoxContainer/StartColor
@onready var initial_width_slider: HSlider = $VBoxContainer/MarginContainer/HBoxContainer/InitialWidth
@onready var length_reduction_slider: HSlider = $VBoxContainer/MarginContainer/HBoxContainer/LengthReduction
@onready var width_reduction_slider: HSlider = $VBoxContainer/MarginContainer/HBoxContainer/WidthReduction
@onready var iterations_slider: HSlider = $VBoxContainer/MarginContainer/HBoxContainer/Iterations

func _ready():
	#var file = FileAccess.open("user://rules.txt", FileAccess.READ)
	#var content = file.get_as_text()
	
	#lines = generate(14, 1, 1, 1, Color(0.5, 1, 1, 1.0), Color(0.5, 1, 1, 1.0), DragonCurve.new())
	#lines = generate(6, 1, 1, 1, Color.GREEN, Color.GREEN, GosperCurve.new())
	#lines = generate(9, 1, 1, 3.0, Color.RED, Color.DARK_BLUE, SierpinskiTriangle.new())
	#lines = generate(8, 1, 0.99, 10.0, Color(0.2, 0.7, 1.0), Color(0.2, 0.7, 1.0), FractalPlant.new())
	#lines = generate(6, 1, 1, 5, Color(0.5, 1, 1, 1.0), Color(0.5, 1, 1, 1.0), CochCurve.new())
	lines = generate()


func _process(delta):
	if lines.is_empty():
		return
	
	for index in lines_per_frame:
		var line: Line2D = lines.pop_front()
		line_container.add_child(line)
		
		if lines.is_empty():
			break


func generate():
	var length = -1
	var arrangement = rule.axiom
	var width = initial_width
	var color = start_color
	var color_add = (end_color-start_color)/iterations
	
	var uses_store = false
	
	var new_lines = []
	
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
				new_lines.push_back(line)
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
				uses_store = true
				cache_queue.push_back([from, rot, width, color, length])
			"load":
				var cached_data = cache_queue.pop_back()
				from = cached_data[0]
				rot = cached_data[1]
				width = cached_data[2]
				color = cached_data[3]
				length = cached_data[4]
	
	if not uses_store:
		color_add = (end_color-start_color)/new_lines.size()
		for index in new_lines.size():
			#print(1, new_lines[index].default_color)
			new_lines[index].default_color = start_color + color_add*index
			#print(2, new_lines[index].default_color)
	
	var scale_and_offset = calculate_scale_factor(new_lines)
	scale_lines(scale_and_offset, new_lines)
	return new_lines


func calculate_scale_factor(lines):
	var min_point = Vector2.INF
	var max_point = -Vector2.INF
	
	for line in lines:
		min_point = min_point.min(line.points[0]).min(line.points[1])
		max_point = max_point.max(line.points[0]).max(line.points[1])
	
	var content_size = max_point - min_point
	
	var window_size = get_viewport_rect().size - Vector2(0, $VBoxContainer/MarginContainer.size.y)
	
	var scale_x = window_size.x / content_size.x
	var scale_y = window_size.y / content_size.y
	
	var scale_factor = min(scale_x, scale_y)
	
	var offset
	if scale_factor == scale_x:
		offset = -min_point*scale_factor + Vector2(0, window_size.y/2 - (max_point.y-min_point.y)/2 * scale_factor + $VBoxContainer/MarginContainer.size.y)
	else:
		offset = -min_point*scale_factor + Vector2(window_size.x/2 - (max_point.x-min_point.x)/2 * scale_factor, $VBoxContainer/MarginContainer.size.y)
	
	return [scale_factor, offset]


func scale_lines(scale_and_offset, lines):
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

class CochIsland extends Rule:
	func _init():
		self.axiom = "F+F+F+F"
		self.angle = 90
		self.start_angle = 0
		self.rules = {
			"F" : "F+F−F−FF+F+F−F",
		}
		self.actions = {
			"F" : "draw_forward",
			"+" : "rotate_right",
			"-" : "rotate_left",
		}

class HilbertCurve extends Rule:
	func _init():
		self.axiom = "A"
		self.angle = 90
		self.start_angle = 0
		self.rules = {
			"A" : "-BF+AFA+FB-",
			"B" : "+AF-BFB-FA+"
		}
		self.actions = {
			"F" : "draw_forward",
			"+" : "rotate_right",
			"-" : "rotate_left",
		}


class Kust1 extends Rule:
	func _init():
		self.axiom = "F"
		self.angle = 22
		self.start_angle = 0
		self.rules = {
			"F" : "FF−[−F+F+F]+[+F−F−F]",
		}
		self.actions = {
			"F" : "draw_forward",
			"+" : "rotate_right",
			"-" : "rotate_left",
			"[" : "store",
			"]" : "load"
		}

class SomePlant1 extends Rule:
	func _init():
		self.axiom = "F"
		self.angle = 35
		self.start_angle = 0
		self.rules = {
			"F" : "F[+FF][-FF]F[-F][+F]F",
		}
		self.actions = {
			"F" : "draw_forward",
			"+" : "rotate_right",
			"-" : "rotate_left",
			"[" : "store",
			"]" : "load"
		}


class HexaMosaic extends Rule:
	func _init():
		self.axiom = "X"
		self.angle = 60
		self.start_angle = 0
		self.rules = {
			"X" : "[−F+F[Y]+F][+F−F[X]−F]",
			"Y" : "[−F+F[Y]+F][+F−F−F]"
		}
		self.actions = {
			"F" : "draw_forward",
			"+" : "rotate_right",
			"-" : "rotate_left",
			"[" : "store",
			"]" : "load"
		}

class Crystal extends Rule:
	func _init():
		self.axiom = "F+F+F+F"
		self.angle = 90
		self.start_angle = 0
		self.rules = {
			"F" : "FF+F++F+F",
		}
		self.actions = {
			"F" : "draw_forward",
			"+" : "rotate_right",
			"-" : "rotate_left",
		}


func _on_menu_pressed() -> void:
	get_tree().change_scene_to_file("res://menu.tscn")


func _on_generate_pressed() -> void:
	_on_clear_pressed()
	lines = generate()


func _on_clear_pressed() -> void:
	lines.clear()
	
	var children = line_container.get_children()
	for child in children:
		child.free()


func _on_option_button_item_selected(index: int) -> void:
	match index:
		0:
			rule = RandomTree.new()
			
			iterations = 12
			initial_width = 15
			length_reduction = 0.9
			width_reduction = 0.7
			rule = RandomTree.new()
			start_color = Color.SADDLE_BROWN
			end_color = Color.LAWN_GREEN
			
			iterations_slider.value = 12
			initial_width_slider.value = 15
			length_reduction_slider.value = 0.9
			width_reduction_slider.value = 0.7
			start_color_picker.color = Color.SADDLE_BROWN
			end_color_picker.color = Color.LAWN_GREEN
		1:
			rule = FractalPlant.new()
			
			iterations = 6
			initial_width = 2
			length_reduction = 0.99
			width_reduction = 1
			start_color = Color(0.2, 0.7, 1.0)
			end_color = Color(0.2, 0.7, 1.0)
			
			iterations_slider.value = 6
			initial_width_slider.value = 2
			length_reduction_slider.value = 0.99
			width_reduction_slider.value = 1
			start_color_picker.color = Color(0.2, 0.7, 1.0)
			end_color_picker.color = Color(0.2, 0.7, 1.0)
		2:
			rule = GosperCurve.new()
			
			iterations = 4
			initial_width = 1
			length_reduction = 1
			width_reduction = 1
			start_color = Color.GREEN
			end_color = Color.GREEN
			
			iterations_slider.value = 4
			initial_width_slider.value = 1
			length_reduction_slider.value = 1
			width_reduction_slider.value = 1
			start_color_picker.color = Color.GREEN
			end_color_picker.color = Color.GREEN
		3:
			rule = DragonCurve.new()
			
			iterations = 13
			initial_width = 1
			length_reduction = 1
			width_reduction = 1
			start_color = Color(0.5, 1, 1, 1.0)
			end_color = Color(0.5, 1, 1, 1.0)
			
			iterations_slider.value = 13
			initial_width_slider.value = 1
			length_reduction_slider.value = 1
			width_reduction_slider.value = 1
			start_color_picker.color = Color(0.5, 1, 1, 1.0)
			end_color_picker.color = Color(0.5, 1, 1, 1.0)
		4:
			rule = CochCurve.new()
			
			iterations = 6
			initial_width = 1
			length_reduction = 1
			width_reduction = 1
			start_color = Color(0.5, 1, 1, 1.0)
			end_color = Color(0.5, 1, 1, 1.0)
			
			iterations_slider.value = 6
			initial_width_slider.value = 1
			length_reduction_slider.value = 1
			width_reduction_slider.value = 1
			start_color_picker.color = Color(0.5, 1, 1, 1.0)
			end_color_picker.color = Color(0.5, 1, 1, 1.0)
		5:
			rule = SierpinskiTriangle.new()

			iterations = 9
			initial_width = 1
			length_reduction = 1
			width_reduction = 1
			start_color = Color.RED
			end_color = Color.DARK_BLUE
			
			iterations_slider.value = 9
			initial_width_slider.value = 1
			length_reduction_slider.value = 1
			width_reduction_slider.value = 1
			start_color_picker.color = Color.RED
			end_color_picker.color = Color.DARK_BLUE
		6:
			rule = CochIsland.new()
			iterations = 4
			initial_width = 1
			length_reduction = 1
			width_reduction = 1
			
			iterations_slider.value = 4
			initial_width_slider.value = 1
			length_reduction_slider.value = 1
			width_reduction_slider.value = 1
		7:
			rule = Kust1.new()
			iterations = 5
			initial_width = 1
			length_reduction = 1
			width_reduction = 1
			
			iterations_slider.value = 5
			initial_width_slider.value = 1
			length_reduction_slider.value = 1
			width_reduction_slider.value = 1
		8: 
			rule = HexaMosaic.new()
			iterations = 5
			initial_width = 1
			length_reduction = 1
			width_reduction = 1
			
			iterations_slider.value = 5
			initial_width_slider.value = 1
			length_reduction_slider.value = 1
			width_reduction_slider.value = 1
		9:
			rule = HilbertCurve.new()
			iterations = 5
			initial_width = 1
			length_reduction = 1
			width_reduction = 1
			
			iterations_slider.value = 5
			initial_width_slider.value = 1
			length_reduction_slider.value = 1
			width_reduction_slider.value = 1
		10:
			rule = SomePlant1.new()
			iterations = 5
			initial_width = 1
			length_reduction = 1
			width_reduction = 1
			
			iterations_slider.value = 5
			initial_width_slider.value = 1
			length_reduction_slider.value = 1
			width_reduction_slider.value = 1
		11:
			rule = Crystal.new()
			iterations = 5
			initial_width = 1
			length_reduction = 1
			width_reduction = 1
			
			iterations_slider.value = 5
			initial_width_slider.value = 1
			length_reduction_slider.value = 1
			width_reduction_slider.value = 1


@onready var label_2_1: Label = $VBoxContainer/MarginContainer/HBoxContainer/InitialWidth/Label2
func _on_initial_width_value_changed(value: float) -> void:
	label_2_1.text = str(value)
	initial_width = value

@onready var label_2_2: Label = $VBoxContainer/MarginContainer/HBoxContainer/LengthReduction/Label2
func _on_length_reduction_value_changed(value: float) -> void:
	label_2_2.text = str(value)
	length_reduction = value

@onready var label_2_3: Label = $VBoxContainer/MarginContainer/HBoxContainer/WidthReduction/Label2
func _on_width_reduction_value_changed(value: float) -> void:
	label_2_3.text = str(value)
	width_reduction = value

@onready var label_2_4: Label = $VBoxContainer/MarginContainer/HBoxContainer/Iterations/Label2
func _on_iterations_value_changed(value: float) -> void:
	label_2_4.text = str(value)
	iterations = int(value)


func _on_end_color_popup_closed() -> void:
	end_color = end_color_picker.color


func _on_start_color_popup_closed() -> void:
	start_color = start_color_picker.color

@onready var label_2_5: Label = $VBoxContainer/MarginContainer/HBoxContainer/LinesPerFrame/Label2

func _on_lines_per_frame_value_changed(value: float) -> void:
	label_2_5.text = str(value)
	lines_per_frame = int(value)
