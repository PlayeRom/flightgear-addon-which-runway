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
    VALUE_MARGIN_X: 110, # the distance of the value from the label.

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

    #
    # @param  string|nil  text
    # @param  vector|nil  RGB color.
    # @return ghost  Text canvas element for label.
    #
    createTextLabel: func(text = nil, color = nil) {
        return me.createText(text)
            .setColor(color == nil ? whichRunway.Colors.DEFAULT_TEXT : color);
    },

    #
    # @param  string|nil  text
    # @param  vector|nil  RGB color.
    # @return ghost  Text canvas element for value.
    #
    createTextValue: func(text = nil, color = nil) {
        return me.createText(text)
            .setColor(color == nil ? whichRunway.Colors.DEFAULT_TEXT : color)
            .setFont(whichRunway.Fonts.SANS_BOLD);
    },

    #
    # @param  string|nil  text
    # @param  vector|nil  RGB color.
    # @return ghost  Text canvas element for unit.
    #
    createTextUnit: func(text = nil, color = nil) {
        return me.createText(text)
            .setColor(color == nil ? whichRunway.Colors.DEFAULT_TEXT : color);
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
};
