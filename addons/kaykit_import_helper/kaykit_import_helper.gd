@tool
extends EditorPlugin

# A class member to hold the dock during the plugin life cycle.
var dock
# A class member to hold the instantiated dock scene during the plugin life cycle.
var dock_scene

func _enter_tree():
	# Initialization of the plugin goes here.
	# Load the dock scene and instantiate it.
	dock_scene = preload("res://addons/kaykit_import_helper/advanced_importer_dock/advanced_importer_dock.tscn").instantiate()

	# Create the dock and add the loaded scene to it.
	dock = EditorDock.new()
	dock.add_child(dock_scene)

	dock.title = "Advanced Import"

	# Note that LEFT_UR means the left of the editor, upper-right dock.
	dock.default_slot = DOCK_SLOT_LEFT_UR

	# Allow the dock to be on the left or right of the editor, and to be made floating.
	dock.available_layouts = EditorDock.DOCK_LAYOUT_VERTICAL | EditorDock.DOCK_LAYOUT_FLOATING

	add_dock(dock)
	dock_scene.connect("reimport_requested", _handle_reimport_request)

func _exit_tree():
	# Clean-up of the plugin goes here.
	# Remove the dock.
	remove_dock(dock)
	# Erase the control from the memory.
	dock.queue_free()

func _handle_reimport_request(settings: Dictionary[String, bool]) -> void:
	print(settings)
