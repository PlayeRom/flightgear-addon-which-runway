#
# Which Runway - Add-on for FlightGear
#
# Written and developer by Roman Ludwicki (PlayeRom, SP-ROM)
#
# Copyright (C) 2024 Roman Ludwicki
#
# WindRoseView widget is an Open Source project and it is licensed
# under the GNU Public License v3 (GPLv3)
#

#
# WindRoseView widget Model
#
gui.widgets.WindRoseView = {
    _CLASS: "WindRoseView",

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
        var me = gui.Widget.new(gui.widgets.WindRoseView, cfg);
        me._focus_policy = me.NoFocus;
        me._setView(style.createWidget(parent, "wind-rose-view", me._cfg));

        me._radius = 175;
        me._windDir = nil;
        me._windKt = 0;
        me._runway = nil;
        me._runways = [];
        me._maxRwyLength = 5000.0;

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
