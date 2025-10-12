#
# Which Runway - Add-on for FlightGear
#
# Written and developer by Roman Ludwicki (PlayeRom, SP-ROM)
#
# Copyright (C) 2024 Roman Ludwicki
#
# WindRose widget is an Open Source project and it is licensed
# under the GNU Public License v3 (GPLv3)
#

#
# WindRose widget Model
#
gui.widgets.WindRose = {
    _CLASS: "WindRose",

    #
    # Constructor.
    #
    # @param  ghost  parent
    # @param  hash|nil  style
    # @param  hash|nil  cfg
    # @return ghost
    #
    new: func(parent, style = nil, cfg = nil) {
        style = style or canvas.style;
        cfg = Config.new(cfg);

        var obj = gui.Widget.new(gui.widgets.WindRose, cfg);
        obj._focus_policy = obj.NoFocus;
        obj._setView(style.createWidget(parent, "wind-rose-view", cfg));

        obj._radius = 175;
        obj._windDir = nil;
        obj._windKt = 0;
        obj._runway = nil;
        obj._runways = [];
        obj._maxRwyLength = 5000.0;
        obj._hwThreshold = 45;
        obj._xwThreshold = 90;

        return obj;
    },

    #
    # @param  double  hwThreshold  Headwind threshold.
    # @param  double  xwThreshold  Crosswind threshold.
    # @return ghost
    #
    setHwXwThresholds: func(hwThreshold = 45, xwThreshold = 90) {
        me._hwThreshold = hwThreshold;
        me._xwThreshold = xwThreshold;
        return me;
    },

    #
    # @param  double  radius  Radius in pixels.
    # @return ghost
    #
    setRadius: func(radius) {
        me._radius = radius;
        return me;
    },

    #
    # @param  double|nil  windDir  Wind direction in degrees. If nil then wind is variable.
    # @param  double  windKt  Wind speed in knots.
    # @return ghost
    #
    setWind: func(windDir, speedKt) {
        me._windDir = windDir;
        me._windKt = speedKt;
        return me;
    },

    #
    # @param  hash  runway  Object with runway data.
    # @return ghost
    #
    setRunway: func(runway) {
        me._runway = runway;
        return me;
    },

    #
    # @param  vector  runways  All runways.
    # #return ghost
    #
    setRunways: func(runways) {
        me._runways = runways;
        me._maxRwyLength = me._findMaxLengthRunway();
        return me;
    },

    #
    # @return double  Max runway length in meters.
    #
    _findMaxLengthRunway: func() {
        var maxLen = 0;
        foreach (var rwy; me._runways) {
            if (rwy.length > maxLen) {
                maxLen = rwy.length;
            }
        }

        # We artificially enlarge the runway so that the runway numbers can still fit within the wind rose.
        # For rose radius of 175 px the ratio 1.35 looks good.
        var ratio = (me._radius / 175) * 1.35;
        return maxLen * ratio;
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
