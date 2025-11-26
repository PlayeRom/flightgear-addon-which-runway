#
# Which Runway - Add-on for FlightGear
#
# Written and developer by Roman Ludwicki (PlayeRom, SP-ROM)
#
# Copyright (C) 2024 Roman Ludwicki
#
# WindSettings widget is an Open Source project and it is licensed
# under the GNU Public License v3 (GPLv3)
#

#
# WindSettings widget Model
#
gui.widgets.WindSettings = {
    _CLASS: "WindSettings",

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

        var obj = gui.Widget.new(gui.widgets.WindSettings, cfg);
        obj._focus_policy = obj.NoFocus;
        obj._setView(style.createWidget(parent, "wind-settings-view", cfg));

        obj._radius = 175;
        obj._hwAngle = 45;
        obj._xwAngle = 90;

        return obj;
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
    # @param  int  hwAngle  Headwind threshold angle.
    # @return ghost
    #
    setHwAngle: func(hwAngle = 45) {
        me._hwAngle = hwAngle;
        return me;
    },

    #
    # @param  int  hwAngle  Crosswind threshold angle.
    # @return ghost
    #
    setXwAngle: func(xwAngle = 90) {
        me._xwAngle = xwAngle;
        return me;
    },

    #
    # Redraw view.
    #
    # @return ghost
    #
    updateView: func {
        me._view.updateView(me);
        return me;
    },
};
