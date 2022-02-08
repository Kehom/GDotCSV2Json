# Copyright (c) 2022 Yuri Sarudiansky
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

tool
extends Container
class_name FlowContainer

#######################################################################################################################
### Signals and definitions


#######################################################################################################################
### "Public" properties


#######################################################################################################################
### "Public" functions
func set_horizontal_separation(val: int) -> void:
	_hsep = val
	if (_hsep < 0):
		_hsep = 0
	
	queue_sort()


func set_vertical_separation(val: int) -> void:
	_vsep = val
	if (_vsep < 0):
		_vsep = 0
	
	queue_sort()


#######################################################################################################################
### "Private" definitions
class LineEntry extends Reference:
	var ctrl: Control
	
	func hor_expand() -> bool:
		return (ctrl.size_flags_horizontal & Control.SIZE_EXPAND != 0)
	
	func ver_expand() -> bool:
		return (ctrl.size_flags_vertical & Control.SIZE_EXPAND != 0)


class LineInfo extends Reference:
	# Instances of LineEntry (see class above this one)
	var entry: Array = []
	
	# Hold the height of this line
	var height: int = 0
	
	# Hold the "width" of this line. Well, the total space used by controls within this line without considering any
	# stretching caused by the horizontal expand flag.
	var width: int = 0
	
	# How many controls have the horizontal expand flag set.
	var hexpand_count: int = 0
	
	
	func add_entry(ctrl: Control, minsize: Vector2, space: int) -> void:
		height = int(max(minsize.y, height))
		width += int(minsize.x) + space
		
		var ne: LineEntry = LineEntry.new()
		ne.ctrl = ctrl
		
		entry.append(ne)
		
		if (ne.hor_expand()):
			hexpand_count += 1


#######################################################################################################################
### "Private" properties
var _cache_min_width: int = 0
var _cache_min_height: int = 0

# Will be exposed through the _get_property_list() functionality
var _hsep: int = 4
var _vsep: int = 6

#######################################################################################################################
### "Private" functions


#######################################################################################################################
### Event handlers


#######################################################################################################################
### Overrides
func _notification(what: int) -> void:
	# Go through children twice. First to scan and calculate the required space
	# Then perform the actual positioning of the children
	if (what == NOTIFICATION_SORT_CHILDREN):
		var line_data: Array = []
		
		var cx: int = 0
		var cline: LineInfo = null
		var space: int = 0
		_cache_min_width = 0
		_cache_min_height = 0
		
		for c in get_children():
			if (!(c is Control)):
				continue
			
			var ctrl: Control = c
			if (!ctrl || !ctrl.is_visible_in_tree()):
				continue
			
			var ms: Vector2 = ctrl.get_combined_minimum_size()
			
			_cache_min_width = int(max(_cache_min_width, ms.x))
			
			if (cx + space + ms.x > rect_size.x || !cline):
				cline = LineInfo.new()
				line_data.append(cline)
				
				cx = 0
				space = 0
			
			
			cline.add_entry(ctrl, ms, space)
			space = _hsep
			cx += space + int(ms.x)
		
		
		# Children have been "scanned". In which x coordinates they should be placed is known. The y coordinate is almost
		# know as their lines have already been calculated too. Perform this positioning now
		var cy: int = 0
		for l in line_data:
			var line: LineInfo = l
			
			# Obtain available space on this line for stretching (in case any control does have Expand in its horizontal size flags).
			var available: int = int(rect_size.x - line.width)
			
			# This space should be evenly distributed into the controls with the expand flag within this line
			# warning-ignore:integer_division
			var stretch: int = int(available / line.hexpand_count) if line.hexpand_count > 0 else 0
			
			cx = 0
			
			for le in line.entry:
				var entry: LineEntry = le
				
				var size: Vector2 = entry.ctrl.get_combined_minimum_size()
				
				if (entry.hor_expand()):
					size.x += stretch
				
				if (entry.ver_expand()):
					size.y = line.height
				
				var vcenter: int = int((line.height - size.y) * 0.5)
				
				fit_child_in_rect(entry.ctrl, Rect2(Vector2(cx, cy + vcenter), size))
				
				cx += int(size.x + _hsep)
			
			
			cy += line.height + _vsep
			_cache_min_height += line.height
		
		_cache_min_height += (line_data.size() - 1) * _vsep
	
	
	
	rect_min_size = Vector2(_cache_min_width, _cache_min_height)


# Exposing properties like this so those can be categorized. Unfortunately default value assign button is lost in the process
func _get_property_list() -> Array:
	var ret: Array = []
	
	ret.append({
		"name": "separation/horizontal",
		"type": TYPE_INT,
	})
	
	ret.append({
		"name": "separation/vertical",
		"type": TYPE_INT,
	})
	
	return ret


func _set(pname: String, val) -> bool:
	var ret: bool = true
	
	match pname:
		"separation/horizontal":
			set_horizontal_separation(val)
		
		"separation/vertical":
			set_vertical_separation(val)
		
		_:
			ret = false
	
	return ret


func _get(pname):
	match pname:
		"separation/horizontal":
			return _hsep
		
		"separation/vertical":
			return _vsep
	
	return null
