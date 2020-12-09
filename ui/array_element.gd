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
class_name TemplateElement

onready var tag_value: ColumnTag = $panel/hbox/tagval

var value_type: int = appstate.ColumnValueType.VT_String

func _ready() -> void:
	tag_value.set_data("Drop column here", -1, false)


func get_column_index() -> int:
	return tag_value.get_column_index()


func set_value_type(vt: int) -> void:
	value_type = vt


func calculate_output(cols: PoolStringArray, bindent: String, ilevel: int) -> String:
	var indent: String = build_indent(bindent, ilevel)
	var col: int = get_column_index()
	if (col < 0):
		return ""
	
	return build_value(cols[col], value_type, indent)


func get_template_type() -> String:
	return "element"

func generate_extra_data(out: Dictionary) -> void:
	out["value_type"] = value_type
	out["column"] = tag_value.get_column_index()
	out["calias"] = tag_value.get_column_name()


func restore_extra_data(d: Dictionary) -> void:
	set_value_type(d.value_type)
	tag_value.set_data(d.calias, d.column, false)


func _on_bt_remove_pressed() -> void:
	remove_itself()
