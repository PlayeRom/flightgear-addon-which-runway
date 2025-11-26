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
    # @param  hash  parent
    # @param  hash|nil  style
    # @param  hash|nil  cfg
    # @return ghost
    #
    new: func(parent, style = nil, cfg = nil) {
        style = style or canvas.style;
        cfg = Config.new(cfg);

        var obj = gui.Widget.new(gui.widgets.WindLabel, cfg);
        obj._focus_policy = obj.NoFocus;
        obj._setView(style.createWidget(parent, "wind-label-view", cfg));

        obj._isWindData = false;
        obj._windDir = nil;
        obj._windKt = 0;
        obj._windGustKt = 0;

        return obj;
    },

    #
    # @param  bool  isWindData  Set true to confirm weather data. If false then wind will be draw as "n/a".
    # @return ghost
    #
    setIsWindData: func(isWindData) {
        me._isWindData = isWindData;
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
    updateView: func {
        me._view.reDrawContent(me);
    },
};
