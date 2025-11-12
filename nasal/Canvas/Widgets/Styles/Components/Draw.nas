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
    SHIFT_X: 5,
    SHIFT_Y: 10,

    #
    # Constructor.
    #
    # @param  ghost  canvasContent  Canvas object where we will be drawn.
    # @param  string|nil  fontSansBold
    # @return hash
    #
    new: func(canvasContent, fontSansBold = nil) {
        return {
            parents: [Draw],
            _content: canvasContent,
            _fontSansBold: fontSansBold or canvas.font_mapper("sans", "bold"),
        };
    },

    #
    # Destructor.
    #
    # @return void
    #
    del: func {
    },

    #
    # @return ghost  Canvas content.
    #
    _getContent: func {
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
    createPath: func {
        return me._getContent().createChild("path");
    },

    #
    # Create and return canvas SVG element.
    #
    # @param  string  file  SVG file path relative to FGData directory.
    # @return ghost  Canvas SVG element.
    #
    createSvg: func(file) {
        var svgImg = me._getContent().createChild("group");
        canvas.parsesvg(svgImg, file);

        return svgImg;
    },

    #
    # @param  ghost  textElement
    # @param  int|nil  extraShift  If nil then Draw.SHIFT_X is set.
    # @return double
    #
    shiftX: func(textElement, extraShift = nil) {
        if (extraShift == nil) {
            extraShift = Draw.SHIFT_X;
        }

        return textElement.getSize()[0] + extraShift;
    },

    #
    # @param  ghost  textElement
    # @param  int|nil  extraShift  If nil then Draw.SHIFT_Y is set.
    # @return double
    #
    shiftY: func(textElement, extraShift = nil) {
        if (extraShift == nil) {
            extraShift = Draw.SHIFT_Y;
        }

        return textElement.getSize()[1] + extraShift;
    },

    #
    # @param  string|nil  text
    # @param  vector|nil  color  RGB color.
    # @return ghost  Text canvas element for label.
    #
    createTextLabel: func(text = nil, color = nil) {
        return me.createText(text)
            .setColor(color or style.getColor("text_color"));
    },

    #
    # @param  string|nil  text
    # @param  vector|nil  color  RGB color.
    # @return ghost  Text canvas element for value.
    #
    createTextValue: func(text = nil, color = nil) {
        return me.createText(text)
            .setColor(color or style.getColor("text_color"))
            .setFont(me._fontSansBold);
    },

    #
    # @param  string|nil  text
    # @param  vector|nil  color  RGB color.
    # @return ghost  Text canvas element for unit.
    #
    createTextUnit: func(text = nil, color = nil) {
        return me.createText(text)
            .setColor(color or style.getColor("text_color"));
    },

    #
    # @param  double  y  Initial Y position.
    # @param  vector  elements  Array of canvas element.
    # @param  double  valueMarginX
    # @param  bool  isLast
    # @return double  New Y position.
    #
    setTextTranslations: func(y, elements, valueMarginX, isLast = false) {
        var x = 0;
        var index = 0;
        var lastText = nil;

        foreach (var elem; elements) {
            if (index == 1) {
                x += valueMarginX;
            } elsif (index > 1) {
                x += me.shiftX(lastText);
            }

            elem.setTranslation(x, y);

            lastText = elem;
            index += 1;
        }

        return me.shiftY(lastText, isLast ? 0 : Draw.SHIFT_Y);
    },
};
