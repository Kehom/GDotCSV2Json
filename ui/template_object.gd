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

extends TemplateBase
class_name TemplateObject


#######################################################################################################################
### Signals and definitions


#######################################################################################################################
### "Public" properties
onready var key_holder: VBoxContainer = $panel/vbox/srow/key_holder

#######################################################################################################################
### "Public" functions
func add_key(kname: String, col_alias: String, column: int, type: int) -> void:
	var nkey: TemplateBase = appstate.template_key_t.instance()
	
	key_holder.add_child(nkey)
	nkey.set_column(col_alias, column)
	nkey.key_name = kname
	nkey.value_type = type


func set_show_self_remove(e: bool) -> void:
	$panel/vbox/frow/bt_remove.visible = e

#######################################################################################################################
### "Private" definitions


#######################################################################################################################
### "Private" properties


#######################################################################################################################
### "Private" functions


#######################################################################################################################
### Event handlers
func _on_bt_addkey_pressed() -> void:
	add_key("NewKey", "Drop column here", -1, appstate.ColumnValueType.VT_String)
	


func _on_bt_remove_pressed() -> void:
	remove_itself()

#######################################################################################################################
### Overrides
func calculate_output(columns: PoolStringArray, bindent: String, ilevel: int) -> String:
	var indent: String = build_indent(bindent, ilevel)
	
	var ret: String = indent + "{"
	var need_comma: bool = false
	for key in key_holder.get_children():
		var kval: String = key.calculate_output(columns, bindent, ilevel + 1)
		
		if (!kval.empty()):
			if (need_comma):
				ret += ","
			else:
				need_comma = true
			
			ret += kval
	
	ret += indent + "}"
	
	return ret


func get_template_type() -> String:
	return "object"


func get_template_children() -> Array:
	return key_holder.get_children()


func add_restored_child(c: TemplateBase) -> void:
	key_holder.add_child(c)

