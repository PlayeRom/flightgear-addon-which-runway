#
# Which Runway - Add-on for FlightGear
#
# Written and developer by Roman Ludwicki (PlayeRom, SP-ROM)
#
# Copyright (C) 2024 Roman Ludwicki
#
# RunwayInfo widget is an Open Source project and it is licensed
# under the GNU Public License v3 (GPLv3)
#

#
# RunwayInfo widget Model
#
gui.widgets.RunwayInfo = {
    _CLASS: "RunwayInfo",

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

        var obj = gui.Widget.new(gui.widgets.RunwayInfo, cfg);
        obj._focus_policy = obj.NoFocus;
        obj._setView(style.createWidget(parent, "runway-info-view", cfg));

        obj._valueMarginX = 110;
        obj._runway = nil;
        obj._aptMagVar = nil;
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
    # Set margin between label and value.
    #
    # @param  int  margin
    # @return hash
    #
    setMarginForValue: func(margin) {
        me._valueMarginX = margin;
        me._view.resetContentHeight(me);
        return me;
    },

    #
    # @param  hash  runway
    # @return ghost
    #
    setRunwayData: func(runway) {
        me._runway = runway;
        return me;
    },

    #
    # @param  double  aptMagVar  Airport magnetic variation.
    # @return ghost
    #
    setAirportMagVar: func(aptMagVar) {
        me._aptMagVar = aptMagVar;
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
