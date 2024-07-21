extends Node2D

@onready var parent = $"../.."
@onready var container = $"../Pieces"
@onready var clock = $"../Time"
@onready var l1 = $"../HBox/L1"
@onready var l2 = $"../HBox/L2"
@onready var l3 = $"../HBox/L3"
@onready var l4 = $"../HBox/L4"
@onready var anim = $"../AnimationPlayer"
@onready var swap_audio = $"../SwapAudio"
@onready var match_audio = $"../MatchAudio"

var width = 16
var height = 6
var margin = 3
var piece_w = 48 + margin
var piece_h = 48 + margin
var offset = Vector2(75, 130)

var waiting_click = true
var click_pos
var release_pos
var swaping = false
var piece1
var last_p1_idx
var piece2
var last_p2_idx
var first_try = true

var time = 63.0 # 3s de 'brinde'
var time_over = false
var score = [0, 0, 0, 0]
var pieces = []

var rng = RandomNumberGenerator.new()

var piece_path = preload("res://src/piece.tscn")

# Called when the node enters the scene tree for the first time.
func _ready():
	update_score()
	for i in width:
		pieces.append([])
		for j in height:
			pieces[i].append(null)
	
	spawn_pieces()

func _process(delta):
	if time <= 0:
		clock.value = 0
		time_over = true
	else:
		time -= delta
		clock.value = time
	if waiting_click:
		if Input.is_action_just_pressed("shoot"):
			click_pos = mouse_to_grid(get_global_mouse_position())
			if click_pos != Vector2(-1, -1):
				swaping = true
		if Input.is_action_just_released("shoot") and swaping:
			release_pos = mouse_to_grid(get_global_mouse_position())
			var dir = calc_dir()
			swap_pieces(click_pos, dir)
			swaping = false

func update_score():
	l1.set_text(str(score[0]))
	l2.set_text(str(score[1]))
	l3.set_text(str(score[2]))
	l4.set_text(str(score[3]))

func calc_dir():
	var dir = Vector2(0, 0)
	var diff = release_pos - click_pos
	if abs(diff.x) > abs(diff.y):
		if diff.x > 0:
			dir = Vector2(1, 0)
		elif diff.x < 0:
			dir = Vector2(-1, 0)
	else:
		if diff.y > 0:
			dir = Vector2(0, 1)
		elif diff.y < 0:
			dir = Vector2(0, -1)
	return dir

func spawn_pieces():
	for i in width:
		for j in height:
			var rnd_type = rng.randi_range(0, 3)
			while(not validate_spawn_piece(i, j, rnd_type)):
				rnd_type += 1
				if rnd_type > 3:
					rnd_type = 0
			var piece = piece_path.instantiate()
			pieces[i][j] = piece
			container.add_child(piece)
			piece.frame = rnd_type
			piece.position = Vector2(i * piece_w, j * piece_h) + offset

func swap_pieces(p, dir):
	swap_audio.play()
	last_p1_idx = p
	last_p2_idx = p + dir
	piece1 = pieces[p.x][p.y]
	piece2 = pieces[last_p2_idx.x][last_p2_idx.y]
	if piece1 != null and piece2 != null:
		waiting_click = false
		pieces[p.x][p.y] = piece2
		pieces[last_p2_idx.x][last_p2_idx.y] = piece1
		var dur = 0.25
		var tween = get_tree().create_tween().set_parallel(true)
		tween.tween_property(piece1, "position", piece2.position, dur)
		tween.tween_property(piece2, "position", piece1.position, dur)
		await get_tree().create_timer(dur).timeout
		first_try = true
		find_matches()

func swap_back():
	swap_audio.play()
	if piece1 != null and piece2 != null:
		pieces[last_p1_idx.x][last_p1_idx.y] = piece1
		pieces[last_p2_idx.x][last_p2_idx.y] = piece2
		var dur = 0.25
		var tween = get_tree().create_tween().set_parallel(true)
		tween.tween_property(piece1, "position", piece2.position, dur)
		tween.tween_property(piece2, "position", piece1.position, dur)
		await get_tree().create_timer(dur).timeout
	if time_over:
		change_mode()
	else:
		waiting_click = true

func find_matches():
	var found_some = false
	for i in width:
		for j in height:
			if i > 0 and i < width-1:
				if pieces[i-1][j] != null and pieces[i][j] != null and pieces[i+1][j] != null:
					var type = pieces[i][j].frame
					if pieces[i-1][j].frame == type and pieces[i+1][j].frame == type:
						# Match
						found_some = true
						pieces[i-1][j].modulate = Color(1, 1, 1, 0.5)
						pieces[i][j].modulate = Color(1, 1, 1, 0.5)
						pieces[i+1][j].modulate = Color(1, 1, 1, 0.5)
			if j > 0 and j < height-1:
				if pieces[i][j-1] != null and pieces[i][j] != null and pieces[i][j+1] != null:
					var type = pieces[i][j].frame
					if pieces[i][j-1].frame == type and pieces[i][j+1].frame == type:
						# Match
						found_some = true
						pieces[i][j-1].modulate = Color(1, 1, 1, 0.5)
						pieces[i][j].modulate = Color(1, 1, 1, 0.5)
						pieces[i][j+1].modulate = Color(1, 1, 1, 0.5)
	if found_some:
		match_audio.play()
		await get_tree().create_timer(0.5).timeout
		destroy_matches()
		first_try = false
	else:
		if first_try:
			swap_back()
		else:
			if time_over:
				change_mode()
			else:
				waiting_click = true

func destroy_matches():
	for i in width:
		for j in height:
			if pieces[i][j] != null:
				if pieces[i][j].modulate.is_equal_approx(Color(1, 1, 1, 0.5)):
					score[pieces[i][j].frame] += 1
					pieces[i][j].queue_free()
					pieces[i][j] = null
	update_score()
	await get_tree().create_timer(0.5).timeout
	collapse_pieces()

func collapse_pieces():
	for i in width:
		for j in range(height-1, -1, -1): # height-1 ~ 0
			# De baixo para cima
			if pieces[i][j] == null:
				for k in range(j-1, -1, -1): # height-j ~ 0
					if pieces[i][k] != null:
						pieces[i][j] = pieces[i][k]
						pieces[i][k] = null
						var dur = 0.25
						var tween = get_tree().create_tween()
						var new_pos = pieces[i][j].position + Vector2(0, piece_h * (j - k))
						#print(pieces[i][k].position, " -> ", pieces[i][k].position + Vector2(0, piece_h * (j - k)))
						tween.tween_property(pieces[i][j], "position", new_pos, dur)
						break
	await get_tree().create_timer(0.5).timeout
	refill_pieces()

func refill_pieces():
	for i in width:
		for j in height:
			if pieces[i][j] == null:
				var rnd_type = rng.randi_range(0, 3)
				while(not validate_spawn_piece(i, j, rnd_type)):
					rnd_type += 1
					if rnd_type > 3:
						rnd_type = 0
				var piece = piece_path.instantiate()
				pieces[i][j] = piece
				container.add_child(piece)
				piece.frame = rnd_type
				piece.position = Vector2(i * piece_w, j * piece_h) + offset
	find_matches()

func validate_spawn_piece(i, j, type):
	if i > 1:
		if pieces[i-1][j] != null and pieces[i-2][j] != null:
			if pieces[i-1][j].frame == type and pieces[i-2][j].frame == type:
				return false
	if j > 1:
		if pieces[i][j-1] != null and pieces[i][j-2] != null:
			if pieces[i][j-1].frame == type and pieces[i][j-2].frame == type:
				return false
	return true

func mouse_to_grid(pos):
	pos = pos - offset
	var x = int(pos.x / piece_w)
	var y = int(pos.y / piece_h)
	if x < 0 or x >= width or y < 0 or y >= height:
		return Vector2(-1, -1)
	return Vector2(x, y)

func change_mode():
	get_tree().paused = true
	
	anim.play("ChangeToFPS")
	await anim.animation_finished
	
	var dur = 1.0
	var tween = get_tree().create_tween()
	tween.tween_property($"..", "modulate", Color(1, 1, 1, 0), dur)
	
	parent.update_ammo(score)
