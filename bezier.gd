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
	var p0 = control_points[index * 4]
	var p1 = control_points[index * 4 + 1]
	var p2 = control_points[index * 4 + 2]
	var p3 = control_points[index * 4 + 3]
	return (1 - t) * (1 - t) * (1 - t) * p0 + \
		3 * (1 - t) * (1 - t) * t * p1 + \
		3 * (1 - t) * t * t * p2 + \
		t * t * t * p3

func _draw():
	if control_points.is_empty():
		return
	if draw_control_points:
		for k in range(control_points.size() / 4 + 1):
			if (k * 4 >= control_points.size()):
				break
			var old_point = control_points[k * 4]
			if k * 4 == selected_point_index:
				draw_circle(old_point, outline_radius, Color.PURPLE) 
			for i in range(k * 4 + 1, clamp((k + 1) * 4, 0, control_points.size())):
				var point = control_points[i]
				if i == selected_point_index:
					draw_circle(point, outline_radius, Color.PURPLE) 
				draw_circle(old_point, point_radius, Color.GRAY)
				draw_dashed_line(old_point, point, Color.WEB_GRAY, control_line_width)
				old_point = point
			draw_circle(old_point, 5, Color.GRAY)
		
	'''var sz = (control_points.size() - 4) / 3 + 1
	if control_points.size() < 4:
		sz = 0'''
	for i in range(control_points.size() / 4):
		var points = 1000
		var old_pos = control_points[i * 4]
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
			control_points.append(event.global_position)
			queue_redraw()
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			for i in range(control_points.size()):
				if mouse_pos.distance_to(control_points[i]) < point_radius:
					control_points.remove_at(i)
					queue_redraw()
					return		
	elif event is InputEventMouseMotion and selected_point_index >= 0:
		control_points[selected_point_index] = event.global_position
		queue_redraw()

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		selected_point_index = -1
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
