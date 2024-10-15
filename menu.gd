extends Control


func _on_fractals_pressed() -> void:
	get_tree().change_scene_to_file("res://l_system.tscn")
	
	


func _on_midpoint_pressed() -> void:
	get_tree().change_scene_to_file("res://midpoint.tscn")
	



func _on_bezier_pressed() -> void:
	get_tree().change_scene_to_file("res://bezier.tscn")
