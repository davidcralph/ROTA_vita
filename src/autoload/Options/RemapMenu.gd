extends CanvasLayer

onready var control := $Control
onready var cursor_node := $Control/Cursor

onready var list_node := $Control/List
onready var items_node := $Control/List/Items
onready var items := items_node.get_children()

var is_open := false
var open = EaseMover.new()

var scroll := 0
var cursor := 0 setget set_cursor
export var cursor_margin := Vector2(-50, 0)

var joy := Vector2.ZERO
var joy_last := Vector2.ZERO

var grid := {}

var actions = {"Move Left": "left",
"Move Right": "right",
"Turn Box+": "up",
"Turn Box-": "down",
"Jump": "jump",
"Grab": "grab",
"Zoom": "zoom",
"Reset": "reset",}

var tex = {"JOY 0": preload("res://media/image/UI/btn_a.png"),
"JOY 1": preload("res://media/image/UI/btn_b.png"),
"JOY 2": preload("res://media/image/UI/btn_x.png"),
"JOY 3": preload("res://media/image/UI/btn_y.png"),
"JOY 10": preload("res://media/image/UI/btn_select.png"),
"JOY 11": preload("res://media/image/UI/btn_start.png"),
"JOY 12": preload("res://media/image/UI/dpad_up.png"),
"JOY 13": preload("res://media/image/UI/dpad_up.png"),
"JOY 14": preload("res://media/image/UI/dpad_up.png"),
"JOY 15": preload("res://media/image/UI/dpad_up.png"),
"AXIS 1-": preload("res://media/image/UI/l_stick_up.png"),
"AXIS 1+": preload("res://media/image/UI/l_stick_down.png"),
"AXIS 0-": preload("res://media/image/UI/l_stick_left.png"),
"AXIS 0+": preload("res://media/image/UI/l_stick_right.png"),
"AXIS 2-": preload("res://media/image/UI/r_stick_up.png"),
"AXIS 2+": preload("res://media/image/UI/r_stick_down.png"),
"AXIS 3-": preload("res://media/image/UI/r_stick_left.png"),
"AXIS 3+": preload("res://media/image/UI/r_stick_right.png"),
"KEY": preload("res://media/image/box/round_rect200.png"),
"KEY_2": preload("res://media/image/UI/key_2.png"),
"KEY_3": preload("res://media/image/UI/key_3.png"),
"UP": preload("res://media/image/UI/key_up.png"),
"DOWN": preload("res://media/image/UI/key_up.png"),
"LEFT": preload("res://media/image/UI/key_up.png"),
"RIGHT": preload("res://media/image/UI/key_up.png"),}

var rotate = {"DOWN": 180,
"LEFT": 270,
"RIGHT": 90,
"JOY 13": 180,
"JOY 14": 270,
"JOY 15": 90,}

var prompt := EaseMover.new()
var is_prompt := false
onready var prompt_key := $Control/Prompt/VBoxContainer/Key
onready var prompt_timer_label := $Control/Prompt/VBoxContainer/Timer
var prompt_clock := 0.0
var prompt_time := 5.0
var is_button := false

var events = {}

onready var row := $Control/List/Base/Row
onready var key := $Control/List/Base/Key

func _ready():
	open.from = Vector2(0, 720)
	open.to = Vector2.ZERO
	open.node = control
	
	prompt.node = $Control/Prompt
	prompt.to = prompt.node.rect_position
	prompt.from = Vector2(prompt.to.x, 720)
	
	$Control/List/Base.visible = false
	
	
	for i in actions.size():
		var r = row.duplicate()
		items_node.add_child(r)
		
		r.get_node("Label").text = actions.keys()[i]
	items = items_node.get_children()
	
	for i in items.size():
		create_keys(i)
	

func _input(event):
	if !is_open: return
	
	if is_prompt:
		if event.is_action_pressed("ui_pause"):
			is_prompt = false
		elif event is InputEventKey and event.is_pressed():
			assign_key(actions.values()[cursor], event)
			is_prompt = false
			get_tree().set_input_as_handled()
		
	else:
		joy_last = joy
		joy = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down").round()
		
		# move cursor
		if joy.y != 0 and joy.y != joy_last.y:
			self.cursor += joy.y
		
		# open prompt
		elif event.is_action_pressed("ui_accept"):
			is_prompt = true
			prompt_key.text = actions.keys()[cursor]
			prompt_clock = prompt_time
			get_tree().set_input_as_handled()
		
		# clear key
		elif event.is_action_pressed("ui_end"):
			clear_row(cursor)
			pass
		
		# exit
		elif event.is_action_pressed("ui_cancel"):
			get_tree().set_input_as_handled()
			show(false)

func _physics_process(delta):
	if is_prompt:
		prompt_clock -= delta
		prompt_timer_label.text = str(ceil(max(0, prompt_clock)))
		
		if prompt_clock < 0:
			is_prompt = false
	
	# ease mover
	open.move(delta, is_open)
	prompt.move(delta, is_prompt)
	
	if open.clock == 0: return
	
	var target = items[cursor]
	
	# position
	var cg = cursor_node.rect_global_position
	cg = cg.linear_interpolate(target.rect_global_position - cursor_margin, 0.15)
	cursor_node.rect_global_position = cg
	
	# size
	var cs = cursor_node.rect_size
	cs = cs.linear_interpolate(target.rect_size + (cursor_margin * 2.0), 0.15)
	cursor_node.rect_size = cs
	
	# scroll
	items_node.rect_position = items_node.rect_position.linear_interpolate(Vector2(0, 80) * -scroll, 0.15)

func show(arg := true):
	is_open = arg
	OptionsMenu.is_open = !is_open
	
	if is_open:
		cursor = 0
		scroll = 0

func set_cursor(arg := 0):
	cursor = clamp(arg, 0, items.size() - 1)
	
	if cursor < scroll or cursor > 5 + scroll:
		scroll = max(0, cursor - (0 if cursor < scroll else 5))

func draw_key(key_node, event):
	if !(event is InputEventKey): return
	
	var label = key_node.get_node("Label")
	var sprite = key_node.get_node("CenterContainer/Control/Sprite")
	
	var s = ""
	if event is InputEventJoypadButton:
		s = "JOY " + str(event.button_index)
	elif event is InputEvent:
		s = str(event.as_text().to_upper())
	
	# sprite
	if tex.has(s):
		label.visible = false
		
		sprite.texture = tex[s]
		if rotate.has(s):
			sprite.rotation_degrees = rotate[s]
	
	# text over key
	else:
		label.text = s
		
		if s.length() < 2:
			sprite.texture = tex["KEY"]
		else:
			sprite.texture = tex["KEY_2"]
	

func clear_row(row := 0):
	for i in items[row].get_node("Keys").get_children():
		i.queue_free()
	
	var action = actions.values()[row]
	
	for i in InputMap.get_action_list(action):
		if i is InputEventKey:
			InputMap.action_erase_event(action, i)
	

func assign_key(action, event):
	InputMap.action_add_event(action, event)
	
	create_keys(cursor)

func create_keys(row):
	var r = items[row]
	var action = actions.values()[row]
	
	for i in r.get_node("Keys").get_children():
		i.queue_free()
	
	for i in InputMap.get_action_list(action):
		if i is InputEventKey:
			var k = key.duplicate()
			r.get_node("Keys").add_child(k)
			
			draw_key(k, i)