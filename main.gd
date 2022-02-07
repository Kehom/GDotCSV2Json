# Copyright (c) 2020-2022 Yuri Sarudiansky
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

extends CanvasLayer

#######################################################################################################################
### Signals and definitions
const column_tag_t: PackedScene = preload("res://ui/column_tag.tscn")

#######################################################################################################################
### "Public" properties
# Some "shortcuts" to some nodes, which will make access a little easier.
onready var drop_frow: OptionButton = $splitter/left/vbox/frowsetting/drop_frow
onready var drop_indent: OptionButton = $splitter/right/indentsetting/drop_indent
onready var txt_indent: SpinBox = $splitter/right/indentsetting/txt_indentsize

onready var vbox_columns: VBoxContainer = $splitter/left/vbox/hbox_vars/vbox_clist/scrl_columns/vbox

onready var root_scope: TemplateBase = $splitter/left/vbox/scrl_template/vbox/root_scope


onready var rtext_preview: RichTextLabel = $splitter/right/rich_preview

#######################################################################################################################
### "Public" functions


#######################################################################################################################
### "Private" definitions


#######################################################################################################################
### "Private" properties
# This will be used to parse the loaded data. Yes, Godot does offer a very useful way to perform this parsing
# when directly loading data from files. However the HTML export can't use this feature. To keep the results
# consistent, all the parsing will be performed by this thing
var _csvparser: CSVParser = CSVParser.new()

# Cache the loaded CSV data. This will allow easier changing of the "column separator" without having to reload
# data from the file
var _loaded_csv: String = ""

# Cache number of columns within the CSV file. Not entirely necessary but make coding slightly easier
var _col_count: int = 0

#######################################################################################################################
### "Private" functions
func _build_column_list() -> void:
	# Ensure the column container is empty
	appstate.clear_node_children(vbox_columns)
	
	# Check what first row is meant to be first to avoid branching multiple times. Yes, this will lead to iteration
	# code twice.
	if (drop_frow.selected == appstate.FirstRowType.FRT_Skip):
		# First row is set to "header". Use the values of that as column aliases
		var cols: PoolStringArray = appstate.file_data[0]
		for i in _col_count:
			var bt: ColumnTag = column_tag_t.instance()
			bt.set_data(cols[i], i, true)
			vbox_columns.add_child(bt)
	
	elif (drop_frow.selected == appstate.FirstRowType.FRT_ValidData):
		for i in _col_count:
			var bt: ColumnTag = column_tag_t.instance()
			bt.set_data("", i, true)
			vbox_columns.add_child(bt)



func _build_auto_template() -> void:
	root_scope.clear_template()
	
	var mainobj: TemplateObject = root_scope.add_object()
	
	
	# The ColumnTag nodes within the vbox_columns are already with the correct key names for this case. So, iterate
	# through those and retrieve the data from the nodes
	for ctag in vbox_columns.get_children():
		# The automatic template will always output values as strings
		mainobj.add_key(ctag.get_column_name(), ctag.get_column_name(), ctag.get_column_index(), appstate.ColumnValueType.VT_String)




func _calculate_output() -> void:
	appstate.first_valid = 0 if drop_frow.selected == appstate.FirstRowType.FRT_ValidData else 1
	
	var bindent: String = _get_base_indent()
	var output: String = "[code]"
	
	output += root_scope.calculate_output(PoolStringArray(), bindent, 0)
	
	output += "[/code]"
	
	rtext_preview.bbcode_text = output


func _get_base_indent() -> String:
	var ret: String = ""
	
	match drop_indent.selected:
		appstate.IndentType.IT_Space:
			var count: int = int(txt_indent.value)
			ret = " ".repeat(count)
		
		appstate.IndentType.IT_Tab:
			ret = "	"
	
	return ret


func _parse_csv(auto_template: bool) -> void:
	if (_loaded_csv.empty()):
		return
	
	# Ensure the CSV parser is "not done"
	_csvparser.reset()
	
	# Reset cached parsed lines
	appstate.file_data = []
	
	# Read first line which will determine number of columns and, obviously, how things will be parsed later
	var pline: PoolStringArray = _csvparser.get_csv_line(_loaded_csv)
	appstate.file_data.append(pline)
	_col_count = pline.size()
	
	# Now parse the rest of the data
	while (!_csvparser.done()):
		pline = _csvparser.get_csv_line(_loaded_csv)
		
		if (pline.size() == _col_count):
			appstate.file_data.append(pline)
	
	_build_column_list()
	
	if (auto_template):
		_build_auto_template()
	
	_calculate_output()


func _get_template_out_data() -> String:
	var out_dict: Dictionary = {
		"template_v": 1,
		"root": {},
	}
	
	root_scope.generate_save_template(out_dict.root)
	
	return JSON.print(out_dict)




func _load_template(data: String) -> void:
	var jpres: JSONParseResult = JSON.parse(data)
	
	if (jpres.error != OK):
		# TODO: proper error message
		return
	
	if (jpres.result is Array):
		return
	
	if (!jpres.result.has("template_v")):
		return
	
	if (!jpres.result.has("root")):
		return
	
	var ver: int = jpres.result.template_v
	var root: Dictionary = jpres.result.root
	
	if (root.type == "array"):
		# NOTE: Code in here currently doesn't do anything, but will be necessary when support for custom root format is added.
		if (!root_scope):
			pass
		
		elif(root_scope is TemplateObject):
			pass
	
	elif (root.type == "object"):
		pass
	
	root_scope.restore_from_template(root, ver)
	
	_calculate_output()




#######################################################################################################################
### Event handlers

func _on_bt_loadcsv_pressed() -> void:
	if (OS.get_name() != "HTML5"):
		$dlg_loadcsv.popup_centered()
	
	else:
		if (OS.has_feature("JavaScript")):
			htmlbridge.load_csv()
			
		
		else:
			# TODO: Display error message telling that the running thing doesn't have JavaScript
			
			pass



func _on_dlg_loadcsv_file_selected(path: String) -> void:
	var file: File = File.new()
	
	var res: int = file.open(path, File.READ)
	if (res != OK):
		# TODO: proper error message
		print("failed to open file. Code = ", res)
		return
	
	_loaded_csv = file.get_as_text()
	file.close()
	
	_parse_csv(true)



func _on_data_loaded_from_html(data: String) -> void:
	_loaded_csv = data
	_parse_csv(true)



func _on_bt_save_pressed() -> void:
	if (rtext_preview.text.empty()):
		return
	
	if (OS.get_name() == "HTML5"):
		if (OS.has_feature("JavaScript")):
			JavaScript.download_buffer(rtext_preview.text.to_utf8(), "output.json", "application/json")
		
		else:
			# TODO: Display an error message
			# Running in HTML5 but there is no JavaScript.
			pass
	
	else:
		$dlg_saveoutput.popup_centered()


func _on_dlg_saveoutput_file_selected(path: String) -> void:
	var file: File = File.new()
	var res: int = file.open(path, File.WRITE)
	if (res != OK):
		# TODO: proper error message
		print("Failed to create output file.")
		return
	
	file.store_string(rtext_preview.text)



func _on_drop_frow_item_selected(_index: int) -> void:
	_calculate_output()



func _on_bt_savetemplate_pressed() -> void:
	if (OS.get_name() == "HTML5"):
		if (OS.has_feature("JavaScript")):
			JavaScript.download_buffer(_get_template_out_data().to_utf8(), "template.json", "application/json")
		
		else:
			# TODO: proper error message here - In HTML but without JavaScript
			pass
	
	else:
		$dlg_savetemplate.popup_centered()


func _on_dlg_savetemplate_file_selected(path: String) -> void:
	var ofile: File = File.new()
	if (ofile.open(path, File.WRITE) != OK):
		# TODO: proper error message
		print("Failed to create output template file")
		return
	
	ofile.store_string(_get_template_out_data())
	
	ofile.close()


func _on_bt_loadtemplate_pressed() -> void:
	if (OS.get_name() == "HTML5"):
		if (OS.has_feature("JavaScript")):
			htmlbridge.load_template()
		
		else:
			# TODO: Display an error message
			pass
	
	else:
		$dlg_loadtemplate.popup_centered()




func _on_dlg_loadtemplate_file_selected(path: String) -> void:
	var infile: File = File.new()
	if (infile.open(path, File.READ) != OK):
		# TODO: proper error message
		print("Failed to open output template file")
		return
	
	_load_template(infile.get_as_text())



func _on_bt_auto_pressed() -> void:
	_build_auto_template()
	_calculate_output()



func _on_txt_delimiter_text_changed(new_text: String) -> void:
	_csvparser.set_delimiter(new_text)
	_parse_csv(false)
	var txt: LineEdit = $splitter/left/vbox/buttons/txt_delimiter as LineEdit
	if (txt):
		txt.call_deferred("select_all")


func _on_txt_delimiter_focus_entered() -> void:
	var txt: LineEdit = $splitter/left/vbox/buttons/txt_delimiter as LineEdit
	if (txt):
		txt.call_deferred("select_all")


func _on_drop_indent_item_selected(index: int) -> void:
	if (index == appstate.IndentType.IT_Space):
		txt_indent.editable = true
	else:
		txt_indent.editable = false
	
	_calculate_output()


func _on_txt_indentsize_value_changed(_value: float) -> void:
	_calculate_output()


func _on_splitter_dragged(offset: int) -> void:
	if (offset < 300):
		var splitter: SplitContainer = $splitter
		splitter.split_offset = 300


#######################################################################################################################
### Overrides
func _unhandled_key_input(evt: InputEventKey) -> void:
	if (evt.is_pressed() && evt.scancode == KEY_F1):
		var l: Panel = $splitter/left
		print(l.rect_size)
		pass



func _ready() -> void:
	# Fill the drop down menus
	for i in appstate.first_row_map:
		drop_frow.add_item(appstate.first_row_map[i], i)
	
	for i in appstate.indent_type:
		drop_indent.add_item(appstate.indent_type[i], i)
	
	# Autoselect space as ident type.
	# TODO: take this from a setting file
	drop_indent.selected = appstate.IndentType.IT_Space
	
	# Connect into the signal that will notfiy that something has changed and output must be recalculated
	# warning-ignore:return_value_discarded
	appstate.connect("settings_changed", self, "_calculate_output")
	
	if (OS.get_name() == "HTML5" && OS.has_feature("JavaScript")):
		# warning-ignore:return_value_discarded
		htmlbridge.connect("data_loaded", self, "_on_data_loaded_from_html")
		
		# warning-ignore:return_value_discarded
		htmlbridge.connect("template_loaded", self, "_load_template")
	
	
	# FIXME: This is only valid if the root_scope is indeed a TemplateArray
	root_scope.set_array_type(appstate.ColumnValueType.VT_Map)
	root_scope.set_csv_source(true)
	
	_calculate_output()


