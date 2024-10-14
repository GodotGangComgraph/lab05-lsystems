extends Control

# Узлы кривой Безье
var control_points = []

# Возвращает точку на кривой Безье в зависимости от параметра t
func bezier_point(t: float, index: int) -> Vector2:
	var p0 = control_points[index * 3]
	var p1 = control_points[index * 3 + 1]
	var p2 = control_points[index * 3 + 2]
	var p3 = control_points[index * 3 + 3]
	# Формула кубического сплайна Безье
	return (1 - t) * (1 - t) * (1 - t) * p0 + \
		3 * (1 - t) * (1 - t) * t * p1 + \
		3 * (1 - t) * t * t * p2 + \
		t * t * t * p3

# Рисует кривую Безье
func _draw():
	if control_points.is_empty():
		return
	var old_point = control_points[0]
	for point in control_points.slice(1, control_points.size()):
		draw_circle(old_point, 5, Color.GRAY)
		draw_dashed_line(old_point, point, Color.WEB_GRAY, 2)
		old_point = point
	draw_circle(old_point, 5, Color.GRAY)
	
	var sz = (control_points.size() - 4) / 3 + 1
	if control_points.size() < 4:
		sz = 0
	for i in range(sz):
		var points = 100
		var old_pos = control_points[i * 3]
		for j in range(points):
			var t = j / float(points)  # Нормализованное значение t от 0 до 1
			var pos = bezier_point(t, i)  # Получаем точку на кривой
			draw_line(old_pos, pos, Color.RED)
			old_pos = pos
			
func _on_panel_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == 1 and event.pressed:
			control_points.append(event.global_position)
			queue_redraw()
	


func _on_clear_pressed() -> void:
	control_points.clear()
	queue_redraw()
