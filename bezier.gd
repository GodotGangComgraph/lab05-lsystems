extends Control

var control_points = []
var selected_point_index = -1

var point_radius = 5
var outline_radius = 8
var line_width = 1
var control_line_width = 1

var draw_control_points: bool = true
@onready var label_2: Label = $VBoxContainer/MarginContainer/HBoxContainer/LineWidth/Label2
@onready var label_2_2: Label = $VBoxContainer/MarginContainer/HBoxContainer/ControlLineWidth/Label2


func bezier_point(t: float, index: int) -> Vector2:
	var p0 = control_points[index * 3 + 1]
	var p1 = control_points[index * 3 + 2]
	var p2 = control_points[index * 3 + 3]
	var p3 = control_points[index * 3 + 4]
	return (1 - t) * (1 - t) * (1 - t) * p0 + \
		3 * (1 - t) * (1 - t) * t * p1 + \
		3 * (1 - t) * t * t * p2 + \
		t * t * t * p3

func _draw():
	if control_points.is_empty():
		return
	if draw_control_points:
			var old_point = control_points[0]
			if 0 == selected_point_index:
				draw_circle(old_point, outline_radius, Color.PURPLE) 
			for i in range(1, control_points.size()):
				var point = control_points[i]
				if i == selected_point_index:
					if i % 3 == 1:
						draw_rect(Rect2(point - Vector2(outline_radius, outline_radius), Vector2(2 * outline_radius, 2 * outline_radius)), Color.PURPLE)
					else:
						draw_circle(point, outline_radius, Color.PURPLE)
				if (i-1) % 3 == 1:
					draw_rect(Rect2(old_point - Vector2(point_radius, point_radius), Vector2(2 * point_radius, 2 * point_radius)), Color.GRAY) 
				else:
					draw_circle(old_point, point_radius, Color.GRAY)
				if i % 3 != 0:
					draw_dashed_line(old_point, point, Color.WEB_GRAY, control_line_width)
				old_point = point
			draw_circle(old_point, 5, Color.GRAY)
		
	var sz = (control_points.size() - 5) / 3 + 1
	if control_points.size() < 4:
		sz = 0
	for i in range(sz):
		var points = 1000
		var old_pos = control_points[i * 3 + 1]
		for j in range(points):
			var t = j / float(points)  # Нормализованное значение t от 0 до 1
			var pos = bezier_point(t, i)
			draw_line(old_pos, pos, Color.RED, line_width)
			old_pos = pos
			
func _on_panel_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_pos = event.global_position
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if draw_control_points:
				for i in range(control_points.size()):
					if mouse_pos.distance_to(control_points[i]) < point_radius:
						selected_point_index = i
						return
			var line = Vector2(40, 0)
			control_points.append(event.global_position - line)
			control_points.append(event.global_position)
			control_points.append(event.global_position + line)
			queue_redraw()
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			for i in range(control_points.size()):
				if mouse_pos.distance_to(control_points[i]) < point_radius:
					var index = i % 3
					if index != 1:
						return
					control_points.remove_at(i - 1)
					control_points.remove_at(i - 1)
					control_points.remove_at(i - 1)
					queue_redraw()
					return
		elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			selected_point_index = -1
			queue_redraw()
	elif event is InputEventMouseMotion and selected_point_index >= 0:
		var index = selected_point_index % 3
		var index_to_change
		var middle_point
		if index == 0:
			index_to_change = selected_point_index + 2
			middle_point = selected_point_index +1
		elif index == 2:
			index_to_change = selected_point_index - 2
			middle_point = selected_point_index - 1
		else:
			var a = selected_point_index - 1
			var b = selected_point_index + 1
			var vec = event.global_position - control_points[selected_point_index]
			control_points[selected_point_index] += vec
			control_points[a] += vec
			control_points[b] += vec
			queue_redraw()
			return
			
		var dist = control_points[middle_point].distance_to(control_points[index_to_change])
		control_points[selected_point_index] = event.global_position
		var ac = (control_points[selected_point_index] - control_points[middle_point]).normalized()
		control_points[index_to_change] = control_points[middle_point] - ac * dist
		
		queue_redraw()

func _on_clear_pressed() -> void:
	control_points.clear()
	queue_redraw()


func _on_check_box_toggled(toggled_on: bool) -> void:
	draw_control_points = toggled_on
	queue_redraw()


func _on_h_slider_value_changed(value: float) -> void:
	label_2.text = str(value)
	line_width = value
	queue_redraw()


func _on_control_line_width_value_changed(value: float) -> void:
	label_2_2.text = str(value)
	control_line_width = value
	queue_redraw()

@onready var label_2_3: Label = $VBoxContainer/MarginContainer/HBoxContainer/Radius/Label2
func _on_radius_value_changed(value: float) -> void:
	label_2_3.text = str(value)
	point_radius = value
	queue_redraw()

@onready var label_2_4: Label = $VBoxContainer/MarginContainer/HBoxContainer/OutlineSize/Label2
func _on_outline_size_value_changed(value: float) -> void:
	label_2_4.text = str(value)
	outline_radius = value + point_radius


func _on_menu_pressed() -> void:
	get_tree().change_scene_to_file("res://menu.tscn")
