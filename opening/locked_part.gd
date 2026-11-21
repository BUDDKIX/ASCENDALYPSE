extends Sprite2D

const PARTS := [preload("res://movement/damage/Screw.png"), preload("res://movement/damage/Spring.png"), preload("res://movement/damage/Fan.png"), preload("res://movement/damage/Wire.png"), preload("res://movement/damage/Battery.png")]
# Three-by-five bitmaps, drawn at native pixel size; zero is never displayed.
const GLYPHS = ["", "010110010010111", "111001111100111", "111001111001111", "101101111001001", "111100111001111"]
var part: int
var bot: CharacterBody2D
var remaining := 5.0
var digit := 5

func _ready(): texture = PARTS[part]

func _physics_process(dt):
	remaining = maxf(0, remaining - dt)
	var next := ceili(remaining - 0.000001)
	if next != digit:
		digit = next
		queue_redraw()
	if digit == 0 and absf(position.x - bot.position.x) <= 10 and absf(position.y - bot.position.y) <= 15:
		if bot.recover_part(part): queue_free()

func _draw():
	for i in GLYPHS[digit].length():
		if GLYPHS[digit][i] == "1": draw_rect(Rect2(i%3-1, floori(i/3.0)-13,1,1), Color("ff514d"))
