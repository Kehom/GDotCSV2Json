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

# Some general data and state that must be shared throughout the app


extends Node

signal settings_changed

const template_array_t: PackedScene = preload("res://ui/template_array.tscn")
const template_object_t: PackedScene = preload("res://ui/template_object.tscn")
const template_key_t: PackedScene = preload("res://ui/template_key.tscn")
const template_element_t: PackedScene = preload("res://ui/array_element.tscn")

const column_tag_t: PackedScene = preload("res://ui/column_tag.tscn")



### Some options that will be identified by "constant integers"
enum ColumnValueType {
	VT_Int,
	VT_Float,
	VT_String,
	VT_Array,
	VT_Map,
}

enum FirstRowType {
	FRT_Skip,
	FRT_ValidData,
}

enum IndentType {
	IT_None,
	IT_Space,
	IT_Tab,
}



var file_data: Array = []
var first_valid: int = 0


### Mapping those options to text that will be displayed within the UI.
# TODO: Load text from translation files
onready var column_type_map: Dictionary = {
	ColumnValueType.VT_Int: "Int",
	ColumnValueType.VT_Float: "Float",
	ColumnValueType.VT_String: "String",
	ColumnValueType.VT_Array: "Array",
	ColumnValueType.VT_Map: "Object",
}

onready var first_row_map: Dictionary = {
	FirstRowType.FRT_Skip: "Header",
	FirstRowType.FRT_ValidData: "Valid data",
}

onready var indent_type: Dictionary = {
	IndentType.IT_None: "None",
	IndentType.IT_Space: "Space",
	IndentType.IT_Tab: "Tab"
}


# Clear all children from the specified node.
static func clear_node_children(node: Node) -> void:
	for child in node.get_children():
		# First remove from the node itself so the nodes are not accessible when iterating right after calling this function
		node.remove_child(child)
		# And mark the child node to be deleted
		child.queue_free()


func fill_value_type_drop_down(ddown: OptionButton) -> void:
	for vtype in column_type_map:
		ddown.add_item(column_type_map[vtype], vtype)



# Instead of having several signals within controls, which will also be added into another controls, causing some sort
# of a nightmare to manage signal connections, this function will be called whenenver a change that affects the output
# occurs. Then, the main.gd script will only hve to connect into a single signal defined within this state script.
func notify_changes() -> void:
	emit_signal("settings_changed")


func get_scene_by_serialized_type(tp: String) -> PackedScene:
	var ret: PackedScene = null
	match tp:
		"array":
			ret = template_array_t
		"object":
			ret = template_object_t
		"key":
			ret = template_key_t
		"element":
			ret = template_element_t
	
	return ret
