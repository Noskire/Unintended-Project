extends Node2D

@onready var player = $"../.."
@onready var tilemap = $"../../TileMap"
@onready var sprite = $Sprite2D
@onready var anim = $AnimationPlayer
@onready var attack_audio = $AttackAudio

@export var pos = Vector2(4, 7)

var attack_range = 1
var move_range = 5
var hp = 5
var damage = 1

var size
var cooldown = 0.0
var atk_cd_time = 2.0
var move_cd_time = 3.0
var idle_cd_time = 5.0

# If close player, move towards player
# If next to it, attack

func _ready():
	# Only half, because the sprite is centered
	# Half to the beginning and half to the end
	size = sprite.get_texture().get_size() / 2
	
	cooldown = idle_cd_time

func _process(delta):
	if player.FPS_mode:
		if cooldown > 0:
			cooldown -= delta
		else:
			var diff = abs(pos - player.player_pos)
			if diff.x + diff.y <= attack_range:
				# Attack
				attack_audio.play()
				player.hit(damage)
				cooldown = atk_cd_time
			elif diff.x + diff.y <= move_range:
				# Move
				var dir
				if diff.x > diff.y:
					if (pos - player.player_pos).x > 0:
						# Go left
						dir = Vector2(-1, 0)
					else:
						# Go right
						dir = Vector2(1, 0)
				else:
					if (pos - player.player_pos).y > 0:
						# Go up
						dir = Vector2(0, -1)
					else:
						# Go down
						dir = Vector2(0, 1)
				if tilemap.get_cell_source_id(0, pos + dir) == -1:
					pos += dir
					player.draw_view()
				cooldown = move_cd_time
			else:
				# Wait
				cooldown = idle_cd_time

func hit(hit_pos, hit_damage):
	anim.play("Hit")
	if hit_pos.x >= position.x - size.x and hit_pos.x <= position.x + size.x:
		if hit_pos.y >= position.y - size.y and hit_pos.y <= position.y + size.y:
			hp -= hit_damage
			if hp <= 0:
				queue_free()

func _on_animation_player_animation_finished(_anim_name):
	anim.play("Idle")
