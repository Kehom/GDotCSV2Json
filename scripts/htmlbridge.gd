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
# Please not that a lot of what is found here is based on code from Pixelorama project:
# https://github.com/Orama-Interactive/Pixelorama
#
# Pixelorama is provided under the MIT license
#
# This should be added as an AutoLoad script
# None of the functions here will do anything if not running in HTML

extends Node


#######################################################################################################################
### Signals and definitions
signal focus_in
signal data_loaded(contents)

#######################################################################################################################
### "Public" properties


#######################################################################################################################
### "Public" functions
func load_csv() -> void:
	JavaScript.eval("load_csv()", true)
	
	yield(self, "focus_in")
	
	yield(get_tree().create_timer(0.5), "timeout")
	
	if (JavaScript.eval("canceled", true)):
		return
	
#	var loaded: String = ""
#	while (true):
#		# Request the data. It might not be fully loaded yet, meaning that this might return null
#		loaded = JavaScript.eval("file_data", true)
#		if (!loaded.empty()):
#			break
#
#		# If here, then no data has been loaded yet. Give some more time
#		yield(get_tree().create_timer(0.5), "timeout")
	# Keep this as a variant as it might return null or a String
	var ldata
	while (true):
		ldata = JavaScript.eval("file_data", true)
		
		if (ldata):
			break
		
		yield(get_tree().create_timer(0.5), "timeout")
	
	emit_signal("data_loaded", ldata)
	
	#emit_signal("data_loaded", loaded)
	#print("Data has been loaded...")
	#JavaScript.eval("console.log('TESTING)", true)
	#JavaScript.eval("console.log(%s)" % loaded)




#######################################################################################################################
### "Private" definitions


#######################################################################################################################
### "Private" properties


#######################################################################################################################
### "Private" functions
func _create_functions() -> void:
	assert(OS.get_name() == "HTML5" && OS.has_feature("JavaScript"))
	
	# TODO: (Properly) Handle the 'onerror' event of the file reader.
	
	JavaScript.eval("""
	var canceled;
	var file_data;
	var file_type;
	var file_name;
	
	function load_csv() {
		canceled = true;
		
		var input = document.createElement('input');
		input.setAttribute('type', 'file');
		input.setAttribute('accept', '.csv, .txt');
		input.click();
		
		input.addEventListener('change', evt => {
			if (evt.target.files.length > 0) {
				canceled = false;
			}
			
			var file = event.target.files[0];
			var reader = new FileReader();
			file_type = file.type;
			file_name = file.name;
			reader.readAsText(file);
			reader.onloadend = function(evt) {
				file_data = reader.result;
			}
			reader.onerror = function(evt) {
				console.log('Failed to load the file...');
				file_data = '';
			}
		});
	}
	""", true)




#######################################################################################################################
### Event handlers


#######################################################################################################################
### Overrides
func _notification(what: int) -> void:
	if (what == NOTIFICATION_WM_FOCUS_IN):
		emit_signal("focus_in")

func _ready() -> void:
	if (OS.get_name() == "HTML5" && OS.has_feature("JavaScript")):
		_create_functions()

