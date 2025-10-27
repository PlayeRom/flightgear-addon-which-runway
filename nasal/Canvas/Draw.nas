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
        var obj = {
            parents: [
                Draw,
            ],
            _content: canvasContent,

        };

        obj._fontSansBold = canvas.font_mapper("sans", "bold");

        return obj;
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
    # @param  double  x  Init position of x.
    # @param  double  y  Init position of y.
    # @param  ghost  airport  Airport object from airportinfo.
    # @return hash  New position of x, y and last used canvas text element.
    #
    printLineAirportName: func(x, y, airport) {
        var text = me.createText(airport.id ~ " – " ~ airport.name)
            .setTranslation(x, y)
            .setColor(canvas.style.getColor("text_color"))
            .setFontSize(24)
            .setFont(me._fontSansBold);

        return {
            x: x,
            y: text.getSize()[1] + Draw.MARGIN_Y,
            text: text,
        };
    },

    #
    # @param  double  x  Init position of x.
    # @param  double  y  Init position of y.
    # @param  string  label  Label text.
    # @param  string|int|double  value  Value to display.
    # @param  string|nil  unit  Unit to display.
    # @param  vector|nil  color  RGB color or default if nil.
    # @return hash  New position of x, y and last used canvas text element.
    #
    printLineWithValue: func(x, y, label, value, unit = nil, color = nil) {
        var text = me.createText(label)
            .setTranslation(x, y)
            .setColor(color == nil ? canvas.style.getColor("text_color") : color);

        x += Draw.VALUE_MARGIN_X;
        text = me.createText(value)
            .setTranslation(x, y)
            .setColor(color == nil ? canvas.style.getColor("text_color") : color)
            .setFont(me._fontSansBold);

        if (unit != nil) {
            x += text.getSize()[0] + 5;
            text = me.createText(unit)
                .setTranslation(x, y)
                .setColor(color == nil ? canvas.style.getColor("text_color") : color);
        }

        return {
            x: x,
            y: text.getSize()[1] + Draw.MARGIN_Y,
            text: text,
        };
    },

    #
    # @param  double  x  Init position of x.
    # @param  double  y  Init position of y.
    # @param  string  label  Label text.
    # @param  string|int|double  value1  First value to display.
    # @param  string  unit1  First unit to display.
    # @param  string|int|double  value2  Second value to display.
    # @param  string  unit2  Second unit to display.
    # @return hash  New position of x, y and last used canvas text element.
    #
    printLineWith2Values: func(x, y, label, value1, unit1, value2, unit2) {
        var res = me.printLineWithValue(x, y, label, value1, unit1 ~ " /");

        x = res.x + res.text.getSize()[0] + 5;
        text = me.createText(value2)
            .setTranslation(x, y)
            .setColor(canvas.style.getColor("text_color"))
            .setFont(me._fontSansBold);

        x += text.getSize()[0] + 5;
        text = me.createText(unit2)
            .setTranslation(x, y)
            .setColor(canvas.style.getColor("text_color"));

        return {
            x: x,
            y: text.getSize()[1] + Draw.MARGIN_Y,
            text: text,
        };
    },

    #
    # @param  double  x  Init position of x.
    # @param  double  y  Init position of y.
    # @param  string  label  Label text.
    # @param  hash  pressValues  Atmospheric pressure with 3 value: mmHg, hPa, inHg.
    # @return hash  New position of x, y and last used canvas text element.
    #
    printLineAtmosphericPressure: func(x, y, label, pressValues) {
        var text = me.createText(label)
            .setTranslation(x, y)
            .setColor(canvas.style.getColor("text_color"));

        # inHg
        x += Draw.VALUE_MARGIN_X;
        text = me.createText(sprintf("%.02f", pressValues.inHg))
            .setTranslation(x, y)
            .setColor(canvas.style.getColor("text_color"))
            .setFont(me._fontSansBold);

        x += text.getSize()[0] + 5;
        text = me.createText("inHg /")
            .setTranslation(x, y)
            .setColor(canvas.style.getColor("text_color"));

        # hPa
        x += 82;
        text = me.createText(pressValues.hPa)
            .setTranslation(x, y)
            .setColor(canvas.style.getColor("text_color"))
            .setFont(me._fontSansBold)
            .setAlignment("right-baseline");

        x += 5;
        text = me.createText("hPa /")
            .setTranslation(x, y)
            .setColor(canvas.style.getColor("text_color"));

        # mmHg
        x += 42;
        text = me.createText(pressValues.mmHg)
            .setTranslation(x, y)
            .setColor(canvas.style.getColor("text_color"))
            .setFont(me._fontSansBold);

        x += text.getSize()[0] + 5;
        text = me.createText("mmHg")
            .setTranslation(x, y)
            .setColor(canvas.style.getColor("text_color"));

        return {
            x: x,
            y: text.getSize()[1] + Draw.MARGIN_Y,
            text: text,
        };
    },

    #
    # @param  double  x  Init position of x.
    # @param  double  y  Init position of y.
    # @param  string  label  Label text.
    # @return hash  New position of x, y and last used canvas text element.
    #
    printLineWind: func(x, y, label) {
        var text = me.createText(label)
            .setTranslation(x, y)
            .setColor(Colors.BLUE)
            .setFontSize(20)
            .setFont(me._fontSansBold);

        return {
            x: x,
            y: text.getSize()[1] + Draw.MARGIN_Y,
            text: text,
        };
    },

    #
    # @param  string  message  Message text.
    # @param  bool  isError  If true then message is error message (red color).
    # @param  int  fontSize
    # @return ghost  Canvas text element.
    #
    printMessage: func(message, isError = false, fontSize = 20) {
        return me.createText(message)
            .setTranslation(0, 0)
            .setColor(isError ? Colors.RED : canvas.style.getColor("text_color"))
            .setFontSize(fontSize);
    },
};
