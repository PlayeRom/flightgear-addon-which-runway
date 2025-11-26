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
# MetarInfo widget Model
#
gui.widgets.MetarInfo = {
    _CLASS: "MetarInfo",

    #
    # Constructor.
    #
    # @param  hash  parent
    # @param  hash|nil  style
    # @param  hash|nil  cfg
    # @return ghost
    #
    new: func(parent, style = nil, cfg = nil) {
        style = style or canvas.style;
        cfg = Config.new(cfg);

        var obj = gui.Widget.new(gui.widgets.MetarInfo, cfg);
        obj._focus_policy = obj.NoFocus;
        obj._setView(style.createWidget(parent, "metar-info-view", cfg));

        obj._isRealWeatherEnabled = false;
        obj._isBasicWxEnabled = false;

        # If true then METAR is taken from nearest airport.
        obj._isMetarFromNearestAirport = false;

        # If METAR is taken from nearest airport this value has a distance to this airport.
        obj._distanceToStation = nil;

        # ICAO code of the airport from which the METAR originates.
        obj._metarIcao = nil;

        # METAR message string.
        obj._metar = nil;

        # The max range within which we are looking for METARs from other airports.
        obj._metarRangeNm = 30;

        return obj;
    },

    #
    # @param  bool  isRealWeatherEnabled
    # @return ghost
    #
    setIsRealWeatherEnabled: func(isRealWeatherEnabled) {
        me._isRealWeatherEnabled = isRealWeatherEnabled;
        return me;
    },

    #
    # @param  bool  isBasicWxEnabled
    # @return ghost
    #
    setIsBasicWxEnabled: func(isBasicWxEnabled) {
        me._isBasicWxEnabled = isBasicWxEnabled;
        return me;
    },

    #
    # @param  bool  isMetarFromNearestAirport
    # @return ghost
    #
    setIsMetarFromNearestAirport: func(isMetarFromNearestAirport) {
        me._isMetarFromNearestAirport = isMetarFromNearestAirport;
        return me;
    },

    #
    # @param  double|nil  distanceToStation  Distance in meters or nil.
    # @return ghost
    #
    setDistanceToStation: func(distanceToStation) {
        me._distanceToStation = distanceToStation;
        return me;
    },

    #
    # @param  string|nil  icao  ICAO code of METAR station.
    # @return ghost
    #
    setMetarIcao: func(icao) {
        me._metarIcao = icao;
        return me;
    },

    #
    # @param  string|nil  metar  METAR text or nil.
    # @return ghost
    #
    setMetar: func(metar) {
        me._metar = metar;
        return me;
    },

    #
    # @param  double  metarRangeNm  The max range within which we are looking for METARs from other airports.
    # @return ghost
    #
    setMetarRangeNm: func(metarRangeNm) {
        me._metarRangeNm = metarRangeNm;
        return me;
    },

    #
    # Redraw view.
    #
    # @return void
    #
    updateView: func {
        me._view.reDrawContent(me);
    },
};
