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
# AirportInfo widget View.
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
            .setColor(style.getColor("text_color"))
            .setFontSize(24)
            .setFont(canvas.font_mapper("sans", "bold"));

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

        me._bestRunwayForPos = [
            me._draw.createTextLabel("Best runway:"),
            me._draw.createTextValue("n/a"),
            me._draw.createTextUnit("from aircraft position:"),
            me._draw.createTextValue("n/a"),
        ];

        me._distance = [
            me._draw.createTextLabel("Distance:"),
            me._draw.createTextValue("n/a"),
            me._draw.createTextUnit("NM /"),
            me._draw.createTextValue("n/a"),
            me._draw.createTextUnit("km"),
        ];

        me._bearing = [
            me._draw.createTextLabel("Bearing:"),
            me._draw.createTextValue("n/a"),
            me._draw.createTextUnit("mag /"),
            me._draw.createTextValue("n/a"),
            me._draw.createTextUnit("true"),
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
    # @param  ghost  model  AirportInfo model.
    # @param  int  w, h  Width and height of widget.
    # @return ghost
    #
    setSize: func(model, w, h) {
        me.reDrawContent(model);

        return me;
    },

    #
    # @param  ghost  model  AirportInfo model.
    # @return void
    #
    update: func(model) {
        # nothing here
    },

    #
    # Set remembered content height to nil for recalculate translations during redraw.
    #
    # @param  ghost  model  AirportInfo model.
    # @return void
    #
    resetContentHeight: func(model) {
        me._contentHeight = nil;
    },

    #
    # @param  ghost  model  AirportInfo model.
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
    # Redraw data for timer.
    #
    # @param  ghost  model  AirportInfo model.
    # @return void
    #
    updateDynamicData: func(model) {
        var acGeoPos = geo.aircraft_position();
        var airportGeoPos = geo.Coord.new().set_latlon(model._airport.lat, model._airport.lon);

        me._updateBestRwyByAcPos(model, acGeoPos);
        me._updateDistance(model, acGeoPos, airportGeoPos);
        me._updateBearing(model, acGeoPos, airportGeoPos);
    },

    #
    # @param  ghost  model  AirportInfo model.
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
        y += me._draw.setTextTranslations(y, me._bestRunwayForPos, model._valueMarginX);
        y += me._draw.setTextTranslations(y, me._distance, model._valueMarginX);
        y += me._draw.setTextTranslations(y, me._bearing, model._valueMarginX);
        y += me._draw.setTextTranslations(y, me._hasMetar, model._valueMarginX, true);

        return y;
    },

    #
    # Draw airport and METAR information.
    #
    # @param  ghost  model  AirportInfo model.
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

        me.updateDynamicData(model);
    },

    #
    # Get string with airport geo coordinates in decimal and sexagesimal formats.
    #
    # @param  ghost  model  AirportInfo model.
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

   #
    # @param  ghost  model  AirportInfo model.
    # @param  hash  acGeoPos  The geo.Coord object of aircraft position.
    # @return void
    #
    _updateBestRwyByAcPos: func(model, acGeoPos) {
        var bestRwy = model._airport.findBestRunwayForPos(acGeoPos);

        me._bestRunwayForPos[me._VAL].setText(sprintf("%s", bestRwy == nil ? "n/a" : bestRwy.id));
        me._bestRunwayForPos[me._VAL2].setText(sprintf("%.4f, %.4f", acGeoPos.lat(), acGeoPos.lon()));
        var (xT, yT) = me._bestRunwayForPos[me._VAL].getTranslation();
        me._draw.setTextTranslations(yT, me._bestRunwayForPos, model._valueMarginX);
    },

    #
    # @param  ghost  model  AirportInfo model.
    # @param  hash  acGeoPos  The geo.Coord object of aircraft position.
    # @param  hash  airportGeoPos  The geo.Coord object of airport position.
    # @return void
    #
    _updateDistance: func(model, acGeoPos, airportGeoPos) {
        var distanceM = airportGeoPos.distance_to(acGeoPos);

        me._distance[me._VAL].setText(sprintf("%.1f", distanceM == nil ? "n/a" : distanceM * globals.M2NM));
        me._distance[me._VAL2].setText(sprintf("%.1f", distanceM == nil ? "n/a" : distanceM / 1000));
        var (xT, yT) = me._distance[me._VAL].getTranslation();
        me._draw.setTextTranslations(yT, me._distance, model._valueMarginX);
    },

    #
    # @param  ghost  model  AirportInfo model.
    # @param  hash  acGeoPos  The geo.Coord object of aircraft position.
    # @param  hash  airportGeoPos  The geo.Coord object of airport position.
    # @return void
    #
    _updateBearing: func(model, acGeoPos, airportGeoPos) {
        var bearingTrue = acGeoPos.course_to(airportGeoPos);
        var bearingMag = geo.normdeg(bearingTrue - globals.magvar(acGeoPos.lat(), acGeoPos.lon()));

        me._bearing[me._VAL].setText(me._getBearingString(bearingMag));
        me._bearing[me._VAL2].setText(me._getBearingString(bearingTrue));
        var (xT, yT) = me._bearing[me._VAL].getTranslation();
        me._draw.setTextTranslations(yT, me._bearing, model._valueMarginX);
    },

    #
    # @param  double  bearing
    # @return string
    #
    _getBearingString: func(bearing) {
        return bearing == nil
            ? "n/a"
            : sprintf("%.0f°", bearing);
    },
};
