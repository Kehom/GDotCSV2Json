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

extends VBoxContainer
class_name TemplateBase



func calculate_output(_columns: PoolStringArray, _bindent: String, _ilevel: int) -> String:
	return ""

func clear_template() -> void:
	pass


func format_str_str(val: String, indent: String) -> String:
	return (indent + "[color=#C49166]\"%s\"[/color]") % val



func format_str_int(val: String, indent: String) -> String:
	if (val.is_valid_integer()):
		return (indent + "[color=#A7CE9B]%d[/color]") % val.to_int()
	
	return format_str_str(val, indent)


func format_str_float(val: String, indent: String) -> String:
	if (val.is_valid_float()):
		return (indent + "[color=#A7CE9B]%f[/color]") % val.to_float()
	
	return format_str_str(val, indent)


func build_value(val: String, tp: int, indent: String) -> String:
	var ret: String = ""
	
	match tp:
		appstate.ColumnValueType.VT_Int:
			ret += format_str_int(val, indent)
		
		appstate.ColumnValueType.VT_Float:
			ret += format_str_float(val, indent)
		
		appstate.ColumnValueType.VT_String:
			ret += format_str_str(val, indent)
	
	return ret




func build_indent(base: String, level: int) -> String:
	if (!base.empty() && level > 0):
		return "\n" + base.repeat(level)
	
	return ""



func remove_itself() -> void:
	var parent: Node = get_parent_control()
	if (!parent):
		return
	
	parent.remove_child(self)
	queue_free()
	
	appstate.notify_changes()



func generate_save_template(out: Dictionary) -> void:
	out["type"] = get_template_type()
	generate_extra_data(out)
	
	var children: Array = get_template_children()
	if (children.size() > 0):
		out["children"] = []
		
		for child in children:
			var cout: Dictionary = {}
			child.generate_save_template(cout)
			out.children.append(cout)



# Derived classes must override these in order to properly generate the template files
func get_template_type() -> String:
	return ""

func generate_extra_data(_out: Dictionary) -> void:
	pass

func get_template_children() -> Array:
	return []


func restore_from_template(data: Dictionary, version: int) -> void:
	restore_extra_data(data)
	
	clear_template()
	
	if (data.has("children")):
		for child in data.children:
			var ps: PackedScene = appstate.get_scene_by_serialized_type(child.type)
			if (ps):
				var cnode: VBoxContainer = ps.instance()
				add_restored_child(cnode)
				if (cnode.is_inside_tree()):
					cnode.restore_from_template(child, version)




func restore_extra_data(_d: Dictionary) -> void:
	pass

# NOTE: The idea here was to static type the argument to TemplateBase. However it resulted in resource leak error
# messages upon exiting the app. So, leaving this as variant
func add_restored_child(_c) -> void:
	pass

