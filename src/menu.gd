extends Control

@onready var vle = $VBox/HBox/HBox/Vle
@onready var audio = $AudioStreamPlayer

var game_path = "res://src/player_view.tscn"

func _ready():
	get_tree().paused = false
	AudioServer.set_bus_volume_db(0, linear_to_db(0.8))

func _on_play_button_up():
	get_tree().change_scene_to_file(game_path)

func _on_h_slider_value_changed(value):
	if value == 0:
		AudioServer.set_bus_mute(0, true)
	else:
		AudioServer.set_bus_mute(0, false)
		AudioServer.set_bus_volume_db(0, linear_to_db(value))
	vle.set_text("%3d" % (value * 100))
	if not audio.is_playing():
		audio.play()
