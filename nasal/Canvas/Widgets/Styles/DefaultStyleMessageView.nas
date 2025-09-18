#
# Which Runway - Add-on for FlightGear
#
# Written and developer by Roman Ludwicki (PlayeRom, SP-ROM)
#
# Copyright (C) 2024 Roman Ludwicki
#
# MessageView widget is an Open Source project and it is licensed
# under the GNU Public License v3 (GPLv3)
#

#
# MessageView widget View
#
DefaultStyle.widgets["message-view"] = {
    #
    # Constructor
    #
    # @param  ghost  parent
    # @param  hash  cfg
    # @return void
    #
    new: func(parent, cfg) {
        me._root = parent.createChild("group", "message-view");

        me._draw = Draw.new(me._root);

        me._text = me._draw.createText()
            .setColor(whichRunway.Colors.DEFAULT_TEXT)
            .setAlignment("center-center")
            .setFontSize(20);
    },

    #
    # Callback called when user resized the window
    #
    # @param  ghost  model  MessageView model
    # @param  int  w, h  Width and height of widget
    # @return ghost
    #
    setSize: func(model, w, h) {
        me.reDrawContent(model);

        return me;
    },

    #
    # @param  ghost  model  MessageView model
    # @return void
    #
    update: func(model) {
        # nothing here
    },

    #
    # @param  ghost  model  MessageView model
    # @return void
    #
    reDrawContent: func(model) {
        if (model._text != nil) {
            me._text.setText(model._text)
                .setColor(model._isError ? whichRunway.Colors.RED : whichRunway.Colors.DEFAULT_TEXT)
                .setTranslation(model._size[0] / 2, model._size[1] / 2);
        }

        # model.setLayoutMaximumSize([MAX_SIZE, y]);
        # model.setLayoutMinimumSize([model._size[0], y]);
        # model.setLayoutSizeHint([model._size[0], y]);
    },
};
