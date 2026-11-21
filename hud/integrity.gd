extends CanvasLayer

const LIVE := preload("res://hud/cell_on.png")
const BROKEN := preload("res://hud/cell_off.png")
const FACES := [preload("res://hud/fracture_0.png"), preload("res://hud/fracture_1.png"), preload("res://hud/fracture_2.png"), preload("res://hud/fracture_3.png"), preload("res://hud/fracture_4.png"), preload("res://hud/fracture_5.png")]
@onready var robot = get_node("../Robot")

func _ready() -> void:
	robot.parts_changed.connect(refresh)
	refresh()

func refresh() -> void:
	for cell in $Panel/Cells.get_children():
		# Battery at the left; the first lost part breaks the rightmost cell.
		var part_id = 4 - cell.get_index()
		cell.texture = LIVE
		if part_id in robot.missing:
			cell.texture = BROKEN
	$Panel/Face.texture = FACES[robot.parts_lost]
