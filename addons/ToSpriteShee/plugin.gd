@tool
extends EditorPlugin

var dock

func _enter_tree():
	dock = preload("res://addons/ToSpriteShee/toSheet.gd").new()
	add_control_to_dock(DOCK_SLOT_LEFT_UR, dock)

func _exit_tree():
	remove_control_from_docks(dock)
	if dock:
		dock.queue_free()