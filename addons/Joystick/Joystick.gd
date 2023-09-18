@tool
extends EditorPlugin

func _enter_tree():
	# Initialization of the plugin goes here.
	add_custom_type("JoystickClient", "Node", preload("./Util/JoystickClient.gd"), preload("./Icons/JoystickClientNode.png"))

func _exit_tree():
	# Clean-up of the plugin goes here.
	# Remember clean up ALL the mess :3
	remove_custom_type("JoystickClient")
