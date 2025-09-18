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
# WeatherInfoView widget View.
#
DefaultStyle.widgets["weather-info-view"] = {
    #
    # Constructor.
    #
    # @param  ghost  parent
    # @param  hash  cfg
    # @return void
    #
    new: func(parent, cfg) {
        me._root = parent.createChild("group", "weather-info-view");

        me._draw = Draw.new(me._root);

        me._pressure = {
            qnh: {
                label   : me._draw.createTextLabel("QNH:"),
                inHgVal : me._draw.createTextValue("n/a"),
                inHgUnit: me._draw.createTextUnit("inHg /"),
                hPaVal  : me._draw.createTextValue("n/a").setAlignment("right-baseline"),
                hPaUnit : me._draw.createTextUnit("hPa /"),
                mmHgVal : me._draw.createTextValue("n/a"),
                mmHgUnit: me._draw.createTextUnit("mmHg"),
            },
            qfe: {
                label   : me._draw.createTextLabel("QFE:"),
                inHgVal : me._draw.createTextValue("n/a"),
                inHgUnit: me._draw.createTextUnit("inHg /"),
                hPaVal  : me._draw.createTextValue("n/a").setAlignment("right-baseline"),
                hPaUnit : me._draw.createTextUnit("hPa /"),
                mmHgVal : me._draw.createTextValue("n/a"),
                mmHgUnit: me._draw.createTextUnit("mmHg"),
            },
        };

        me._windText = me._draw.createText("Wind")
            .setColor(whichRunway.Colors.BLUE)
            .setFontSize(20)
            .setFont(whichRunway.Fonts.SANS_BOLD);
    },

    #
    # Callback called when user resized the window.
    #
    # @param  ghost  model  WeatherInfoView model.
    # @param  int  w, h  Width and height of widget.
    # @return ghost
    #
    setSize: func(model, w, h) {
        me.reDrawContent(model);

        return me;
    },

    #
    # @param  ghost  model  WeatherInfoView model.
    # @return void
    #
    update: func(model) {
        # nothing here
    },

    #
    # @param  ghost  model  WeatherInfoView model.
    # @return void
    #
    reDrawContent: func(model) {
        var x = 0;
        var y = 0;

        y += me._drawWeatherData(x, y, model);

        # model.setLayoutMaximumSize([MAX_SIZE, y]);
        model.setLayoutMinimumSize([model._size[0], y]);
        model.setLayoutSizeHint([model._size[0], y]);
    },

    #
    # Draw weather data (pressure and wind).
    #
    # @param  double  x  Init position of x.
    # @param  double  y  Init position of y.
    # @param  ghost  model  WeatherInfoView model.
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
    # @param  ghost  model  WeatherInfoView model.
    # @return string
    #
    _getWindInfoText: func(model) {
        if (!model._isMetarData) {
            return "n/a";
        }

        var windDir = model._windDir == nil
            ? "variable"
            : sprintf("%d°", math.round(model._windDir));

        var wind = windDir ~ sprintf(" at %d kts", math.round(model._windKt));

        var gust = math.round(model._windGustKt);
        if (gust > 0) {
            return wind ~ sprintf(" with gust at %d kts", gust);
        }

        return wind;
    },
};
