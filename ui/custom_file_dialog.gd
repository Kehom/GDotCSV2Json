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

# Unfortunatelly to add custom controls to the file dialog we need to access the internal vertical box by calling
# get_vbox().add_child()
# This means that a script is necessary to perform this task.

tool        # Just so additional controls appear in the editor preview
extends FileDialog
class_name CustomFileDialog

const csv_separator_t: PackedScene = preload("res://ui/cdialog_separator.tscn")

var _txt_separator: LineEdit = null
var _chk_rebuild: CheckBox = null

func _ready() -> void:
	# Create the custom controls
	var sepnode: Node = csv_separator_t.instance()
	_chk_rebuild = CheckBox.new()
	# TODO: take text from translation file
	_chk_rebuild.text = "Rebuild column map template"
	# TODO: pressed state retrieved from settings - so, it will remember the last one used.
	_chk_rebuild.pressed = true
	
	# Add to the dialog
	get_vbox().add_child(sepnode)
	get_vbox().add_child(_chk_rebuild)
	
	# Cache some specific nodes
	_txt_separator = sepnode.get_node("hbox/txt_separator")
	
	
	# Finally, listen to events if necessary
	# warning-ignore:return_value_discarded
	_txt_separator.connect("focus_entered", self, "_on_separator_focus_entered")




func _on_separator_focus_entered() -> void:
	# For some reason, at this point control is still without focus meaning that directly calling "select_all()" will fail.
	# Postponing the call works.
	_txt_separator.call_deferred("select_all")



func get_separator() -> String:
	var ret: String = _txt_separator.text
	
	if (ret.empty()):
		ret = ","
	
	return ret


func rebuild_column_map() -> bool:
	return _chk_rebuild.pressed
