extends Node2D

### ViewLayers node naming ###
# The player (pla) can see 12 differents tiles
# Two of them (l22 and l24) has two visibles sides (f-ront and s-ide)
	# l31 l32 l33 l34 l35
	# l21 l22 l23 l24 l25
	# xxx l11 pla l12 xxx

@onready var view_layers = $ViewLayers
@onready var l_31 = $ViewLayers/L31
@onready var l_32 = $ViewLayers/L32
@onready var l_33 = $ViewLayers/L33
@onready var l_34 = $ViewLayers/L34
@onready var l_35 = $ViewLayers/L35
@onready var l_21 = $ViewLayers/L21
@onready var l_22f = $ViewLayers/L22f
@onready var l_22s = $ViewLayers/L22s
@onready var l_25 = $ViewLayers/L25
@onready var l_24f = $ViewLayers/L24f
@onready var l_24s = $ViewLayers/L24s
@onready var l_23 = $ViewLayers/L23
@onready var l_11 = $ViewLayers/L11
@onready var l_12 = $ViewLayers/L12

@onready var tilemap = $TileMap
@onready var mini_map = $MiniMap
@onready var ping = $Ping
@onready var goal_node = $Goal

@onready var crosshair = $Crosshair
@onready var lb_weapon = $WeaponHUD/VBox/Weapon
@onready var lb_cartridge = $WeaponHUD/VBox/HBox/Cartridge
@onready var lb_ammo = $WeaponHUD/VBox/HBox/Ammo
@onready var lb_reloading = $WeaponHUD/VBox/Reloading

@onready var enemies = $Enemies
@onready var anim = $AnimationPlayer

@onready var change_audio = $ChangeAudio
@onready var pistol_audio = $PistolAudio
@onready var shotgun_audio = $ShotgunAudio
@onready var rifle_audio = $RifleAudio
@onready var smg_audio = $SMGAudio
@onready var no_ammo_audio = $NoAmmoAudio
@onready var reloading_audio = $ReloadingAudio

var FPS_mode = false
var goal = Vector2(11, 6)

var hp = 5
var player_pos = Vector2(5, 9)
var player_dir = Vector2(0, -1)

var weapons = [
	# Name, Damage, Fire Rate, Reload Time, Range, Magazine Size, Ammo in Weapon, Ammo in Inventory, auto
	["Pistol", 2, 0.1, 1.5, 3, 8, 0, 0, false],
	["Shotgun", 5, 0.3, 3.5, 1, 2, 0, 0, false],
	["Assault Rifle", 3, 0.05, 1.85, 3, 30, 0, 0, true],
	["SMG", 1, 0.01, 1.25, 2, 45, 0, 0, true]
]
var weapon = 0
var shoot_cd = 0.0
var reload_cd = 0.0

var menu_path = "res://src/menu.tscn"

func _ready():
	draw_view()
	update_weapon()
	get_tree().paused = false

func _process(delta):
	if FPS_mode:
		if shoot_cd > 0:
			shoot_cd -= delta
			if shoot_cd <= 0:
				# Crosshair red if no ammo
				if weapons[weapon][6] + weapons[weapon][7] > 0:
					crosshair.modulate = "#acfdad"
				else:
					crosshair.modulate = "#e22c46"
				#print("end shoot")
		elif reload_cd > 0:
			reload_cd -= delta
			if reload_cd <= 0:
				reloading_audio.stop()
				lb_reloading.hide()
				crosshair.modulate = "#acfdad"
				#print("reloaded")
		
		if Input.is_action_just_pressed("front"):
			move("front")
		elif Input.is_action_just_pressed("back"):
			move("back")
		elif Input.is_action_just_pressed("move-left"):
			move("left")
		elif Input.is_action_just_pressed("move-right"):
			move("right")
		elif Input.is_action_just_pressed("turn-left"):
			if player_dir == Vector2(0, -1): # Up
				player_dir = Vector2(-1, 0) # Left
			elif player_dir == Vector2(1, 0): # Right
				player_dir = Vector2(0, -1) # Up
			elif player_dir == Vector2(0, 1): # Down
				player_dir = Vector2(1, 0) # Right
			elif player_dir == Vector2(-1, 0): # Left
				player_dir = Vector2(0, 1) # Down
			draw_view()
		elif Input.is_action_just_pressed("turn-right"):
			if player_dir == Vector2(0, -1): # Up
				player_dir = Vector2(1, 0) # Right
			elif player_dir == Vector2(1, 0): # Right
				player_dir = Vector2(0, 1) # Down
			elif player_dir == Vector2(0, 1): # Down
				player_dir = Vector2(-1, 0) # Left
			elif player_dir == Vector2(-1, 0): # Left
				player_dir = Vector2(0, -1) # Up
			draw_view()
		
		if Input.is_action_just_pressed("shoot"):
			shoot(get_viewport().get_mouse_position())
		elif Input.is_action_pressed("shoot") and weapons[weapon][8]:
			shoot(get_viewport().get_mouse_position())
		
		if Input.is_action_just_pressed("reload"):
			reload()

func _input(event):
	if FPS_mode:
		if event is InputEventMouseButton:
			if event.button_index == 4 and event.pressed: # Mouse Scroll Up
				change_audio.play()
				weapon -= 1
				if weapon < 0:
					weapon = weapons.size() - 1
				# Crosshair red if no ammo
				if weapons[weapon][6] + weapons[weapon][7] > 0:
					crosshair.modulate = "#acfdad"
				else:
					crosshair.modulate = "#e22c46"
				update_weapon()
			elif event.button_index == 5 and event.pressed: # Mouse Scroll Down
				change_audio.play()
				weapon += 1
				if weapon >= weapons.size():
					weapon = 0
				# Crosshair red if no ammo
				if weapons[weapon][6] + weapons[weapon][7] > 0:
					crosshair.modulate = "#acfdad"
				else:
					crosshair.modulate = "#e22c46"
				update_weapon()
		elif event is InputEventMouseMotion:
			crosshair.position = event.position

func move(dir):
	match dir:
		"front":
			if tilemap.get_cell_source_id(0, player_pos + player_dir) != -1:
				#print("Can't move, blocked by wall")
				return
			# Else
			player_pos += player_dir
		"back":
			if tilemap.get_cell_source_id(0, player_pos - player_dir) != -1:
				#print("Can't move, blocked by wall")
				return
			# Else
			player_pos -= player_dir
		"left":
			var move_dir
			if player_dir == Vector2(0, -1): # Up
				move_dir = Vector2(-1, 0) # Left
			elif player_dir == Vector2(1, 0): # Right
				move_dir = Vector2(0, -1) # Up
			elif player_dir == Vector2(0, 1): # Down
				move_dir = Vector2(1, 0) # Right
			elif player_dir == Vector2(-1, 0): # Left
				move_dir = Vector2(0, 1) # Down
			
			if tilemap.get_cell_source_id(0, player_pos + move_dir) != -1:
				#print("Can't move, blocked by wall")
				return
			# Else
			player_pos += move_dir
		"right":
			var move_dir
			if player_dir == Vector2(0, -1): # Up
				move_dir = Vector2(1, 0) # Right
			elif player_dir == Vector2(1, 0): # Right
				move_dir = Vector2(0, 1) # Down
			elif player_dir == Vector2(0, 1): # Down
				move_dir = Vector2(-1, 0) # Left
			elif player_dir == Vector2(-1, 0): # Left
				move_dir = Vector2(0, -1) # Up
			
			if tilemap.get_cell_source_id(0, player_pos + move_dir) != -1:
				#print("Can't move, blocked by wall")
				return
			# Else
			player_pos += move_dir
	draw_view()

func draw_view():
	for l in view_layers.get_children():
		l.hide()
	
	for e in enemies.get_children():
		e.hide()
	
	var axis
	var inverted
	if player_dir == Vector2(0, -1): # Up
		ping.frame = 0
		axis = 0
		inverted = false
	elif player_dir == Vector2(1, 0): # Right
		ping.frame = 1
		axis = 1
		inverted = false
	elif player_dir == Vector2(0, 1): # Down
		ping.frame = 2
		axis = 0
		inverted = true
	elif player_dir == Vector2(-1, 0): # Left
		ping.frame = 3
		axis = 1
		inverted = true
	
	# The last value is exclusive, so there's +1 in both
	for i in range(-2, 3): # -2 ~ 2
		for j in range(-2, 1): # -2 ~ 0
			if axis == 0:
				if not inverted:
					if tilemap.get_cell_source_id(0, player_pos + Vector2(i, j)) != -1:
						show_block(i, j)
					else:
						for e in enemies.get_children():
							if e.pos == (player_pos + Vector2(i, j)):
								has_enemy(e, i, j)
				else:
					if tilemap.get_cell_source_id(0, player_pos + Vector2(-i, -j)) != -1:
						show_block(i, j)
					else:
						for e in enemies.get_children():
							if e.pos == (player_pos + Vector2(-i, -j)):
								has_enemy(e, i, j)
			else:
				if not inverted:
					if tilemap.get_cell_source_id(0, player_pos + Vector2(-j, i)) != -1:
						show_block(i, j)
					else:
						for e in enemies.get_children():
							if e.pos == (player_pos + Vector2(-j, i)):
								has_enemy(e, i, j)
				else:
					if tilemap.get_cell_source_id(0, player_pos + Vector2(j, -i)) != -1:
						show_block(i, j)
					else:
						for e in enemies.get_children():
							if e.pos == (player_pos + Vector2(j, -i)):
								has_enemy(e, i, j)
	
	# l31 l32 l33 l34 l35
	# l21 l22 l23 l24 l25
	# xxx l11 Pla l12 xxx
	
	draw_mini_map()

func show_block(i, j):
	match j:
		-2:
			match i:
				-2:
					l_31.show()
				-1:
					l_32.show()
				0:
					l_33.show()
				1:
					l_34.show()
				2:
					l_35.show()
		-1:
			match i:
				-2:
					l_21.show()
				-1:
					l_22f.show()
					l_22s.show()
				0:
					l_23.show()
				1:
					l_24f.show()
					l_24s.show()
				2:
					l_25.show()
		0:
			match i:
				-2:
					pass
				-1:
					l_11.show()
				0:
					pass
				1:
					l_12.show()
				2:
					pass

func has_enemy(e, i, j):
	if j == -1:
		match i:
			-1:
				e.position = Vector2(96, 270)
				e.scale = Vector2(1, 1)
				e.z_index = 1
				e.show()
			0:
				e.position = Vector2(480, 270)
				e.scale = Vector2(1, 1)
				e.z_index = 1
				e.show()
			1:
				e.position = Vector2(864, 270)
				e.scale = Vector2(1, 1)
				e.z_index = 1
				e.show()
	if j == 0 and i == 0:
		e.position = Vector2(480, 202)
		e.scale = Vector2(2, 2)
		e.z_index = 2
		e.show()
	return Vector2(-1, -1)

func get_enemy_pos(i, j):
	if j == -1:
		match i:
			-1:
				return Vector2(96, 270)
			0:
				return Vector2(480, 270)
			1:
				return Vector2(864, 270)
	if j == 0 and i == 0:
		return Vector2(480, 202)
	return Vector2(-1, -1)

func draw_mini_map():
	var x = -2
	var y = -2
	
	goal_node.hide()
	for cell in mini_map.get_children():
		if tilemap.get_cell_source_id(0, player_pos + Vector2(x, y)) == -1:
			cell.frame = 0
		else:
			cell.frame = 1
		
		if player_pos + Vector2(x, y) == goal:
			goal_node.show()
			goal_node.position = Vector2(880, 64) + Vector2(x, y) * 16
		
		x += 1
		if x == 3:
			x = -2
			y += 1
	
	if player_pos == goal:
		$GameOver.set_text("You Win!")
		anim.play("Win")
		get_tree().paused = true

func shoot(pos):
	if shoot_cd <= 0.0 and reload_cd <= 0.0:
		# It's not shooting or reloading
		if weapons[weapon][6] > 0:
			# Has ammo loaded in the weapon
			match weapon:
				0:
					pistol_audio.play()
				1:
					shotgun_audio.play()
				2:
					rifle_audio.play()
				3:
					smg_audio.play()
			
			for e in enemies.get_children():
				if e.is_visible():
					e.hit(pos, weapons[weapon][1])
			crosshair.modulate = "#e22c46"
			shoot_cd = weapons[weapon][2]
			weapons[weapon][6] -= 1
			update_weapon()
		else: # No ammo in weapon
			#no_ammo_audio.play()
			shoot_cd = weapons[weapon][2]
			reload()

func reload():
	var missing_bullets = weapons[weapon][5] - weapons[weapon][6]
	if missing_bullets > 0:
		if weapons[weapon][7] >= missing_bullets:
			reloading_audio.play()
			#print("reloading")
			crosshair.modulate = "#e22c46"
			lb_reloading.show()
			
			reload_cd = weapons[weapon][3]
			weapons[weapon][6] = weapons[weapon][5]
			weapons[weapon][7] -= missing_bullets
		elif weapons[weapon][7] > 0:
			reloading_audio.play()
			#print("reloading")
			crosshair.modulate = "#e22c46"
			lb_reloading.show()
			
			reload_cd = weapons[weapon][3]
			weapons[weapon][6] += weapons[weapon][7]
			weapons[weapon][7] = 0
		else: # no ammo in inventory
			no_ammo_audio.play()
			if weapons[weapon][6] == 0:
				#print("no ammo")
				crosshair.modulate = "#e22c46"
			else:
				#print("no ammo in inventory")
				pass
		update_weapon()

func update_weapon():
	lb_weapon.set_text(weapons[weapon][0])
	lb_cartridge.set_text("%d / %d" % [weapons[weapon][6], weapons[weapon][5]])
	lb_ammo.set_text("- %d" % weapons[weapon][7])

func update_ammo(arr):
	if arr[0] <= weapons[0][5]:
		weapons[0][6] = arr[0]
	else:
		weapons[0][6] = weapons[0][5]
	weapons[0][7] = arr[0] - weapons[0][6]
	
	if arr[1] <= weapons[1][5]:
		weapons[1][6] = arr[1]
	else:
		weapons[1][6] = weapons[1][5]
	weapons[1][7] = arr[1] - weapons[1][6]
	
	if arr[2] <= weapons[2][5]:
		weapons[2][6] = arr[2]
	else:
		weapons[2][6] = weapons[2][5]
	weapons[2][7] = arr[2] - weapons[2][6]
	
	if arr[3] <= weapons[3][5]:
		weapons[3][6] = arr[3]
	else:
		weapons[3][6] = weapons[3][5]
	weapons[3][7] = arr[3] - weapons[3][6]
	
	update_weapon()
	await get_tree().create_timer(2.0).timeout
	
	get_tree().paused = false
	FPS_mode = true

func hit(damage):
	anim.play("Hit")
	#hp -= damage
	
	var dur = 0.25
	var tween = get_tree().create_tween().set_parallel(true)
	for d in damage:
		match hp:
			5:
				tween.tween_property($HPHUD/HBox/HP5, "modulate", Color(1, 1, 1, 0), dur)
			4:
				tween.tween_property($HPHUD/HBox/HP4, "modulate", Color(1, 1, 1, 0), dur)
			3:
				tween.tween_property($HPHUD/HBox/HP3, "modulate", Color(1, 1, 1, 0), dur)
			2:
				tween.tween_property($HPHUD/HBox/HP2, "modulate", Color(1, 1, 1, 0), dur)
			1:
				tween.tween_property($HPHUD/HBox/HP1, "modulate", Color(1, 1, 1, 0), dur)
			_:
				break
		hp -= 1
	
	if hp <= 0:
		get_tree().paused = true
		await get_tree().create_timer(dur).timeout
		anim.play("GameOver")

func _on_button_up():
	get_tree().change_scene_to_file(menu_path)
