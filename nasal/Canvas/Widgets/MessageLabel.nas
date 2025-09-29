#
# Which Runway - Add-on for FlightGear
#
# Written and developer by Roman Ludwicki (PlayeRom, SP-ROM)
#
# Copyright (C) 2024 Roman Ludwicki
#
# MessageLabel widget is an Open Source project and it is licensed
# under the GNU Public License v3 (GPLv3)
#

#
# MessageLabel widget Model
#
gui.widgets.MessageLabel = {
    _CLASS: "MessageLabel",

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
        var me = gui.Widget.new(gui.widgets.MessageLabel, cfg);
        me._focus_policy = me.NoFocus;
        me._setView(style.createWidget(parent, "message-label-view", me._cfg));

        me._text = nil;
        me._isError = false;

        return me;
    },

    #
    # @param  string  text  Message text.
    # @param  bool  isError
    # @return ghost
    #
    setText: func(text, isError = false) {
        me._text = text;
        me._isError = isError;
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
