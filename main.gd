# Copyright (c) 2020 Yuri Sarudiansky
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


const column_tag_t: PackedScene = preload("res://ui/column_tag.tscn")


# Some "shortcuts" to some nodes, which will make access a little easier.
onready var drop_frow: OptionButton = $splitter/left/vbox/frowsetting/drop_frow
onready var drop_indent: OptionButton = $splitter/right/indentsetting/drop_indent
onready var txt_indent: SpinBox = $splitter/right/indentsetting/txt_indentsize

onready var vbox_columns: VBoxContainer = $splitter/left/vbox/hbox_vars/vbox_clist/scrl_columns/vbox

onready var root_scope: TemplateBase = $splitter/left/vbox/scrl_template/vbox/root_scope


onready var rtext_preview: RichTextLabel = $splitter/right/rich_preview


# Cache number of columns within the CSV file. Not entirely necessary but make coding slightly easier
var _col_count: int = 0


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
	
	# FIXME: This is only valid if the root_scope is indeed a TemplateArray
	root_scope.set_array_type(appstate.ColumnValueType.VT_Map)
	root_scope.set_csv_source(true)
	
	_calculate_output()



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




func _on_bt_loadcsv_pressed() -> void:
	$dlg_loadcsv.popup_centered()



func _on_dlg_loadcsv_file_selected(path: String) -> void:
	var file: File = File.new()
	
	var res: int = file.open(path, File.READ)
	if (res != OK):
		# TODO: proper error message
		print("failed to open file. Code = ", res)
		return
	
	# Will be used to parse things
	var separator: String = $dlg_loadcsv.get_separator()
	# Reset cached file data array
	appstate.file_data = []
	
	# Read first line which will determine number of columns and, obviously, how things will be parsed later
	var pline: PoolStringArray = file.get_csv_line(separator)
	appstate.file_data.append(pline)
	_col_count = pline.size()
	
	# Now read the rest of the file
	while (!file.eof_reached()):
		pline = file.get_csv_line(separator)
		
		if (pline.size() == _col_count):
			appstate.file_data.append(pline)
	
	file.close()
	
	
	_build_column_list()
	
	if ($dlg_loadcsv.rebuild_column_map()):
		_build_auto_template()
	
	_calculate_output()


func _on_bt_save_pressed() -> void:
	if (rtext_preview.text.empty()):
		return
	
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
	$dlg_savetemplate.popup_centered()


func _on_dlg_savetemplate_file_selected(path: String) -> void:
	var outdict: Dictionary = {
		"template_v": 1,
		
		"root": {}
	}
	
	root_scope.generate_save_template(outdict.root)
	
	var ofile: File = File.new()
	if (ofile.open(path, File.WRITE) != OK):
		# TODO: proper error message
		print("Failed to create output template file")
		return
	
	ofile.store_string(JSON.print(outdict))
	
	ofile.close()


func _on_bt_loadtemplate_pressed() -> void:
	$dlg_loadtemplate.popup_centered()


func _on_dlg_loadtemplate_file_selected(path: String) -> void:
	var infile: File = File.new()
	if (infile.open(path, File.READ) != OK):
		# TODO: proper error message
		print("Failed to open output template file")
		return
	
	var jpres: JSONParseResult = JSON.parse(infile.get_as_text())
	
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
	
	# At this point assuming every entry is in the correct format
	if (root.type == "array"):
		# NOTE: the code here will be necessary when support for custom root format is added.
		if (!root_scope):
			pass
		elif (root_scope is TemplateObject):
			pass
		
		
	
	elif (root.type == "object"):
		pass
	
	root_scope.restore_from_template(root, ver)
	
	_calculate_output()



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

