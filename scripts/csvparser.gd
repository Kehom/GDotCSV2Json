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

# Yes, Godot does offer a very useful function to obtain parsed CSV lines from files. However, when
# loading data through HTML5, that functionality is not present because the used file reader is actually
# provided by the web browser in use. So, this script is used to perform this parsing, with the help
# of regular expressions.
# Note that two expressions are used here, one to match full lines and the other to parse each line.
# In theory it should be possible to use a single expression for this, however this is not exactly
# something in my skill set.
# That said, the parser expression has been taken from https://regex101.com/library/oU3yV6

extends Reference
class_name CSVParser

#######################################################################################################################
### Signals and definitions


#######################################################################################################################
### "Public" properties
var delimiter: String = "," setget set_delimiter

#######################################################################################################################
### "Public" functions
func reset() -> void:
	_offset = 0
	_done = false

func done() -> bool:
	return _done

func get_csv_line(data: String) -> PoolStringArray:
	var ret: PoolStringArray = PoolStringArray()
	
	if (!_reg_csv.is_valid()):
		_done = true
		return ret
	
	var line: RegExMatch = _reg_line.search(data, _offset)
	
	if (line):
		# The "strings" Array should have a single entry, which is the entire line
		assert(line.strings.size() == 1)
		
		# Advance the offset so next time this function is called the search will occur on the next line
		_offset = line.get_end() + 1
		_done = _offset >= data.length()
		
		var fields: Array = _reg_csv.search_all(line.strings[0])
		
		for f in fields:
			var rm: RegExMatch = f
			assert(rm.strings.size() == 1)
			
			var field: String = rm.strings[0]
			if (field[0] == "\""):
				# This field is enclosed in double quotes. Remove them
				field = field.substr(1, field.length() - 2)
			
			ret.append(field.strip_edges())
	
	
	return ret


func set_delimiter(val: String) -> void:
	if (val.empty()):
		delimiter = ","
	
	else:
		delimiter = val[0]
	
	if (delimiter.empty() || delimiter == " "):
		delimiter = ","
	
	_compile_parser()

#######################################################################################################################
### "Private" definitions
# The actual expression taken from the mentioned web site is: "(?:[^"]|"")*"|[^,\n]+|(?=,)(?<=,)|^|(?<=,)$
# The string bellow is used to help simply exchange the "," appropriate delimiter
const _base_expression: String = "\"(?:[^\"]|\"\")*\"|[^{delimiter}\n]+|(?=,)(?<=,)|^|(?<={delimiter})$"


#######################################################################################################################
### "Private" properties
var _reg_line: RegEx = RegEx.new()

var _reg_csv: RegEx = RegEx.new()

var _offset: int = 0
var _done: bool = false

#######################################################################################################################
### "Private" functions
func _compile_parser() -> void:
	if (_reg_csv.compile(_base_expression.format({"delimiter": delimiter})) != OK):
		pass

#######################################################################################################################
### Event handlers


#######################################################################################################################
### Overrides
func _init() -> void:
	# warning-ignore:return_value_discarded
	_reg_line.compile(".+")
	_compile_parser()
