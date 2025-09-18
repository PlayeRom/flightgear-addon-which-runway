#
# Which Runway - Add-on for FlightGear
#
# Written and developer by Roman Ludwicki (PlayeRom, SP-ROM)
#
# Copyright (C) 2024 Roman Ludwicki
#
# AirportInfoView widget is an Open Source project and it is licensed
# under the GNU Public License v3 (GPLv3)
#

#
# MetarInfoView widget View.
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

        var x = 0;
        var y = 0;

        me._noLiveDataText = me._draw.createText("For METAR, it is necessary to select the \"Live Data\" weather scenario!")
            .setTranslation(x, y)
            .setColor(whichRunway.Colors.RED)
            .setVisible(false);

        me._foreignMetarText = me._draw.createText() # "METAR comes from %s, %.1f NM (%.1f km) away:",
            .setTranslation(x, y)
            .setColor(whichRunway.Colors.AMBER)
            .setVisible(false);

        me._metarLine1Text = me._draw.createText()
            .setTranslation(x, y)
            .setColor(whichRunway.Colors.DEFAULT_TEXT)
            .setVisible(false);

        me._metarLine2Text = me._draw.createText()
            .setTranslation(x, y)
            .setColor(whichRunway.Colors.DEFAULT_TEXT)
            .setVisible(false);

        me._pressure = {
            qnh: {
                label   : me._draw.createTextLabel(x, y, "QNH:"),
                inHgVal : me._draw.createTextValue(x, y, "n/a"),
                inHgUnit: me._draw.createTextUnit(x, y, "inHg /"),
                hPaVal  : me._draw.createTextValue(x, y, "n/a").setAlignment("right-baseline"),
                hPaUnit : me._draw.createTextUnit(x, y, "hPa /"),
                mmHgVal : me._draw.createTextValue(x, y, "n/a"),
                mmHgUnit: me._draw.createTextUnit(x, y, "mmHg"),
            },
            qfe: {
                label   : me._draw.createTextLabel(x, y, "QFE:"),
                inHgVal : me._draw.createTextValue(x, y, "n/a"),
                inHgUnit: me._draw.createTextUnit(x, y, "inHg /"),
                hPaVal  : me._draw.createTextValue(x, y, "n/a").setAlignment("right-baseline"),
                hPaUnit : me._draw.createTextUnit(x, y, "hPa /"),
                mmHgVal : me._draw.createTextValue(x, y, "n/a"),
                mmHgUnit: me._draw.createTextUnit(x, y, "mmHg"),
            },
        };

        me._windText = me._draw.createText("Wind")
            .setTranslation(x, y)
            .setColor(whichRunway.Colors.BLUE)
            .setFontSize(20)
            .setFont(whichRunway.Fonts.SANS_BOLD);
    },

    #
    # Callback called when user resized the window.
    #
    # @param  ghost  model  MetarInfoView model.
    # @param  int  w, h  Width and height of widget.
    # @return ghost
    #
    setSize: func(model, w, h) {
        me.reDrawContent(model);

        return me;
    },

    #
    # @param  ghost  model  MetarInfoView model.
    # @return void
    #
    update: func(model) {
        # nothing here
    },

    #
    # @param  ghost  model  MetarInfoView model.
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
        y += me._drawWeatherData(x, y, model);

        # model.setLayoutMaximumSize([MAX_SIZE, y]);
        model.setLayoutMinimumSize([model._size[0], 162.375]); # <- min height when METAR has one line.
        model.setLayoutSizeHint([model._size[0], y]);
    },

    #
    # Draw airport METAR.
    #
    # @param  double  x  Init position of x.
    # @param  double  y  Init position of y.
    # @param  ghost  model  MetarInfoView model
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
            : whichRunway.Colors.DEFAULT_TEXT;

        var (line1, line2) = me._getMetarTextLines(model);

        me._metarLine1Text.setText(line1)
            .setTranslation(x, y)
            .setColor(color)
            .setVisible(true);

        var lastText = me._metarLine1Text;

        if (line2 != nil) {
            y += me._metarLine1Text.getSize()[1] + 5;

            me._metarLine2Text.setText(line2)
                .setTranslation(x, y)
                .setColor(color)
                .setVisible(true);

            lastText = me._metarLine2Text;
        }

        return y + me._draw.shiftY(lastText, 2);
    },

    #
    # Draw weather data (pressure and wind).
    #
    # @param  double  x  Init position of x.
    # @param  double  y  Init position of y.
    # @param  ghost  model  MetarInfoView model.
    # @return double  New Y position.
    #
    _drawWeatherData: func(x, y, model) {
        foreach (var name; keys(me._pressure)) {
            me._pressure[name].inHgUnit.setVisible(false);
            me._pressure[name].hPaVal.setVisible(false);
            me._pressure[name].hPaUnit.setVisible(false);
            me._pressure[name].mmHgVal.setVisible(false);
            me._pressure[name].mmHgUnit.setVisible(false);
        }

        y += model._qnhValues == nil
            ? me._printLineAtmosphericPressureNone(x, y, me._pressure.qnh)
            : me._printLineAtmosphericPressure(x, y, me._pressure.qnh, model._qnhValues);

        y += model._qfeValues == nil
            ? me._printLineAtmosphericPressureNone(x, y, me._pressure.qfe)
            : me._printLineAtmosphericPressure(x, y, me._pressure.qfe, model._qfeValues);

        y += (Draw.MARGIN_Y * 2);

        # Wind
        y += me._printLineWind(x, y, "Wind " ~ me._getWindInfoText(model));

        return y;
    },

    #
    # @param  double  x  Init position of x.
    # @param  double  y  Init position of y.
    # @param  hash  press  Text elements.
    # @return double  New Y position.
    #
    _printLineAtmosphericPressureNone: func(x, y, press) {
        press.label.setTranslation(x, y);

        x += Draw.VALUE_MARGIN_X;
        press.inHgVal.setText("n/a").setTranslation(x, y);
        return me._draw.shiftY(press.inHgVal);
    },

    #
    # @param  double  x  Init position of x.
    # @param  double  y  Init position of y.
    # @param  hash  press  Text elements.
    # @param  hash  pressValues  Atmospheric pressure with 3 value: mmHg, hPa, inHg.
    # @return double  New Y position.
    #
    _printLineAtmosphericPressure: func(x, y, press, pressValues) {
        press.label.setTranslation(x, y);

        # inHg
        x += Draw.VALUE_MARGIN_X;
        press.inHgVal.setText(sprintf("%.02f", pressValues.inHg)).setTranslation(x, y);
        x += me._draw.shiftX(press.inHgVal);
        press.inHgUnit.setTranslation(x, y).setVisible(true);

        # hPa
        x += 82;
        press.hPaVal.setText(sprintf("%d", pressValues.hPa)).setTranslation(x, y).setVisible(true);
        x += 5;
        press.hPaUnit.setTranslation(x, y).setVisible(true);

        # mmHg
        x += 42;
        press.mmHgVal.setText(sprintf("%d", pressValues.mmHg)).setTranslation(x, y).setVisible(true);
        x += me._draw.shiftX(press.mmHgVal);
        press.mmHgUnit.setTranslation(x, y).setVisible(true);

        return me._draw.shiftY(press.mmHgUnit);
    },

    #
    # @param  double  x  Init position of x.
    # @param  double  y  Init position of y.
    # @param  string  label  Label text.
    # @return double  New Y position.
    #
    _printLineWind: func(x, y, label) {
        me._windText.setText(label).setTranslation(x, y);

        return me._draw.shiftY(me._windText);
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

        return y + me._draw.shiftY(me._noLiveDataText, 2);
    },

    #
    # Draw warning that the METAR is from another airport.
    #
    # @param  double  x  Init position of x.
    # @param  double  y  Init position of y.
    # @param  ghost  model  MetarInfoView model.
    # @return double  New position of y shifted by height of printed line.
    #
    _printWarningForeignMetar: func(x, y, model) {
        var distM = model._distanceToStation;

        var label = sprintf(
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
    # @param  ghost  model  MetarInfoView model.
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

    #
    # @param  ghost  model  MetarInfoView model.
    # @return string
    #
    _getWindInfoText: func(model) {
        if (!model._canUseMetar) {
            return "n/a";
        }

        var windDir = model._windDir == nil
            ? "variable"
            : sprintf("%d°", math.round(model._windDir));

        var wind = sprintf("%s at %d kts", windDir, math.round(model._windSpeedKt));

        var gust = math.round(model._windGustSpeedKt);
        if (gust > 0) {
            return sprintf("%s with gust at %d kts", wind, gust);
        }

        return wind;
    },
};
