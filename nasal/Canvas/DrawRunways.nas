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
# Class do draw runways with wind rose on canvas
#
var DrawRunways = {
    #
    # Constructor
    #
    # @param  ghost  canvas  Canvas object where runways will be drawn.
    # @param  ghost  wind  Wind object.
    # @return me
    #
    new: func(canvas, wind) {
        var me = { parents: [DrawRunways] };

        me._canvas = canvas;
        me._wind = wind;
        me._runwaysData = RunwaysData.new(wind);
        me._drawWindRose = DrawWindRose.new(canvas);

        return me;
    },

    #
    # Destructor
    #
    # @return void
    #
    del: func() {
        me._drawWindRose.del();
        me._runwaysData.del();
    },

    #
    # Draw runways information with wind rose.
    #
    # @param  int  y  Init position of y.
    # @param  ghost  airport
    # @return int  New position of y shifted by height of printed line.
    #
    drawRunways: func(y, airport) {
        var runwaysData = me._runwaysData.getRunways(airport);
        var roseRadius = 175;

        foreach (var rwy; runwaysData) {
            y += me._printRunwayLabel(0, y, rwy);

            var label = rwy.headwind < 0 ? "Tailwind:" : "Headwind:";
            y += me._printLineWithValue(0, y, label, math.round(math.abs(rwy.headwind)), "kts");

            var unit = "kts" ~ (rwy.crosswind == 0 ? "" : (rwy.crosswind < 0 ? " from left" : " from right"));
            y += me._printLineWithValue(0, y, "Crosswind:", math.round(math.abs(rwy.crosswind)), unit);
            y += me._printLineWithValue(0, y, "Heading:", math.round(rwy.heading) ~ "°");
            y += me._printLineWithValue(0, y, "Length:", math.round(rwy.length), "m");
            y += me._printLineWithValue(0, y, "Width:", math.round(rwy.width), "m");
            y += me._printLineWithValue(0, y, "Reciprocal:", rwy.reciprocalId);
            y += me._printLineWithValue(0, y, "ILS:", rwy.ils == nil ? "No" : (sprintf("%.3f/%.0f°", rwy.ils.frequency / 100, rwy.ils.course)));

            me._drawWindRose.drawWindRose(
                500,
                y,
                roseRadius,
                me._wind.getDirection(),
                me._wind.getSpeedKt(),
                rwy,
            );

            # Margin between runways
            y += (roseRadius * 2);
        }

        return y;
    },

    #
    # @param  int  x  Init position of x.
    # @param  int  y  Init position of y.
    # @param  hash  runway  Runway data object.
    # @return int  New position of y shifted by height of printed runway label.
    #
    _printRunwayLabel: func(x, y, runway) {
        var text = me._canvas.createChild("text")
            .setText("Runway: ")
            .setTranslation(x, y)
            .setColor(Colors.DEFAULT_TEXT);

        x += text.getSize()[0] + 5;
        text = me._canvas.createChild("text")
            .setText(runway.rwyId)
            .setTranslation(x, y)
            .setColor([0.0, 0.0, 0.0])
            .setFontSize(20)
            .setFont(Fonts.SANS_BOLD);

        x += text.getSize()[0] + 10;
        text = me._canvas.createChild("text")
            .setText(me._geWindLabelByDir(runway.normDiffDeg))
            .setTranslation(x, y)
            .setColor(me._geWindColorByDir(runway.normDiffDeg))
            .setFont(me._geWindFontByDir(runway.normDiffDeg));

        return text.getSize()[1] + WhichRwyDialog.MARGIN_Y;
    },

    #
    # @param  int  normDiffDeg
    # @return string  Wind label: "Headwind", "Crosswind" or "Tailwind"
    #
    _geWindLabelByDir: func(normDiffDeg) {
             if (normDiffDeg <= Wind.HEADWIND_THRESHOLD)  return "Headwind";
        else if (normDiffDeg <= Wind.CROSSWIND_THRESHOLD) return "Crosswind";
        else                                              return "Tailwind";
    },

    #
    # @param  int  normDiffDeg
    # @return vector  RGB color.
    #
    _geWindColorByDir: func(normDiffDeg) {
             if (normDiffDeg <= Wind.HEADWIND_THRESHOLD)  return Colors.HEADWIND;
        else if (normDiffDeg <= Wind.CROSSWIND_THRESHOLD) return Colors.CROSSWIND;
        else                                              return Colors.DEFAULT_TEXT;
    },

    #
    # @param  int  normDiffDeg
    # @return string  Font path.
    #
    _geWindFontByDir: func(normDiffDeg) {
        if (normDiffDeg <= Wind.CROSSWIND_THRESHOLD) return Fonts.SANS_BOLD;
        else                                         return Fonts.SANS_REGULAR;
    },

    #
    # @param  int  x  Init position of x.
    # @param  int  y  Init position of y.
    # @param  string  label  Label text.
    # @param  string|int  value  Value to display.
    # @param  string|nil  unit  Unit to display.
    # @return int  New position of y shifted by height of printed line.
    #
    _printLineWithValue: func(x, y, label, value, unit = nil) {
        var text = me._canvas.createChild("text")
            .setText(label)
            .setTranslation(x, y)
            .setColor(Colors.DEFAULT_TEXT);

        x += 100;
        text = me._canvas.createChild("text")
            .setText(value)
            .setTranslation(x, y)
            .setColor(Colors.DEFAULT_TEXT)
            .setFont(Fonts.SANS_BOLD);

        if (unit != nil) {
            x += text.getSize()[0] + 5;
            text = me._canvas.createChild("text")
                .setText(unit)
                .setTranslation(x, y)
                .setColor(Colors.DEFAULT_TEXT);
        }

        return text.getSize()[1] + WhichRwyDialog.MARGIN_Y;
    },
};
