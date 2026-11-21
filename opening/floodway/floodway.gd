extends Node2D

@onready var bot = $"../Robot"
@onready var fight = $"../Encounter"
var last_dry := Vector2(285,210)
var powered := false

func _physics_process(_delta):
	if fight.state != "open" or bot.parts_lost == 5:
		$CallHint.hide()
		return
	if bot.is_on_floor():
		for i in bot.get_slide_collision_count():
			var hit = bot.get_slide_collision(i)
			if hit.get_normal().y > -0.9: continue
			var body = hit.get_collider()
			if body.is_in_group("flood_landing"):
				var half_width: float = body.get_node("Shape").shape.size.x / 2.0
				last_dry = Vector2(clampf(bot.position.x, body.position.x-half_width+6, body.position.x+half_width-6), body.position.y-12)
			elif body == fight.get_node("NextFloor"): last_dry = Vector2(300,210)
	if bot.position.x >= 300 and bot.position.y + 12 >= 246:
		var drop = preload("res://opening/locked_part.gd").new()
		drop.part = bot.next_part()
		drop.bot = bot
		drop.position = last_dry
		fight.get_node("Drops").add_child(drop)
		bot.lose_part()
		return
	$CallHint.visible = not powered and bot.is_on_floor() and bot.position.distance_to(Vector2(3263,108)) <= 16
	if $CallHint.visible and Input.is_action_just_pressed("interact"):
		powered = true
		$CallHint.hide()
		$LiveLamp.show()
		$Display.show()

func _touch_checkpoint(body: Node2D) -> void:
	if body != bot or bot.parts_lost >= 5 or fight.state != "open" or $P18/Checkpoint/LED.frame == 1:
		return
	bot.spawn_position = $P18.global_position + Vector2.UP * 12
	$P18/Checkpoint/LED.frame = 1
