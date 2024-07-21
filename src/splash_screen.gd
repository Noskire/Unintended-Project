extends Control

var menu_path = "res://src/menu.tscn"

func _on_animation_player_animation_finished(anim_name):
	get_tree().change_scene_to_file(menu_path)
