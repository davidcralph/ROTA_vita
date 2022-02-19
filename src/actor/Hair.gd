tool
extends Node2D

export var color := Color("00fff9") # 00fff9 ff007e
export var width := 50.0
export var end_scale := 0.75
export var length = 25.0
export var sitting_angle = 15.0

export var gravity = 190.0
export var lerp_weight := 0.2

export var point_count := 3 setget set_points

var points = []
var last_pos := Vector2.ZERO
var hair_end = Vector2(-150, 150)

func _ready():
	set_points()

func _physics_process(delta):
	# move end
	hair_end -= hair_end - to_local(last_pos)
	
	# gravity
	hair_end += Vector2.DOWN * gravity * delta
	
	# keep hair behind back
	var a = rad2deg(hair_end.angle()) - 90
	if abs(a) < sitting_angle:
		var diff = (sitting_angle - abs(a)) * global_scale.x
		var l = lerp(0,  deg2rad(diff), lerp_weight)
		hair_end = hair_end.rotated(l)
	
	# keep length
	if hair_end.length() > length:
		hair_end = hair_end.normalized() * length
	
	# set points
	for i in points.size():
		points[i] = hair_end.normalized() * hair_end.length() * (float(i) / (points.size() - 1))
	
	
	last_pos = to_global(hair_end)
	update()

func _draw():
	for i in points.size():
		var w = (width * 0.5) * lerp(1.0, end_scale, i / float(points.size() - 1))
		draw_circle(points[i], w, color) 
	
	if Engine.editor_hint:
		for i in points.size():
			draw_circle(points[i], 1, Color.white)

func set_points(arg := point_count):
	point_count = max(2, arg)
	
	points = []
	for i in point_count:
		points.append(Vector2.ZERO)
	
	update()

