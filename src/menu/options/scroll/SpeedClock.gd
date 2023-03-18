extends Scroll

func _ready():
	cursor = Shared.clock_show
	set_label()

func set_value():
	Shared.clock_show = cursor
	UI.scene_changed(true)
	MenuOptions.fill_items()
