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

# Visually represent the output template for JSON Arrays

extends TemplateBase
class_name TemplateArray


#######################################################################################################################
### Signals and definitions


#######################################################################################################################
### "Public" properties
export var show_self_remove: bool = true


onready var element_holder: VBoxContainer = $panel/vbox/srow/element_holder
onready var drop_arrtype: OptionButton = $panel/vbox/frow/drop_arrtype
onready var chk_csvsource: CheckBox = $panel/vbox/frow/chk_csvsource

#######################################################################################################################
### "Public" functions
func set_array_type(tp: int) -> void:
	drop_arrtype.selected = tp
	# Unfortunately the previous line does not trigger the item selected signal. So, manually calling it
	_on_drop_arrtype_item_selected(tp)


func add_object() -> TemplateBase:
	if (_arr_type != appstate.ColumnValueType.VT_Map):
		return null
	
	var ret: TemplateBase = appstate.template_object_t.instance()
	element_holder.add_child(ret)
	
	return ret


func set_show_self_remove(e: bool) -> void:
	show_self_remove = e
	$panel/vbox/frow/bt_remarray.visible = e


func set_csv_source(e: bool) -> void:
	$panel/vbox/frow/chk_csvsource.pressed = e



#######################################################################################################################
### "Private" definitions


#######################################################################################################################
### "Private" properties
# Must cache the selected array type. The thing is, a few tests are necessary to be performed when a new type is
# selected. By the time the signal function is run, the selected property will already be updated and the old value
# must be used as part of the tests
var _arr_type: int = appstate.ColumnValueType.VT_String

# Cache if this array is holding simple elements (int, float or array) or complex elements (array or object)
var _is_scope: bool = false

#######################################################################################################################
### "Private" functions
func _calculate_output(cols: PoolStringArray, bindent: String, ilevel: int) -> String:
	var ret: String = ""
	
	var need_comma: bool = false
	
	for el in element_holder.get_children():
		var val: String = el.calculate_output(cols, bindent, ilevel)
		
		if (!val.empty()):
			if (need_comma):
				ret += ","
			else:
				need_comma = true
			
			ret += val
	
	return ret

#######################################################################################################################
### Event handlers
func _on_drop_arrtype_item_selected(index: int) -> void:
	var oldscope: bool = (_arr_type == appstate.ColumnValueType.VT_Array || _arr_type == appstate.ColumnValueType.VT_Map)
	var newscope: bool = (index == appstate.ColumnValueType.VT_Array || index == appstate.ColumnValueType.VT_Map)
	
	# In here a change of the array types occurred. There is no need to clear the children nodes if previously on non
	# complex values (string, int, float). However, if moving complex <-> simple does require this kind of cleanup.
	# And, if moving from array to object the cleanup is also required because the child node that will be created
	# when clicking the "add" button will depend on the selected type.
	if (newscope || oldscope != newscope):
		# The held elements are fundementally different, so must delete all of them
		appstate.clear_node_children(element_holder)
	
	_arr_type = index
	_is_scope = newscope
	
	if (!_is_scope):
		# In here it's relatively safe to directly call "set_value_type". If there are children in here then those are
		# indeed of ArrayElement type.
		for el in element_holder.get_children():
			el.set_value_type(index)


func _on_bt_addelement_pressed() -> void:
	if (_is_scope):
		var nel: TemplateBase = null
		if (_arr_type == appstate.ColumnValueType.VT_Array):
			nel = appstate.template_array_t.instance()
		elif (_arr_type == appstate.ColumnValueType.VT_Map):
			nel = appstate.template_object_t.instance()
		
		if (nel):
			element_holder.add_child(nel)
	
	else:
		# Just add one instance of the ArrayElement
		var ael: TemplateBase = appstate.template_element_t.instance()
		element_holder.add_child(ael)

func _on_bt_remarray_pressed() -> void:
	remove_itself()


#######################################################################################################################
### Overrides
func calculate_output(columns: PoolStringArray, bindent: String, ilevel: int) -> String:
	var indent: String = build_indent(bindent, ilevel)
	
	var ret: String = indent + "["
	
	if (chk_csvsource.pressed):
		var need_comma: bool = false
		for line in range(appstate.first_valid, appstate.file_data.size()):
			var l: String = _calculate_output(appstate.file_data[line], bindent, ilevel + 1)
			if (!l.empty()):
				if (need_comma):
					ret += ","
				else:
					need_comma = true
			ret += l
	
	else:
		# Using a "custom source" for the erray elements. So directly build the output using the incomming columns
		ret += _calculate_output(columns, bindent, ilevel + 1)
	
	if (!bindent.empty() && ilevel == 0):
		ret += "\n"
	
	ret += indent + "]"
	
	return ret


func clear_template() -> void:
	appstate.clear_node_children(element_holder)


func get_template_type() -> String:
	return "array"


func generate_extra_data(out: Dictionary) -> void:
	out["array_type"] = _arr_type
	out["csv_source"] = chk_csvsource.pressed


func get_template_children() -> Array:
	return element_holder.get_children()


func restore_extra_data(d: Dictionary) -> void:
	_arr_type = d.array_type
	drop_arrtype.selected = _arr_type
	chk_csvsource.pressed = d.csv_source


func add_restored_child(c: TemplateBase) -> void:
	element_holder.add_child(c)


func _ready() -> void:
	if (!show_self_remove):
		$panel/vbox/frow/bt_remarray.visible = false
		$panel/vbox/frow/drop_arrtype.visible = false

