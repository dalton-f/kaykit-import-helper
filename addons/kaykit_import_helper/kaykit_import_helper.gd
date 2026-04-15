@tool
extends EditorPlugin

#region Constants
const AVAILABLE_DOCK_LAYOUTS: int = EditorDock.DockLayout.DOCK_LAYOUT_VERTICAL | EditorDock.DockLayout.DOCK_LAYOUT_FLOATING
const DEFAULT_DOCK_SLOT: EditorDock.DockSlot = EditorDock.DockSlot.DOCK_SLOT_LEFT_UR
const DEFAULT_DOCK_TITLE: String = "Advanced Import"
#endregion

#region Variables
# A class member to hold the dock during the plugin life cycle.
var dock
# A class member to hold the instantiated dock scene during the plugin life cycle.
var dock_scene
#endregion

#region Virtual Methods
# Initialization of the plugin goes here.
func _enter_tree():
	_build_dock()
	
	dock_scene.connect("reimport_requested", _handle_reimport_request)

# Clean-up of the plugin goes here.
func _exit_tree():
	_erase_dock()
#endregion

func _build_dock() -> void:
	# Load the dock scene and instantiate it.
	dock_scene = preload("res://addons/kaykit_import_helper/advanced_importer_dock/advanced_importer_dock.tscn").instantiate()

	# Create the dock and add the loaded scene to it.
	dock = EditorDock.new()
	dock.add_child(dock_scene)

	dock.title = DEFAULT_DOCK_TITLE

	# Note that LEFT_UR means the left of the editor, upper-right dock.
	dock.default_slot = DEFAULT_DOCK_SLOT

	# Allow the dock to be on the left or right of the editor, and to be made floating.
	dock.available_layouts = AVAILABLE_DOCK_LAYOUTS

	add_dock(dock)
	
	print_rich("[color=green]✓ [b][KayKit Import Helper][/b] Dock initialized successfully[/color]")

func _erase_dock() -> void:
	# Remove the dock.
	remove_dock(dock)
	# Erase the control from the memory.
	dock.queue_free()
	
	print_rich("[color=green]✓ [b][KayKit Import Helper][/b] Dock erased successfully[/color]")

func _handle_reimport_request(settings: Dictionary[String, bool]) -> void:
	print_rich("[color=green]✓ [b][KayKit Import Helper][/b] Reimport requested with settings: %s [/color]" % settings)
