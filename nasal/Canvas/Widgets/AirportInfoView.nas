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
# AirportInfoView widget Model
#
gui.widgets.AirportInfoView = {
    _CLASS: "AirportInfoView",

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
        var me = gui.Widget.new(gui.widgets.AirportInfoView, cfg);
        me._focus_policy = me.NoFocus;
        me._setView(style.createWidget(parent, "airport-info-view", me._cfg));

        me._airport = nil;
        me._aptMagVar = nil;

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
};
