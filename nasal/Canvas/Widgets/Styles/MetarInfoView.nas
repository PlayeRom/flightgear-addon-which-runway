#
# Which Runway - Add-on for FlightGear
#
# Written and developer by Roman Ludwicki (PlayeRom, SP-ROM)
#
# Copyright (C) 2024 Roman Ludwicki
#
# AirportInfo widget is an Open Source project and it is licensed
# under the GNU Public License v3 (GPLv3)
#

#
# MetarInfo widget View.
#
DefaultStyle.widgets["metar-info-view"] = {
    #
    # Constructor.
    #
    # @param  ghost  parent
    # @param  hash  cfg
    # @return void
    #
    new: func(parent, cfg) {
        me._root = parent.createChild("group", "metar-info-view");

        me._draw = Draw.new(me._root);

        me._noLiveDataText = me._draw.createText("For METAR, it is necessary to select the \"Live Data\" weather scenario!")
            .setColor(whichRunway.Colors.RED)
            .setVisible(false);

        me._foreignMetarText = me._draw.createText() # "METAR comes from %s, %.1f NM (%.1f km) away:",
            .setColor(whichRunway.Colors.AMBER)
            .setVisible(false);

        me._metarLine1Text = me._draw.createText()
            .setColor(style.getColor("text_color"))
            .setVisible(false);

        me._metarLine2Text = me._draw.createText()
            .setColor(style.getColor("text_color"))
            .setVisible(false);
    },

    #
    # Callback called when user resized the window.
    #
    # @param  ghost  model  MetarInfo model.
    # @param  int  w, h  Width and height of widget.
    # @return ghost
    #
    setSize: func(model, w, h) {
        me.reDrawContent(model);

        return me;
    },

    #
    # @param  ghost  model  MetarInfo model.
    # @return void
    #
    update: func(model) {
        # nothing here
    },

    #
    # @param  ghost  model  MetarInfo model.
    # @return void
    #
    reDrawContent: func(model) {
        var x = 0;
        var y = 0;

        me._noLiveDataText.setVisible(false);
        me._foreignMetarText.setVisible(false);
        me._metarLine1Text.setVisible(false);
        me._metarLine2Text.setVisible(false);

        y += me._drawMetar(x, y, model);

        # model.setLayoutMaximumSize([MAX_SIZE, y]);
        model.setLayoutMinimumSize([model._size[0], y]);
        model.setLayoutSizeHint([model._size[0], y]);
    },

    #
    # Draw airport METAR.
    #
    # @param  double  x  Init position of x.
    # @param  double  y  Init position of y.
    # @param  ghost  model  MetarInfo model
    # @return double  New position of y shifted by height of printed line.
    #
    _drawMetar: func(x, y, model) {
        if (!model._isRealWeatherEnabled) {
            return me._printNoteLiveDataDisabled(x, y);
        }

        if (model._isMetarFromNearestAirport) {
            y += me._printWarningForeignMetar(x, y, model);
        }

        var color = model._isMetarFromNearestAirport
            ? whichRunway.Colors.AMBER
            : style.getColor("text_color");

        var (line1, line2) = me._getMetarTextLines(model);

        me._metarLine1Text.setText(line1)
            .setTranslation(x, y)
            .setColor(color)
            .setVisible(true);

        var lastText = me._metarLine1Text;

        if (line2 != nil) {
            y += me._draw.shiftY(me._metarLine1Text, 5);

            me._metarLine2Text.setText(line2)
                .setTranslation(x, y)
                .setColor(color)
                .setVisible(true);

            lastText = me._metarLine2Text;
        }

        return y + me._draw.shiftY(lastText, 0);
    },

    #
    # Draw note that Live Data weather scenario is disabled.
    #
    # @param  double  x  Init position of x.
    # @param  double  y  Init position of y.
    # @return double  New position of y shifted by height of printed line.
    #
    _printNoteLiveDataDisabled: func(x, y) {
        me._noLiveDataText
            .setTranslation(x, y)
            .setVisible(true);

        return y + me._draw.shiftY(me._noLiveDataText, 0);
    },

    #
    # Draw warning that the METAR is from another airport.
    #
    # @param  double  x  Init position of x.
    # @param  double  y  Init position of y.
    # @param  ghost  model  MetarInfo model.
    # @return double  New position of y shifted by height of printed line.
    #
    _printWarningForeignMetar: func(x, y, model) {
        var distM = model._distanceToStation;

        var label = distM == nil
            ? sprintf("METAR comes from %s, ? NM (? km) away:", model._metarIcao)
            : sprintf(
                "METAR comes from %s, %.1f NM (%.1f km) away:",
                model._metarIcao,
                distM * globals.M2NM,
                distM / 1000,
            );

        me._foreignMetarText.setText(label)
            .setTranslation(x, y)
            .setVisible(true);

        return me._draw.shiftY(me._foreignMetarText);
    },

    #
    # @param  ghost  model  MetarInfo model.
    # @return vector  Two lines of text, where second line can be nil.
    #
    _getMetarTextLines: func(model) {
        var metar = model._metar;
        if (metar == nil) {
            var line1 = sprintf(
                "No METAR within %d NM (%.1f km)",
                model._metarRangeNm,
                (model._metarRangeNm * globals.NM2M) / 1000,
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
