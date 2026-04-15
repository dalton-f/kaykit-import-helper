@tool
extends EditorPlugin

#region Constants
const PLUGIN_DIRECTORY_PATH: String = "res://addons/kaykit_import_helper/"
const PLUGIN_DOCK_SCENE_PATH: String = PLUGIN_DIRECTORY_PATH + "advanced_importer_dock/advanced_importer_dock.tscn"

const AVAILABLE_DOCK_LAYOUTS: int = EditorDock.DockLayout.DOCK_LAYOUT_VERTICAL | EditorDock.DockLayout.DOCK_LAYOUT_FLOATING
const DEFAULT_DOCK_SLOT: EditorDock.DockSlot = EditorDock.DockSlot.DOCK_SLOT_LEFT_UR
const DEFAULT_DOCK_TITLE: String = "Advanced Import"

const BASE_OUTPUT_DIRECTORY_PATH: String = "res://assets/"
const MATERIALS_OUTPUT_DIRECTORY_PATH: String = BASE_OUTPUT_DIRECTORY_PATH + "materials/"
const TEXTURES_OUTPUT_DIRECTORY_PATH: String = BASE_OUTPUT_DIRECTORY_PATH + "textures/"
const MODELS_OUTPUT_DIRECTORY_PATH: String = BASE_OUTPUT_DIRECTORY_PATH + "models/"
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
	
	_connect_signals()

# Clean-up of the plugin goes here.
func _exit_tree():
	_disconnect_signals()
		
	_erase_dock()
#endregion

#region Plugin Lifecycle
func _build_dock() -> void:
	# Load the dock scene and instantiate it.
	dock_scene = preload(PLUGIN_DOCK_SCENE_PATH).instantiate()

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

func _connect_signals() -> void:
	dock_scene.connect("reimport_requested", _handle_reimport_request)
	
	EditorInterface.get_file_system_dock().connect("selection_changed", _update_dock_state)
	
	print_rich("[color=green]✓ [b][KayKit Import Helper][/b] Signals connected successfully[/color]")

func _disconnect_signals() -> void:
	dock_scene.disconnect("reimport_requested", _handle_reimport_request)
	
	EditorInterface.get_file_system_dock().disconnect("selection_changed", _update_dock_state)
	
	print_rich("[color=green]✓ [b][KayKit Import Helper][/b] Signals disconnected successfully[/color]")

func _update_dock_state() -> void:
	pass
#endregion

func _handle_reimport_request(settings: Dictionary[String, bool]) -> void:
	print_rich("[color=green]✓ [b][KayKit Import Helper][/b] Reimport requested with settings: %s [/color]" % settings)

	await _build_output_directories()
	
	print_rich("[color=green]✓ [b][KayKit Import Helper][/b] Reimport successfully completed with settings: %s [/color]" % settings)

func _build_output_directories() -> void:
	var output_directory_paths = [MATERIALS_OUTPUT_DIRECTORY_PATH, TEXTURES_OUTPUT_DIRECTORY_PATH, MODELS_OUTPUT_DIRECTORY_PATH]

	for output_directory_path: String in output_directory_paths:
		_make_dir(output_directory_path)
	
	await _refresh_filesystem()
	
	print_rich("[color=green]✓ [b][KayKit Import Helper][/b] Built output directories successfully [/color]")

#region Utility Functions
# Refreshes the Godot editor filesystem
# Waits until scanning is fully complete before continuing
func _refresh_filesystem() -> void:
	var fs: EditorFileSystem = EditorInterface.get_resource_filesystem()
	
	# Start scanning the filesystem
	fs.scan() 
		
	# Wait until scanning finishes
	while fs.is_scanning():
		await fs.filesystem_changed
		
	# Wait one frame to ensure updates are applied
	await get_tree().process_frame

# Refreshes both source imports (e.g. textures, models) and filesystem
func _refresh_filesystem_and_imports() -> void:
	var fs: EditorFileSystem = EditorInterface.get_resource_filesystem()
	
	# Scan source files (triggers reimport if needed)
	fs.scan_sources() 
	
	# Wait until source scanning finishes
	while fs.is_scanning():
		await fs.sources_changed
	
	# Wait one frame to ensure updates are applied
	await get_tree().process_frame
	
	# Then refresh full filesystem
	fs.scan()
	
	# Wait until filesystem scanning finishes
	while fs.is_scanning():
		await fs.filesystem_changed
		
	# Wait one frame to ensure updates are applied	
	await get_tree().process_frame

# Returns only selected paths that are valid folders
func _get_selected_folders() -> Array:
	var folders: Array = []
	
	var selected_paths: PackedStringArray = EditorInterface.get_selected_paths()
	
	for path: String in selected_paths:
		# Check if the selected path is a directory
		if DirAccess.dir_exists_absolute(path):
			folders.append(path)
	
	return folders

# Opens a .import file (ConfigFile format) and returns it
# Returns null if loading fails
func _open_import_file(import_file_path: String) -> ConfigFile:
	var import_file: ConfigFile = ConfigFile.new()
	var error: Error = import_file.load(import_file_path)

	# Handle loading failure
	if error != Error.OK:
		push_error("✗ [KayKit Import Helper] Failed to open import file: %s" % import_file_path)
		return null

	return import_file

# Recursively collects files from a directory
# - extensions: optional filter (e.g. ["png", "jpg"])
# - scan_subfolders: whether to include subdirectories (currently always scans)
func _get_files(directory_path: String, extensions: Array = [], scan_subfolders: bool = false) -> Array:
	var results: Array = []
	
	var directory: DirAccess = DirAccess.open(directory_path)
	
	# If directory can't be opened, return empty list
	if directory == null:
		push_error("✗ [KayKit Import Helper] Failed to open directory: %s" % directory_path)
		return results
		
	# Initalize the stream used to list all files and folders using get_next()
	directory.list_dir_begin()
		
	var file_name: String = directory.get_next()
		
	while file_name != "":
		# Skip any hidden files or folders
		if file_name.begins_with("."):
			file_name = directory.get_next()
			continue
				
		var full_path = directory_path.path_join(file_name)
			
		# If it's a directory, recurse into it
		if directory.current_is_dir():
			var subfolder_results: Array = _get_files(full_path, extensions, scan_subfolders)
			results.append_array(subfolder_results)
		else:
			# Add file if it matches extensions or no filter is set
			if extensions.is_empty() or file_name.get_extension() in extensions:
				results.append(full_path)
				
		file_name = directory.get_next()
	
	# Close the stream
	directory.list_dir_end()

	return results

# Makes a directory if it doesn't already exist
func _make_dir(path: String) -> void:
	# If directory already exists, do nothing
	if DirAccess.dir_exists_absolute(path):
		return

	var err := DirAccess.make_dir_recursive_absolute(path)

	if err != OK:
		push_error("✗ [KayKit Import Helper] Failed to create directory: %s" % path)
		return 
#endregion
