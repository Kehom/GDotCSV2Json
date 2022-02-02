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

# When creating the output template, instances of this scene will be created in order to represet the desired JSON keys.


extends TemplateBase
class_name TemplateKey


#######################################################################################################################
### Signals and definitions


#######################################################################################################################
### "Public" properties
# The name of the key. This will be directly used within the output as long as it's not empty
var key_name: String = "" setget set_key_name

# Tell which type should be used when to output the value. It's take from the ColumnValueType enum defined in the
# appstate.gd script. String will be used when no type get assigned.
var value_type: int = appstate.ColumnValueType.VT_String setget set_value_type


# Hold a reference to the scope node if this key is set to be object or array
var scope_node: Node = null


onready var column_tag: ColumnTag = $panel/vbox/hbox/column_tag
onready var txt_key: LineEdit = $panel/vbox/hbox/txt_key
onready var drop_vtype: DropValueType = $panel/vbox/hbox/drop_vtype
onready var scope_holder: HBoxContainer = $panel/vbox/scope_holder

#######################################################################################################################
### "Public" functions
func set_column(alias: String, index: int) -> void:
	column_tag.set_data(alias, index, false)


func set_key_name(n: String) -> void:
	key_name = n
	if (txt_key):
		txt_key.text = n


func set_value_type(vt: int) -> void:
	value_type = vt
	if (drop_vtype):
		drop_vtype.selected = vt

#######################################################################################################################
### "Private" definitions


#######################################################################################################################
### "Private" properties


#######################################################################################################################
### "Private" functions
func _check_ui_visibility() -> void:
	if (scope_node):
		scope_node.set_show_self_remove(false)
	
	scope_holder.visible = (scope_node != null)
	column_tag.visible = (scope_node == null)


func _clear_scope_node() -> void:
	if (scope_node):
		scope_holder.remove_child(scope_node)
		scope_node.queue_free()
		scope_node = null


func _on_bt_remove_pressed() -> void:
	remove_itself()

#######################################################################################################################
### Event handlers
func _on_txt_key_text_changed(new_text: String) -> void:
	key_name = new_text
	appstate.notify_changes()



func _on_drop_vtype_item_selected(index: int) -> void:
	value_type = index
	
	# If a change occurs, the scope holder has to be cleared, no matter what change is done
	_clear_scope_node()
	
	
	match value_type:
		appstate.ColumnValueType.VT_Int, appstate.ColumnValueType.VT_Float, appstate.ColumnValueType.VT_String:
			# Maybe there is nothing to do here....
			pass
		
		appstate.ColumnValueType.VT_Array:
			scope_node = appstate.template_array_t.instance()
			scope_holder.add_child(scope_node)
		
		appstate.ColumnValueType.VT_Map:
			scope_node = appstate.template_object_t.instance()
			scope_holder.add_child(scope_node)
	
	_check_ui_visibility()
	
	appstate.notify_changes()

#######################################################################################################################
### Overrides
func calculate_output(columns: PoolStringArray, bindent: String, ilevel: int) -> String:
	if (key_name.empty()):
		return ""
	
	var col: int = column_tag.get_column_index()
	
	if (col < 0 && !scope_node):
		return ""
	
	var indent: String = build_indent(bindent, ilevel)
	
	var ret: String = indent + "[color=#9CDCFE]\"%s\"[/color]: "
	
	if (scope_node):
		if (scope_node.has_method("calculate_output")):
			ret += scope_node.calculate_output(columns, bindent, ilevel)
		else:
			ret = ""
	
	else:
		ret += build_value(columns[col], value_type, "")
	
	return ret % key_name


func get_template_type() -> String:
	return "key"

func generate_extra_data(out: Dictionary) -> void:
	out["name"] = key_name
	out["value_type"] = value_type
	if (!scope_node):
		out["column"] = column_tag.get_column_index()
		out["calias"] = column_tag.get_column_name()

func get_template_children() -> Array:
	var ret: Array = []
	if (scope_node):
		ret.append(scope_node)
	return ret


func restore_extra_data(d: Dictionary) -> void:
	set_key_name(d.name)
	set_value_type(d.value_type)
	if (d.has("column")):
		column_tag.set_data(d.calias, d.column, false)


func add_restored_child(c: TemplateBase) -> void:
	scope_holder.add_child(c)
	scope_node = c
	_check_ui_visibility()

