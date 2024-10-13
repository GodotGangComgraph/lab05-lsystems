extends Control

var line: Array[Vector2]
@onready var check_box: CheckBox = $VBoxContainer/MarginContainer/HBoxContainer/CheckBox
var draw_circles: bool
@onready var random: LineEdit = $VBoxContainer/MarginContainer/HBoxContainer/Random

func _draw() -> void:
	line.sort()
	if line.is_empty():
		return
	var old_point = line[0]
	for point in line.slice(1, line.size()):
		draw_line(old_point, Vector2(old_point.x, get_viewport_rect().size.y), Color.WHITE)
		if draw_circles:
			draw_circle(old_point, 3, Color.RED)
		draw_line(old_point, point, Color.WHITE, 1)
		old_point = point
	
	draw_line(line[-1], Vector2(old_point.x, get_viewport_rect().size.y), Color.WHITE)
	if draw_circles:
		draw_circle(line[-1], 3, Color.RED)


func _on_panel_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == 1 and event.pressed:
			line.append(event.global_position)
			if line.size() > 2:
				line.clear()
			queue_redraw()


func _on_clear_pressed() -> void:
	line.clear()
	queue_redraw()

func step(p1: Vector2, p2: Vector2, l: int, index: int):
	if l < 1:
		return
	var midpoint: Vector2 = (p1 + p2) / 2
	var r = float(random.text)
	midpoint = Vector2(midpoint.x, midpoint.y + randf_range(-r * l, r * l))
	line.insert(index, midpoint)
	#print(line)
	await get_tree().create_timer(0.8).timeout
	step(p1, midpoint, l / 2, index)
	step(midpoint, p2, l / 2, index + 1)
	queue_redraw()


func _on_start_pressed() -> void:
	step(line[0], line[1], (line[1] - line[0]).length(), 1)


func _on_check_box_toggled(toggled_on: bool) -> void:
	draw_circles = toggled_on
	queue_redraw()
	
