# Save this as: addons/sprite_sheet_generator/sprite_sheet_dock.gd
@tool
extends Control

# UI Elements
var input_folder_line: LineEdit
var output_path_line: LineEdit
var images_per_row_spin: SpinBox
var padding_spin: SpinBox
var cell_width_spin: SpinBox
var cell_height_spin: SpinBox
var auto_size_check: CheckBox
var background_color_picker: ColorPicker
var transparent_bg_check: CheckBox
var generate_button: Button
var browse_input_button: Button
var browse_output_button: Button
var progress_bar: ProgressBar
var log_text: TextEdit

# File dialog
var file_dialog: FileDialog

func _init():
	name = "Sprite Sheet Generator"
	custom_minimum_size = Vector2(280, 600)
	_create_ui()

func _create_ui():
	var vbox = VBoxContainer.new()
	add_child(vbox)
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	# Title
	var title = Label.new()
	title.text = "Sprite Sheet Generator"
	title.add_theme_font_size_override("font_size", 16)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)
	
	vbox.add_child(HSeparator.new())
	
	# Input folder section
	var input_label = Label.new()
	input_label.text = "Input Folder:"
	vbox.add_child(input_label)
	
	var input_hbox = HBoxContainer.new()
	vbox.add_child(input_hbox)
	
	input_folder_line = LineEdit.new()
	input_folder_line.text = "res://images/"
	input_folder_line.placeholder_text = "res://path/to/images/"
	input_hbox.add_child(input_folder_line)
	
	browse_input_button = Button.new()
	browse_input_button.text = "Browse"
	browse_input_button.pressed.connect(_on_browse_input_pressed)
	input_hbox.add_child(browse_input_button)
	
	# Output path section
	var output_label = Label.new()
	output_label.text = "Output Path:"
	vbox.add_child(output_label)
	
	var output_hbox = HBoxContainer.new()
	vbox.add_child(output_hbox)
	
	output_path_line = LineEdit.new()
	output_path_line.text = "res://sprite_sheet.png"
	output_path_line.placeholder_text = "res://output.png"
	output_hbox.add_child(output_path_line)
	
	browse_output_button = Button.new()
	browse_output_button.text = "Browse"
	browse_output_button.pressed.connect(_on_browse_output_pressed)
	output_hbox.add_child(browse_output_button)
	
	vbox.add_child(HSeparator.new())
	
	# Layout settings
	var layout_label = Label.new()
	layout_label.text = "Layout Settings:"
	layout_label.add_theme_font_size_override("font_size", 14)
	vbox.add_child(layout_label)
	
	# Images per row
	var row_container = _create_labeled_spinbox("Images per Row:", 1, 20, 1, 4)
	images_per_row_spin = row_container.get_child(1)
	vbox.add_child(row_container)
	
	# Padding
	var padding_container = _create_labeled_spinbox("Padding (px):", 0, 50, 1, 2)
	padding_spin = padding_container.get_child(1)
	vbox.add_child(padding_container)
	
	# Auto size checkbox
	auto_size_check = CheckBox.new()
	auto_size_check.text = "Auto Size (use largest image)"
	auto_size_check.button_pressed = true
	auto_size_check.toggled.connect(_on_auto_size_toggled)
	vbox.add_child(auto_size_check)
	
	# Manual cell size (initially disabled)
	var width_container = _create_labeled_spinbox("Cell Width:", 1, 2048, 1, 64)
	cell_width_spin = width_container.get_child(1)
	cell_width_spin.editable = false
	vbox.add_child(width_container)
	
	var height_container = _create_labeled_spinbox("Cell Height:", 1, 2048, 1, 64)
	cell_height_spin = height_container.get_child(1)
	cell_height_spin.editable = false
	vbox.add_child(height_container)
	
	vbox.add_child(HSeparator.new())
	
	# Background settings
	var bg_label = Label.new()
	bg_label.text = "Background:"
	bg_label.add_theme_font_size_override("font_size", 14)
	vbox.add_child(bg_label)
	
	transparent_bg_check = CheckBox.new()
	transparent_bg_check.text = "Transparent Background"
	transparent_bg_check.button_pressed = true
	transparent_bg_check.toggled.connect(_on_transparent_bg_toggled)
	vbox.add_child(transparent_bg_check)
	
	var color_label = Label.new()
	color_label.text = "Background Color:"
	vbox.add_child(color_label)
	
	background_color_picker = ColorPicker.new()
	background_color_picker.color = Color.BLACK
	background_color_picker.custom_minimum_size = Vector2(250, 150)
	background_color_picker.visible = false
	vbox.add_child(background_color_picker)
	
	vbox.add_child(HSeparator.new())
	
	# Generate button
	generate_button = Button.new()
	generate_button.text = "Generate Sprite Sheet"
	generate_button.add_theme_font_size_override("font_size", 14)
	generate_button.pressed.connect(_on_generate_pressed)
	vbox.add_child(generate_button)
	
	# Progress bar
	progress_bar = ProgressBar.new()
	progress_bar.visible = false
	vbox.add_child(progress_bar)
	
	vbox.add_child(HSeparator.new())
	
	# Log section
	var log_label = Label.new()
	log_label.text = "Log:"
	vbox.add_child(log_label)
	
	log_text = TextEdit.new()
	log_text.custom_minimum_size = Vector2(250, 120)
	log_text.editable = false
	log_text.placeholder_text = "Generation log will appear here..."
	vbox.add_child(log_text)
	
	# Clear log button
	var clear_button = Button.new()
	clear_button.text = "Clear Log"
	clear_button.pressed.connect(_clear_log)
	vbox.add_child(clear_button)

func _create_labeled_spinbox(label_text: String, min_val: float, max_val: float, step: float, default_val: float) -> HBoxContainer:
	var container = HBoxContainer.new()
	
	var label = Label.new()
	label.text = label_text
	label.custom_minimum_size.x = 120
	container.add_child(label)
	
	var spinbox = SpinBox.new()
	spinbox.min_value = min_val
	spinbox.max_value = max_val
	spinbox.step = step
	spinbox.value = default_val
	container.add_child(spinbox)
	
	return container

func _on_browse_input_pressed():
	_show_file_dialog(FileDialog.FILE_MODE_OPEN_DIR, _on_input_folder_selected)

func _on_browse_output_pressed():
	_show_file_dialog(FileDialog.FILE_MODE_SAVE_FILE, _on_output_path_selected)

func _show_file_dialog(mode: FileDialog.FileMode, callback: Callable):
	if file_dialog:
		file_dialog.queue_free()
	
	file_dialog = FileDialog.new()
	get_tree().root.add_child(file_dialog)
	file_dialog.file_mode = mode
	file_dialog.access = FileDialog.ACCESS_RESOURCES
	
	if mode == FileDialog.FILE_MODE_SAVE_FILE:
		file_dialog.add_filter("*.png", "PNG Images")
	
	file_dialog.popup_centered(Vector2i(800, 600))
	file_dialog.file_selected.connect(callback)
	file_dialog.dir_selected.connect(callback)

func _on_input_folder_selected(path: String):
	input_folder_line.text = path + "/"

func _on_output_path_selected(path: String):
	output_path_line.text = path

func _on_auto_size_toggled(pressed: bool):
	cell_width_spin.editable = not pressed
	cell_height_spin.editable = not pressed

func _on_transparent_bg_toggled(pressed: bool):
	background_color_picker.visible = not pressed

func _on_generate_pressed():
	_clear_log()
	_log("Starting sprite sheet generation...")
	
	progress_bar.visible = true
	progress_bar.value = 0
	generate_button.disabled = true
	
	await get_tree().process_frame
	
	var success = await _generate_sprite_sheet()
	
	progress_bar.visible = false
	generate_button.disabled = false
	
	if success:
		_log("✓ Sprite sheet generated successfully!")
	else:
		_log("✗ Failed to generate sprite sheet.")

func _generate_sprite_sheet() -> bool:
	var input_folder = input_folder_line.text
	var output_path = output_path_line.text
	
	# Validate input
	if input_folder.is_empty() or output_path.is_empty():
		_log("Error: Input folder and output path are required.")
		return false
	
	if not input_folder.ends_with("/"):
		input_folder += "/"
	
	var dir = DirAccess.open(input_folder)
	if dir == null:
		_log("Error: Could not open directory: " + input_folder)
		return false
	
	# Get all image files
	var image_files = []
	dir.list_dir_begin()
	var file_name = dir.get_next()
	
	while file_name != "":
		if not dir.current_is_dir():
			var extension = file_name.get_extension().to_lower()
			if extension in ["png", "jpg", "jpeg", "bmp", "tga", "webp"]:
				image_files.append(file_name)
		file_name = dir.get_next()
	
	if image_files.is_empty():
		_log("No image files found in: " + input_folder)
		return false
	
	image_files.sort()
	_log("Found %d image files" % image_files.size())
	
	progress_bar.value = 10
	await get_tree().process_frame
	
	# Load images
	var images = []
	var max_width = 0
	var max_height = 0
	
	for i in range(image_files.size()):
		var file = image_files[i]
		var image = Image.new()
		var error = image.load(input_folder + file)
		
		if error != OK:
			_log("Warning: Could not load " + file)
			continue
		
		images.append(image)
		max_width = max(max_width, image.get_width())
		max_height = max(max_height, image.get_height())
		_log("Loaded: %s (%dx%d)" % [file, image.get_width(), image.get_height()])
		
		progress_bar.value = 10 + (i * 40 / image_files.size())
		await get_tree().process_frame
	
	if images.is_empty():
		_log("No valid images to process")
		return false
	
	# Calculate dimensions
	var cell_width = max_width
	var cell_height = max_height
	
	if not auto_size_check.button_pressed:
		cell_width = int(cell_width_spin.value)
		cell_height = int(cell_height_spin.value)
	
	var images_per_row = int(images_per_row_spin.value)
	var padding = int(padding_spin.value)
	var rows = ceil(float(images.size()) / images_per_row)
	
	var sheet_width = (cell_width + padding) * images_per_row - padding
	var sheet_height = (cell_height + padding) * rows - padding
	
	_log("Creating sprite sheet: %dx%d" % [sheet_width, sheet_height])
	_log("Grid: %d columns x %d rows" % [images_per_row, rows])
	_log("Cell size: %dx%d" % [cell_width, cell_height])
	
	progress_bar.value = 60
	await get_tree().process_frame
	
	# Create sprite sheet
	var sprite_sheet = Image.create(sheet_width, sheet_height, false, Image.FORMAT_RGBA8)
	
	var bg_color = Color.TRANSPARENT
	if not transparent_bg_check.button_pressed:
		bg_color = background_color_picker.color
	
	sprite_sheet.fill(bg_color)
	
	# Place images
	for i in range(images.size()):
		var image = images[i]
		var col = i % images_per_row
		var row = i / images_per_row
		
		var x_offset = col * (cell_width + padding) + (cell_width - image.get_width()) / 2
		var y_offset = row * (cell_height + padding) + (cell_height - image.get_height()) / 2
		
		sprite_sheet.blit_rect(image, Rect2i(0, 0, image.get_width(), image.get_height()), Vector2i(x_offset, y_offset))
		
		progress_bar.value = 60 + (i * 30 / images.size())
		await get_tree().process_frame
	
	# Save sprite sheet
	var save_error = sprite_sheet.save_png(output_path)
	progress_bar.value = 100
	
	if save_error != OK:
		_log("Error saving sprite sheet: " + str(save_error))
		return false
	
	_log("Saved to: " + output_path)
	_log("\n--- Animation Info ---")
	_log("Frame size: %dx%d" % [cell_width, cell_height])
	_log("Frames per row: %d" % images_per_row)
	_log("Total frames: %d" % images.size())
	_log("Padding: %d pixels" % padding)
	
	return true

func _log(message: String):
	log_text.text += message + "\n"
	log_text.scroll_vertical = log_text.get_line_count()

func _clear_log():
	log_text.text = ""

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		if file_dialog:
			file_dialog.queue_free()