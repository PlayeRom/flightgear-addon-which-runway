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
        me._isMetarFromNearestAirport = false;
        me._distanceToStation = nil;
        me._metarIcao = nil;
        me._metar = nil;
        me._canUseMetar = false;
        me._windDir = nil;
        me._windSpeedKt = 0;
        me._windGustSpeedKt = 0;
        me._qnhValues = nil;
        me._qfeValues = nil;
        me._metarRangeNm = 0;

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
    # @param  bool  isRealWeatherEnabled
    # @return ghost
    #
    setIsMetarFromNearestAirport: func(isMetarFromNearestAirport) {
        me._isMetarFromNearestAirport = isMetarFromNearestAirport;
        return me;
    },

    #
    # @param  double|nil  distanceToStation  Distance in meters or nil if failed.
    # @return ghost
    #
    setDistanceToStation: func(distanceToStation) {
        me._distanceToStation = distanceToStation;
        return me;
    },

    #
    # @param  string|nil  icao
    # @return ghost
    #
    setMetarIcao: func(icao) {
        me._metarIcao = icao;
        return me;
    },

    #
    # @param  string|nil  metar
    # @return ghost
    #
    setMetar: func(metar) {
        me._metar = metar;
        return me;
    },

    #
    # @param  bool  can
    # @return ghost
    #
    setCanUseMetar: func(can) {
        me._canUseMetar = can;
        return me;
    },

    #
    # @param  double|nil  windDir
    # @param  double  windSpeedKt
    # @param  double  windGustSpeedKt
    # @return ghost
    #
    setMetarWind: func(windDir, windSpeedKt, windGustSpeedKt) {
        me._windDir = windDir;
        me._windSpeedKt = windSpeedKt;
        me._windGustSpeedKt = windGustSpeedKt;
        return me;
    },

    #
    # @param  hash|nil  qnhValues
    # @return ghost
    #
    setQnhValues: func(qnhValues) {
        me._qnhValues = qnhValues;
        return me;
    },

    #
    # @param  hash|nil  qfeValues
    # @return ghost
    #
    setQfeValues: func(qfeValues) {
        me._qfeValues = qfeValues;
        return me;
    },

    #
    # @param  int  metarRangeNm
    # @return ghost
    #
    setMetarRangeNm: func(metarRangeNm) {
        me._metarRangeNm = metarRangeNm;
        return me;
    },

    #
    # Redraw view
    #
    # @return void
    #
    updateView: func() {
        me._view.reDrawContent(me);
    },
};
