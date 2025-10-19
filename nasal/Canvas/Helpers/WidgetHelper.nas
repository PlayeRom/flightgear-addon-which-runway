#
# Which Runway Add-on for FlightGear
#
# Written and developer by Roman Ludwicki (PlayeRom, SP-ROM)
#
# Copyright (C) 2025 Roman Ludwicki
#
# Which Runway is an Open Source project and it is licensed
# under the GNU Public License v3 (GPLv3)
#

#
# General helper class for create Canvas Widgets.
#
var WidgetHelper = {
    #
    # Constructor.
    #
    # @param  ghost  context  Canvas parent.
    # @return void
    #
    new: func(context) {
        return {
            parents: [
                WidgetHelper,
            ],
            _context: context,
        };
    },

    #
    # Create Label widget.
    #
    # @param  string  text
    # @param  bool  wordWrap
    # @param  string|nil  align
    # @return ghost  Label widget.
    #
    getLabel: func(text, wordWrap = false, align = nil) {
        var label = canvas.gui.widgets.Label.new(parent: me._context, cfg: { wordWrap: wordWrap })
            .setText(text);

        if (align != nil) {
            label.setTextAlign(align);
        }

        return label;
    },

    #
    # Create Button widget.
    #
    # @param  string  text  Label of button.
    # @param  func|nil  callback  Function which will be executed after click the button.
    # @param  int|nil  width  Width of the button. If nil then size will not be set.
    # @return ghost  Button widget.
    #
    getButton: func(text, callback = nil, width = nil) {
        var btn = canvas.gui.widgets.Button.new(me._context)
            .setText(text);

        if (callback) {
            btn.listen("clicked", callback);
        }

        if (width) {
            btn.setFixedSize(width, 26);
        }

        return btn;
    },

    #
    # Create CheckBox widget.
    #
    # @param  string  text
    # @param  bool  isChecked
    # @param  func  callback
    # @return ghost  CheckBox widget.
    #
    getCheckBox: func(text, isChecked, callback) {
        return canvas.gui.widgets.CheckBox.new(me._context)
            .setText(text)
            .setChecked(isChecked)
            .listen("toggled", callback);
    },

    #
    # Get RadioButton widget.
    #
    # @param  string  text  Label text.
    # @param  hash|nil  cfg  Config hash or nil.
    # @return ghost  RadioButton widget.
    #
    getRadioButton: func(text, cfg = nil) {
        return canvas.gui.widgets.RadioButton.new(parent: me._context, cfg: cfg)
            .setText(text);
    },

    #
    # Create LineEdit widget.
    #
    # @param  string  text
    # @param  int|nil  width
    # @param  func|nil  callback
    # @return ghost  LineEdit widget.
    #
    getLineEdit: func(text = "", width = nil, callback = nil) {
        var input = canvas.gui.widgets.LineEdit.new(me._context)
            .setText(text);

        if (callback) {
            input.listen("editingFinished", callback);
        }

        if (width) {
            input.setFixedSize(width, 26);
        }

        return input;
    },

    #
    # Create horizontal rule.
    #
    # @return ghost  HorizontalRule widget.
    #
    getHorizontalRule: func() {
        return canvas.gui.widgets.HorizontalRule.new(me._context);
    },
};
