#
# Which runway - Add-on for FlightGear
#
# Written and developer by Roman Ludwicki (PlayeRom, SP-ROM)
#
# Copyright (C) 2025 Roman Ludwicki
#
# Which Runway is an Open Source project and it is licensed
# under the GNU Public License v3 (GPLv3)
#

#
# Helper class for draw in canvas content.
#
var Draw = {
    #
    # Constants:
    #
    MARGIN_Y      : 10,
    VALUE_MARGIN_X: 110,

    #
    # Constructor.
    #
    # @param  ghost  canvasContent  Canvas object where we will be drawn.
    # @return hash
    #
    new: func(canvasContent) {
        var me = { parents: [Draw] };

        me._content = canvasContent;

        return me;
    },

    #
    # Destructor.
    #
    # @return void
    #
    del: func() {
    },

    #
    # @return ghost  Canvas content.
    #
    _getContent: func() {
        return me._content;
    },

    #
    # Create and return canvas text element.
    #
    # @param  string|nil  text
    # @return ghost  Canvas text element.
    #
    createText: func(text = nil) {
        var element = me._getContent().createChild("text");

        if (text != nil) {
            element.setText(text);
        }

        return element;
    },

    #
    # Create and return canvas path element.
    #
    # @return ghost  Canvas path element.
    #
    createPath: func() {
        return me._getContent().createChild("path");
    },

    #
    # @param  ghost  textElement
    # @return double
    #
    shiftX: func(textElement) {
        return textElement.getSize()[0] + 5;
    },

    #
    # @param  ghost  textElement
    # @return double
    #
    shiftY: func(textElement, multiplier = 1) {
        return textElement.getSize()[1] + (Draw.MARGIN_Y * multiplier);
    },

    createTextLabel: func(x, y, text = nil) {
        return me.createText(text)
            .setTranslation(x, y)
            .setColor(whichRunway.Colors.DEFAULT_TEXT);
    },

    createTextValue: func(x, y, text = nil) {
        return me.createText(text)
            .setTranslation(x, y)
            .setColor(whichRunway.Colors.DEFAULT_TEXT)
            .setFont(whichRunway.Fonts.SANS_BOLD);
    },

    createTextUnit: func(x, y, text = nil) {
        return me.createText(text)
            .setTranslation(x, y)
            .setColor(whichRunway.Colors.DEFAULT_TEXT);
    },

    #
    # @param  double  y  Initial Y position.
    # @param  vector  array  Array of text element.
    # @return double  New Y position.
    #
    setTextTranslations: func(y, array) {
        var x = 0;
        var index = 0;
        var lastText = nil;

        foreach (var textElem; array) {
            if (index == 1) {
                x += Draw.VALUE_MARGIN_X;
            } elsif (index > 1) {
                x += me.shiftX(lastText);
            }

            textElem.setTranslation(x, y);

            lastText = textElem;
            index += 1;
        }

        return me.shiftY(lastText);
    },

    #
    # As parameters you pass the vector of objects: { text: canvas, value: value, unit: canvas|nil  }
    # and so on.
    #
    # @return void
    #
    setValuesForLine: func() {
        var count = size(arg);
        var x = Draw.VALUE_MARGIN_X;

        for (var i = 0; i < count; i += 1) {
            var param = arg[i];

            if (i > 0) {
                # shift value text:
                var lastText = arg[i - 1].unit == nil
                    ? arg[i - 1].text
                    : arg[i - 1].unit;

                var (tX, tY) = lastText.getTranslation();
                x += me.shiftX(lastText);

                param.text.setTranslation(x, tY);
            }

            param.text.setText(param.value);

            if (param.unit != nil) {
                # shift unit text:
                var (tX, tY) = param.unit.getTranslation();
                x += me.shiftX(param.text);
                param.unit.setTranslation(x, tY);
            }
        }
    },
};
