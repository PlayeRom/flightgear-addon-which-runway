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
# MessageLabel widget View
#
DefaultStyle.widgets["message-label-view"] = {
    #
    # Constructor
    #
    # @param  hash  parent
    # @param  hash  cfg
    # @return void
    #
    new: func(parent, cfg) {
        me._root = parent.createChild("group", "message-labe-view");

        me._colors = cfg.get("colors");

        me._draw = Draw.new(me._root);

        me._text = me._draw.createText()
            .setColor(style.getColor("text_color"))
            .setAlignment("center-center")
            .setFontSize(20);
    },

    #
    # Callback called when user resized the window
    #
    # @param  ghost  model  MessageLabel model
    # @param  int  w, h  Width and height of widget
    # @return ghost
    #
    setSize: func(model, w, h) {
        me.reDrawContent(model);

        return me;
    },

    #
    # @param  ghost  model  MessageLabel model
    # @return void
    #
    update: func(model) {
        # nothing here
    },

    #
    # @param  ghost  model  MessageLabel model
    # @return void
    #
    reDrawContent: func(model) {
        if (model._text != nil) {
            me._text.setText(model._text)
                .setColor(model._isError ? me._colors.RED : style.getColor("text_color"))
                .setTranslation(model._size[0] / 2, model._size[1] / 2);
        }

        var width = me._text.getSize()[0];
        var height = me._text.getSize()[1];

        # model.setLayoutMaximumSize([MAX_SIZE, y]);
        model.setLayoutMinimumSize([width, height]);
        model.setLayoutSizeHint([width, height]);
    },
};
