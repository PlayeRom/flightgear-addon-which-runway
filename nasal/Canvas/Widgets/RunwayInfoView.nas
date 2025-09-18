#
# Which Runway - Add-on for FlightGear
#
# Written and developer by Roman Ludwicki (PlayeRom, SP-ROM)
#
# Copyright (C) 2024 Roman Ludwicki
#
# RunwayInfoView widget is an Open Source project and it is licensed
# under the GNU Public License v3 (GPLv3)
#

#
# RunwayInfoView widget Model
#
gui.widgets.RunwayInfoView = {
    _CLASS: "RunwayInfoView",

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
        var me = gui.Widget.new(gui.widgets.RunwayInfoView, cfg);
        me._focus_policy = me.NoFocus;
        me._setView(style.createWidget(parent, "runway-info-view", me._cfg));

        me._runway = nil;
        me._aptMagVar = nil;

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
    # @param  double  aptMagVar  Airport  magnetic variation.
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
    updateView: func() {
        me._view.reDrawContent(me);
    },
};
