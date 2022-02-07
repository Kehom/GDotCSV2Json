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

# The Web export is sandboxed in a way that the file dialog provided by Godot does not have access
# to the system paths. The result of this is that a save/load system becomes very limited.
# Luckily we can use the JavaScript class to execute and even "inject" script into the running HTML.
# By doing so it becomes possible to create functions that will "force" the web browser to prompt
# the user with the appropriate save/load dialog.
# The script here is meant to provide this "bridging" between Godot code and HTML
#
# This should be added as an AutoLoad script
# None of the functions here will do anything if not running in HTML

extends Node


#######################################################################################################################
### Signals and definitions
signal data_loaded(contents)
signal template_loaded(contents)

#######################################################################################################################
### "Public" properties


#######################################################################################################################
### "Public" functions
func load_csv() -> void:
	if (OS.get_name() == "HTML5" && OS.has_feature("JavaScript")):
		JavaScript.eval("loadCSV()")


func load_template() -> void:
	if (OS.get_name() == "HTML5" && OS.has_feature("JavaScript")):
		JavaScript.eval("loadTemplate()")



#######################################################################################################################
### "Private" definitions


#######################################################################################################################
### "Private" properties
# Callbacks must remain kept as valid references for as long as they can be called by JavaScript code. The properties
# bellow are meant to perform this task. However, since JavaScriptObject (or JavaScript itself) are not available on
# non HTML exports. Because of that those are not static typed here
var _csvloaded_callback = null

var _templateloaded_callback = null

#######################################################################################################################
### "Private" functions
func _on_csv_loaded_cb(args: Array) -> void:
	assert(args.size() == 1)
	emit_signal("data_loaded", args[0])


func _on_template_loaded_cb(args: Array) -> void:
	assert(args.size() == 1)
	emit_signal("template_loaded", args[0])


func _create_functions() -> void:
	assert(OS.get_name() == "HTML5" && OS.has_feature("JavaScript"))
	
	# Create the callbacks
	_csvloaded_callback = JavaScript.create_callback(self, "_on_csv_loaded_cb")
	_templateloaded_callback = JavaScript.create_callback(self, "_on_template_loaded_cb")
	
	
	# Obtain the objec that is meant to hold the functions - this "gdFuncs" object is defined within the front page
	var gdfuncs: JavaScriptObject = JavaScript.get_interface("gdFuncs")
	
	# Assign into the interface
	gdfuncs.csvLoaded = _csvloaded_callback
	gdfuncs.templateLoaded = _templateloaded_callback





#######################################################################################################################
### Event handlers


#######################################################################################################################
### Overrides
func _ready() -> void:
	if (OS.get_name() == "HTML5" && OS.has_feature("JavaScript")):
		_create_functions()
