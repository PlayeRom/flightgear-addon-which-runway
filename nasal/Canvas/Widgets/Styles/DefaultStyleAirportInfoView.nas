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
# AirportInfoView widget View.
#
DefaultStyle.widgets["airport-info-view"] = {
    #
    # Constructor.
    #
    # @param  ghost  parent
    # @param  hash  cfg
    # @return void
    #
    new: func(parent, cfg) {
        me._root = parent.createChild("group", "airport-info-view");

        me._draw = Draw.new(me._root);

        me._LABEL = 0;
        me._VAL   = 1;
        me._UNIT  = 2;
        me._VAL2  = 3;
        me._UNIT2 = 4;

        me._airportNameText = me._draw.createText("n/a")
            .setColor(whichRunway.Colors.DEFAULT_TEXT)
            .setFontSize(24)
            .setFont(whichRunway.Fonts.SANS_BOLD);

        me._latLon = [
            me._draw.createTextLabel("Lat, Lon:"),
            me._draw.createTextValue("n/a"),
        ];

        me._elevation = [
            me._draw.createTextLabel("Elevation:"),
            me._draw.createTextValue("n/a"),
            me._draw.createTextUnit("ft /"),
            me._draw.createTextValue("n/a"),
            me._draw.createTextUnit("m"),
        ];

        me._magVar = [
            me._draw.createTextLabel("Mag Var:"),
            me._draw.createTextValue("n/a"),
        ];

        me._hasMetar = [
            me._draw.createTextLabel("Has METAR:"),
            me._draw.createTextValue("n/a"),
        ];

        me._contentHeight = nil;
    },

    #
    # Callback called when user resized the window.
    #
    # @param  ghost  model  AirportInfoView model.
    # @param  int  w, h  Width and height of widget.
    # @return ghost
    #
    setSize: func(model, w, h) {
        me.reDrawContent(model);

        return me;
    },

    #
    # @param  ghost  model  AirportInfoView model.
    # @return void
    #
    update: func(model) {
        # nothing here
    },

    #
    # Set remembered content height to nil for recalculate translations during redraw.
    #
    # @param  ghost  model  AirportInfoView model.
    # @return void
    #
    resetContentHeight: func(model) {
        me._contentHeight = nil;
    },

    #
    # @param  ghost  model  AirportInfoView model.
    # @return void
    #
    reDrawContent: func(model) {
        if (me._contentHeight == nil) {
            me._contentHeight = me._setTranslations(model);
        }

        if (model._airport != nil) {
            me._drawAirportInfo(model);
        }

        # model.setLayoutMaximumSize([MAX_SIZE, y]);
        model.setLayoutMinimumSize([model._size[0], me._contentHeight]);
        model.setLayoutSizeHint([model._size[0], me._contentHeight]);
    },

    #
    # @param  ghost  model  AirportInfoView model.
    # @return double  New Y position.
    #
    _setTranslations: func(model) {
        var x = 0;
        var y = me._airportNameText.getSize()[1];

        me._airportNameText.setTranslation(x, y);
        y += me._draw.shiftY(me._airportNameText);

        y += me._draw.setTextTranslations(y, me._latLon, model._valueMarginX);
        y += me._draw.setTextTranslations(y, me._elevation, model._valueMarginX);
        y += me._draw.setTextTranslations(y, me._magVar, model._valueMarginX);
        y += me._draw.setTextTranslations(y, me._hasMetar, model._valueMarginX, true);

        return y;
    },

    #
    # Draw airport and METAR information.
    #
    # @param  ghost  model  AirportInfoView model.
    # @return void
    #
    _drawAirportInfo: func(model) {
        var elevationFt = sprintf("%d", math.round(model._airport.elevation * globals.M2FT));
        var elevationM  = sprintf("%d", math.round(model._airport.elevation));

        me._airportNameText.setText(model._airport.id ~ " – " ~ model._airport.name);
        me._latLon[me._VAL].setText(me._getLatLonInfo(model));

        me._elevation[me._VAL].setText(elevationFt);
        me._elevation[me._VAL2].setText(elevationM);
        var (xT, yT) = me._elevation[me._VAL].getTranslation();
        me._draw.setTextTranslations(yT, me._elevation, model._valueMarginX);

        me._magVar[me._VAL].setText(sprintf("%.2f°", model._aptMagVar));
        me._hasMetar[me._VAL].setText(model._airport.has_metar ? "Yes" : "No");
    },

    #
    # Get string with airport geo coordinates in decimal and sexagesimal formats.
    #
    # @param  ghost  model  AirportInfoView model.
    # @return string
    #
    _getLatLonInfo: func(model) {
        var decimal = sprintf("%.4f, %.4f", model._airport.lat, model._airport.lon);

        var signNS = model._airport.lat >= 0 ? "N" : "S";
        var signEW = model._airport.lon >= 0 ? "E" : "W";
        var sexagesimal = sprintf(
            "%s %d°%02d'%.1f'', %s %d°%02d'%.1f''",
            signNS,
            math.abs(int(model._airport.lat)),
            math.abs(int(model._airport.lat * 60 - int(model._airport.lat) * 60)),
            math.abs(model._airport.lat * 3600 - int(model._airport.lat * 60) * 60),
            signEW,
            math.abs(int(model._airport.lon)),
            math.abs(int(model._airport.lon * 60 - int(model._airport.lon) * 60)),
            math.abs(model._airport.lon * 3600 - int(model._airport.lon * 60) * 60),
        );

        return decimal ~ "  /  " ~ sexagesimal;
    },
};
