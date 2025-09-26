#
# Which Runway - Add-on for FlightGear
#
# Written and developer by Roman Ludwicki (PlayeRom, SP-ROM)
#
# Copyright (C) 2024 Roman Ludwicki
#
# RwyUseInfo widget is an Open Source project and it is licensed
# under the GNU Public License v3 (GPLv3)
#

#
# RwyUseInfo widget View
#
DefaultStyle.widgets["rwy-use-info-view"] = {
    #
    # Constructor
    #
    # @param  ghost  parent
    # @param  hash  cfg
    # @return void
    #
    new: func(parent, cfg) {
        me._root = parent.createChild("group", "rwy-use-info-view");

        me._colors = cfg.get("colors");

        me._fontSansRegular = canvas.font_mapper("sans");
        me._fontSansBold    = canvas.font_mapper("sans", "bold");

        me._draw = Draw.new(me._root, me._fontSansBold);
        var fontSize = 14;

        me._LABEL = 0;
        me._VAL   = 1;
        me._UNIT  = 2;
        me._VAL2  = 3;
        me._UNIT2 = 4;

        me._utcTime = [
            me._draw.createTextLabel("UTC Time:"),
            me._draw.createTextValue("00:00"),
        ];

        me._tailwind = [
            me._draw.createTextLabel("Max tailwind:", me._colors.BLUE).setFontSize(fontSize),
            me._draw.createTextValue("n/a", me._colors.BLUE).setFontSize(fontSize),
            me._draw.createTextUnit("kts", me._colors.BLUE).setFontSize(fontSize),
        ];

        me._crosswind = [
            me._draw.createTextLabel("Max crosswind:", me._colors.BLUE).setFontSize(fontSize),
            me._draw.createTextValue("n/a", me._colors.BLUE).setFontSize(fontSize),
            me._draw.createTextUnit("kts", me._colors.BLUE).setFontSize(fontSize),
        ];

        me._traffic = [
            me._draw.createTextLabel("Traffic:").setFontSize(fontSize),
            me._draw.createTextValue("n/a").setFontSize(fontSize),
        ];

        me._schedule = [
            me._draw.createTextLabel("Schedule:").setFontSize(fontSize),
            me._draw.createTextValue("n/a").setFontSize(fontSize),
        ];

        me._contentHeight = nil;
    },

    #
    # Callback called when user resized the window.
    #
    # @param  ghost  model  RwyUseInfo model.
    # @param  int  w, h  Width and height of widget.
    # @return ghost
    #
    setSize: func(model, w, h) {
        me.reDrawContent(model);

        return me;
    },

    #
    # @param  ghost  model  RwyUseInfo model.
    # @return void
    #
    update: func(model) {
        # nothing here
    },

    #
    # Set remembered content height to nil for recalculate translations during redraw.
    #
    # @param  ghost  model  AirportInfo model.
    # @return void
    #
    resetContentHeight: func(model) {
        me._contentHeight = nil;
    },

    #
    # @param  ghost  model  RwyUseInfo model.
    # @return void
    #
    reDrawContent: func(model) {
        if (me._contentHeight == nil) {
            me._contentHeight = me._setTranslations(model);
        }

        me._drawInfo(model);

        # model.setLayoutMaximumSize([model._size[0], me._contentHeight]);
        model.setLayoutMinimumSize([model._size[0], me._contentHeight]);
        model.setLayoutSizeHint([model._size[0], me._contentHeight]);
    },

    #
    # @param  ghost  model  RwyUseInfo model.
    # @return double  New Y position.
    #
    _setTranslations: func(model) {
        var x = 0;
        var y = 0;

        y += me._draw.setTextTranslations(y, me._utcTime, model._valueMarginX);
        y += me._draw.setTextTranslations(y, me._tailwind, model._valueMarginX);
        y += me._draw.setTextTranslations(y, me._crosswind, model._valueMarginX);
        y += me._draw.setTextTranslations(y, me._traffic, model._valueMarginX);
        y += me._draw.setTextTranslations(y, me._schedule, model._valueMarginX, true);

        return y;
    },

    #
    # @param  ghost  model  RwyUseInfo model.
    # @return void
    #
    _drawInfo: func(model) {
        me._utcTime[me._VAL].setText(model._utcTime);

        me._tailwind[me._VAL].setText(sprintf("%.0f", model._maxTail));
        var (xTT, yTT) = me._tailwind[me._VAL].getTranslation();
        me._draw.setTextTranslations(yTT, me._tailwind, model._valueMarginX);

        me._crosswind[me._VAL].setText(sprintf("%.0f", model._maxCross));
        var (xTC, yTC) = me._crosswind[me._VAL].getTranslation();
        me._draw.setTextTranslations(yTC, me._crosswind, model._valueMarginX);

        me._traffic[me._VAL].setText(model._traffic or "n/a");
        me._schedule[me._VAL].setText(model._schedule or "n/a");
    },
};
