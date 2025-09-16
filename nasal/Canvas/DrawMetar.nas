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
# Draw METAR class.
#
var DrawMetar = {
    #
    # Constructor.
    #
    # @param  hash  draw  Draw object.
    # @param  hash  metar  Metar object.
    # @return hash
    #
    new: func(draw, metar) {
        var me = { parents: [DrawMetar] };

        me._draw = draw;
        me._metar = metar;

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
    # Draw airport METAR.
    #
    # @param  double  x  Init x position.
    # @param  double  y  Init y position.
    # @param  ghost  airport
    # @return double  New position of y shifted by height of printed line.
    #
    drawMetar: func(x, y, airport) {
        if (!me._metar.isRealWeatherEnabled()) {
            return me._printNoteLiveDataDisabled(x, y);
        }

        if (me._metar.isMetarFromNearestAirport()) {
            y += me._printWarningForeignMetar(x, y, airport);
        }

        var color = me._metar.isMetarFromNearestAirport() ? Colors.AMBER : Colors.DEFAULT_TEXT;
        var (line1, line2) = me._getMetarTextLines(airport);

        var text = me._draw.createText(line1)
            .setTranslation(x, y)
            .setColor(color);

        if (line2 != nil) {
            y += text.getSize()[1] + 5;

            text = me._draw.createText(line2)
                .setTranslation(x, y)
                .setColor(color);
        }

        return y + text.getSize()[1] + (Draw.MARGIN_Y * 2);
    },

    #
    # Draw note that Live Data weather scenario is disabled.
    #
    # @param  double  x  Init position of x.
    # @param  double  y  Init position of y.
    # @return double  New position of y shifted by height of printed line.
    #
    _printNoteLiveDataDisabled: func(x, y) {
        var text = me._draw.createText("For METAR, it is necessary to select the \"Live Data\" weather scenario!")
            .setTranslation(x, y)
            .setColor(Colors.RED);

        return y + text.getSize()[1] + (Draw.MARGIN_Y * 2);
    },

    #
    # Draw warning that the METAR is from another airport.
    #
    # @param  double  x  Init position of x.
    # @param  double  y  Init position of y.
    # @param  ghost  airport
    # @return double  New position of y shifted by height of printed line.
    #
    _printWarningForeignMetar: func(x, y, airport) {
        var distM = me._metar.getDistanceToStation(airport);

        var label = sprintf(
            "METAR comes from %s, %.1f NM (%.1f km) away:",
            me._metar.getIcao(),
            distM * globals.M2NM,
            distM / 1000,
        );

        var text = me._draw.createText(label)
            .setTranslation(x, y)
            .setColor(Colors.AMBER);

        return text.getSize()[1] + Draw.MARGIN_Y;
    },

    #
    # @param  ghost  airport
    # @return vector  Two lines of text, where second line can be nil.
    #
    _getMetarTextLines: func(airport) {
        var metar = me._metar.getMetar(airport);
        if (metar == nil) {
            var line1 = sprintf("No METAR within %d NM (%.1f km)",
                DrawTabContent.METAR_RANGE_NM,
                (DrawTabContent.METAR_RANGE_NM * globals.NM2M) / 1000,
            );

            return [line1, nil];
        }

        var metarParts = globals.split(" ", metar);
        var count = size(metarParts);
        if (count <= 12) {
            # Draw by one line
            return [metar, nil];
        }

        # Draw by 2 lines - METAR is too long
        var half = int(count / 2);

        return me._mergePartsIntoLines(metarParts, count, half);
    },

    #
    # @param  vector  parts
    # @param  int  count  Quantity of all parts.
    # @param  int  half  Part index where the first line ends.
    # @return vector  Two lines of text.
    #
    _mergePartsIntoLines: func(parts, count, half) {
        var line1 = "";
        var line2 = "";

        for (var i = 0; i < count; i += 1) {
            if (i < half) {
                line1 ~= parts[i] ~ " ";
            } else {
                line2 ~= parts[i] ~ " ";
            }
        }

        return [line1, line2];
    },
};
