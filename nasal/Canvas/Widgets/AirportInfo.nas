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
# AirportInfo widget Model
#
gui.widgets.AirportInfo = {
    _CLASS: "AirportInfo",

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

        var obj = gui.Widget.new(gui.widgets.AirportInfo, cfg);
        obj._focus_policy = obj.NoFocus;
        obj._setView(style.createWidget(parent, "airport-info-view", cfg));

        obj._valueMarginX = 110;
        obj._airport = nil;
        obj._aptMagVar = nil;

        return obj;
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
    # @param  ghost|nil  airport  The airport object.
    # @return ghost
    #
    setAirport: func(airport) {
        me._airport = airport;
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
    # Redraw view
    #
    # @return void
    #
    updateView: func() {
        me._view.reDrawContent(me);
    },

    #
    # Timer callback
    #
    # @return void
    #
    updateDynamicData: func() {
        me._view.updateDynamicData(me);
    },
};
