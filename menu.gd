extends Control
@onready var open_rgb: Button = $MarginContainer/VBoxContainer/OpenRGB
@onready var open_hsv: Button = $MarginContainer/VBoxContainer/OpenHSV
@onready var open_grayscale: Button = $MarginContainer/VBoxContainer/OpenGrayscale
@onready var file_dialog: FileDialog = $FileDialog
@onready var label: Label = $MarginContainer/VBoxContainer/Label

func _on_file_dialog_file_selected(path: String) -> void:
	open_rgb.disabled = false
	open_hsv.disabled = false
	open_grayscale.disabled = false
	label.text = "Loaded image from %s" % path
	
	ImagePath.image_path = path

func _ready() -> void:
	if ImagePath.image_path != "":
		open_rgb.disabled = false
		open_hsv.disabled = false
		open_grayscale.disabled = false
		label.text = "Loaded image from %s" % ImagePath.image_path

func _on_load_image_pressed() -> void:
	file_dialog.popup()


func _on_open_grayscale_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/grayscale.tscn")


func _on_open_rgb_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/rgb.tscn")


func _on_open_hsv_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/hsv.tscn")
