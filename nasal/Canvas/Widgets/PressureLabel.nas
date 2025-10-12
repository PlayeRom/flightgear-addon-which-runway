#
# Which Runway - Add-on for FlightGear
#
# Written and developer by Roman Ludwicki (PlayeRom, SP-ROM)
#
# Copyright (C) 2024 Roman Ludwicki
#
# PressureLabel widget is an Open Source project and it is licensed
# under the GNU Public License v3 (GPLv3)
#

#
# PressureLabel widget Model
#
gui.widgets.PressureLabel = {
    _CLASS: "PressureLabel",

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

        var obj = gui.Widget.new(gui.widgets.PressureLabel, cfg);
        obj._focus_policy = obj.NoFocus;
        obj._setView(style.createWidget(parent, "pressure-label-view", cfg));

        obj._valueMarginX = 110;
        obj._label = "QNH:";
        obj._inHg = nil;
        obj._hPa = nil;
        obj._mmHg = nil;

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
        return me;
    },

    #
    # Set label text.
    #
    # @param  text  Text of label.
    # @return hash
    #
    setLabel: func(text) {
        me._label = text;
        return me;
    },

    #
    # Set pressure value in inHg.
    #
    # @param  double  Pressure value in inHg.
    # @return hash
    #
    setInHg: func(inHg) {
        me._inHg = inHg;
        return me;
    },

    #
    # Set pressure value in hPa.
    #
    # @param  int  Pressure value in hPa.
    # @return hash
    #
    setHPa: func(hPa) {
        me._hPa = hPa;
        return me;
    },

    #
    # Set pressure value in mmHg.
    #
    # @param  int  Pressure value in mmHg.
    # @return hash
    #
    setMmHg: func(mmHg) {
        me._mmHg = mmHg;
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
