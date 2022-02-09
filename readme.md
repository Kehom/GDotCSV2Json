# GDotCSV2JSON

This is a free, open source, CSV to JSON converter, powered by [Godot engine](https://godotengine.org/) ([Github repository](https://github.com/godotengine/godot)]).

This application does not enforce a "one to one mapping", that is, each column in the CSV generates a key in the resulting JSON file. Instead you can create a template that will be followed when generating the output.

Besides Windows and Linux binaries that can be found in the [Releases](https://github.com/Kehom/GDotCSV2Json/releases) section, there is a web version that can be accessed at https://kehom.github.io/csvtojson/


### Output Template

How exactly the output will be like relies on the output template. This template can be easily manipulated by adding/removing entries. Columns are mapped into keys by simply dragging a column tag from the list into the corresponding key. Column tags are generated once a CSV file is loaded.

An output template can be automatically generated when a CSV file is loaded by simply keeping the `Auto build template on load` checked (it's bellow the load button). If this option is disabled and you want the automatic template to be generated, just click the `Auto` button that is just above the template area.

Templates can be saved for future uses, which can be very useful if it isn't a "one to one" mapping and the source data may change, requiring further conversions.


### Not So Comma Separated

For some reason certain applications use `;` instead of `,` when exporting the spreadsheet into a "comma" separated value format. To deal with such cases, you can determine what is the separator by changing the character in the `Column separator` setting (near the top section of the left panel).

### First Row is Of Valid Values

Some CSV files have all "valid data", without any "header" within the first row, indicating what each column is. This kind of file can be dealt with by simply changing a drop down option within the main application window and should immediately update the output in case a CSV file has already been loaded.

### Spacing Tabs

Some people prefer to indent using spaces. Other people prefer to indent using tabs. You can choose whichever you prefer through a drop down menu above the output preview. You can even choose no indenting, which will basically place the entire output into a single line.

### Finally Saving

Use the output preview to ensure the result is as expected. If it is, finally generate the JSON file by clicking the "save" button and specifying its path and name.
