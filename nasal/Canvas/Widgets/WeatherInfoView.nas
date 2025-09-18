#
# Which Runway - Add-on for FlightGear
#
# Written and developer by Roman Ludwicki (PlayeRom, SP-ROM)
#
# Copyright (C) 2024 Roman Ludwicki
#
# WeatherInfoView widget is an Open Source project and it is licensed
# under the GNU Public License v3 (GPLv3)
#

#
# WeatherInfoView widget Model
#
gui.widgets.WeatherInfoView = {
    _CLASS: "WeatherInfoView",

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
        var me = gui.Widget.new(gui.widgets.WeatherInfoView, cfg);
        me._focus_policy = me.NoFocus;
        me._setView(style.createWidget(parent, "weather-info-view", me._cfg));

        me._isMetarData = false;
        me._windDir = nil;
        me._windKt = 0;
        me._windGustKt = 0;
        me._qnhValues = nil;
        me._qfeValues = nil;

        return me;
    },

    #
    # @param  bool  isMetarData  Set true to confirm weather data. If false then wind will be draw as "n/a".
    # @return ghost
    #
    setIsMetarData: func(isMetarData) {
        me._isMetarData = isMetarData;
        return me;
    },

    #
    # @param  double|nil  windDir  Wind direction in degrees. If nil then wind is variable.
    # @param  double  windKt  Wind speed in knots.
    # @param  double  windGustKt  Wind gust speed in knots.
    # @return ghost
    #
    setWind: func(windDir, windKt, windGustKt) {
        me._windDir = windDir;
        me._windKt = windKt;
        me._windGustKt = windGustKt;
        return me;
    },

    #
    # @param  hash|nil  qnhValues  Hash with 3 fields: "inHg", "hPa", "mmHg". If nil then we haven't data (no METAR).
    # @return ghost
    #
    setQnhValues: func(qnhValues) {
        me._qnhValues = qnhValues;
        return me;
    },

    #
    # @param  hash|nil  qfeValues  Hash with 3 fields: "inHg", "hPa", "mmHg". If nil then we haven't data (no METAR).
    # @return ghost
    #
    setQfeValues: func(qfeValues) {
        me._qfeValues = qfeValues;
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
