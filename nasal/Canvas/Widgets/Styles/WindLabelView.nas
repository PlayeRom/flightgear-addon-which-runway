#
# Which Runway - Add-on for FlightGear
#
# Written and developer by Roman Ludwicki (PlayeRom, SP-ROM)
#
# Copyright (C) 2024 Roman Ludwicki
#
# WindLabel widget is an Open Source project and it is licensed
# under the GNU Public License v3 (GPLv3)
#

#
# WindLabel widget View.
#
DefaultStyle.widgets["wind-label-view"] = {
    #
    # Constructor.
    #
    # @param  ghost  parent
    # @param  hash  cfg
    # @return void
    #
    new: func(parent, cfg) {
        me._root = parent.createChild("group", "wind-label-view");

        me._draw = Draw.new(me._root);

        me._windText = me._draw.createText("Wind")
            .setTranslation(0, 0)
            .setColor(whichRunway.Colors.BLUE)
            .setFontSize(20)
            .setFont(canvas.font_mapper("sans", "bold"));
    },

    #
    # Callback called when user resized the window.
    #
    # @param  ghost  model  WindLabel model.
    # @param  int  w, h  Width and height of widget.
    # @return ghost
    #
    setSize: func(model, w, h) {
        me.reDrawContent(model);

        return me;
    },

    #
    # @param  ghost  model  WindLabel model.
    # @return void
    #
    update: func(model) {
        # nothing here
    },

    #
    # @param  ghost  model  WindLabel model.
    # @return void
    #
    reDrawContent: func(model) {
        me._windText.setText("Wind " ~ me._getWindInfoText(model));

        var height = me._draw.shiftY(me._windText, 0);

        # model.setLayoutMaximumSize([MAX_SIZE, y]);
        model.setLayoutMinimumSize([model._size[0], height]);
        model.setLayoutSizeHint([model._size[0], height]);
    },

    #
    # @param  ghost  model  WindLabel model.
    # @return string
    #
    _getWindInfoText: func(model) {
        if (!model._isMetarData) {
            return "n/a";
        }

        var windDir = model._windDir == nil
            ? "variable"
            : sprintf("%d°", math.round(model._windDir));

        var wind = windDir ~ sprintf(" at %d kts", math.round(model._windKt));

        var gust = math.round(model._windGustKt);
        if (gust > 0) {
            return wind ~ sprintf(" with gust at %d kts", gust);
        }

        return wind;
    },
};
