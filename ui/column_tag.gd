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

# The column tag is a "button" that will be used to allow the user to drag into the template map. Basically this will
# tell which input column will be associated with which output key.

extends VBoxContainer
class_name ColumnTag


#######################################################################################################################
### Signals and definitions


#######################################################################################################################
### "Public" properties


#######################################################################################################################
### "Public" functions
func set_data(alias: String, index: int, list_only: bool) -> void:
	_alias = alias
	_index = index
	_list_only = list_only
	
	if (_alias.empty()):
		_alias = "Column_%d" % _index
	
	$panel/hbox/lbl_alias.text = _alias



func get_column_name() -> String:
	return _alias

func get_column_index() -> int:
	return _index




#######################################################################################################################
### "Private" definitions


#######################################################################################################################
### "Private" properties
# Name of the column that will be displayed in the UI.
var _alias: String
# Column index within the input CSV
var _index: int


var _list_only: bool = false


# If this is true then this is being used as a drag preview so don't return anything within the get_drag_data()
#var _is_preview: bool = false

#######################################################################################################################
### "Private" functions


#######################################################################################################################
### Event handlers


#######################################################################################################################
### Overrides
func get_drag_data(_pos: Vector2):
	if (_index < 0):
		return null
	
	set_drag_preview(duplicate())
	
	return {
		"alias": _alias,
		"index": _index,
		"columntag": true
	}

func can_drop_data(_pos: Vector2, data) -> bool:
	if (data is Dictionary && data.has("columntag")):
		return data.index != _index && !_list_only
	
	return false

func drop_data(_pos: Vector2, data) -> void:
	assert(data.has("columntag"))
	
	set_data(data.alias, data.index, false)
	appstate.notify_changes()

