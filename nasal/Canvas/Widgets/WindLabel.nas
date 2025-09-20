#
# Which Runway - Add-on for FlightGear
#
# Written and developer by Roman Ludwicki (PlayeRom, SP-ROM)
#
# Copyright (C) 2024 Roman Ludwicki
#
# WindLabel widget is an Open Source project and it is licensed
# under the GNU Public License v3 (GPLv3)
#

#
# WindLabel widget Model
#
gui.widgets.WindLabel = {
    _CLASS: "WindLabel",

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
        var me = gui.Widget.new(gui.widgets.WindLabel, cfg);
        me._focus_policy = me.NoFocus;
        me._setView(style.createWidget(parent, "wind-label-view", me._cfg));

        me._isMetarData = false;
        me._windDir = nil;
        me._windKt = 0;
        me._windGustKt = 0;

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
    # Redraw view
    #
    # @return void
    #
    updateView: func() {
        me._view.reDrawContent(me);
    },
};
