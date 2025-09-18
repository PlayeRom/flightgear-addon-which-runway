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
# MetarInfoView widget Model
#
gui.widgets.MetarInfoView = {
    _CLASS: "MetarInfoView",

    #
    # Constructor.
    #
    # @param  ghost  parent
    # @param  hash  style
    # @param  hash  cfg
    # @return ghost
    #
    new: func(parent, style = nil, cfg = nil) {
        style = style or canvas.style;
        cfg = Config.new(cfg);
        var me = gui.Widget.new(gui.widgets.MetarInfoView, cfg);
        me._focus_policy = me.NoFocus;
        me._setView(style.createWidget(parent, "metar-info-view", me._cfg));

        me._isRealWeatherEnabled = false;

        # If true then METAR is taken from nearest airport.
        me._isMetarFromNearestAirport = false;

        # If METAR is taken from nearest airport this value has a distance to this airport.
        me._distanceToStation = nil;

        # ICAO code of the airport from which the METAR originates.
        me._metarIcao = nil;

        # METAR message string.
        me._metar = nil;

        # The max range within which we are looking for METARs from other airports.
        me._metarRangeNm = 30;

        return me;
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
    # @param  int  metarRangeNm  The max range within which we are looking for METARs from other airports.
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
    updateView: func() {
        me._view.reDrawContent(me);
    },
};
