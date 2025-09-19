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
# PressureLabel widget View.
#
DefaultStyle.widgets["pressure-label"] = {
    #
    # Constructor.
    #
    # @param  ghost  parent
    # @param  hash  cfg
    # @return void
    #
    new: func(parent, cfg) {
        me._root = parent.createChild("group", "pressure-label");

        me._draw = Draw.new(me._root);

        me._label    = me._draw.createTextLabel("QNH:");
        me._inHgVal  = me._draw.createTextValue("n/a");
        me._inHgUnit = me._draw.createTextUnit("inHg /");
        me._hPaVal   = me._draw.createTextValue("n/a").setAlignment("right-baseline");
        me._hPaUnit  = me._draw.createTextUnit("hPa /");
        me._mmHgVal  = me._draw.createTextValue("n/a");
        me._mmHgUnit = me._draw.createTextUnit("mmHg");
    },

    #
    # Callback called when user resized the window.
    #
    # @param  ghost  model  PressureLabel model.
    # @param  int  w, h  Width and height of widget.
    # @return ghost
    #
    setSize: func(model, w, h) {
        me.reDrawContent(model);

        return me;
    },

    #
    # @param  ghost  model  PressureLabel model.
    # @return void
    #
    update: func(model) {
        # nothing here
    },

    #
    # Set remembered content height to nil for recalculate translations during redraw.
    #
    # @param  ghost  model  AirportInfoView model.
    # @return void
    #
    resetContentHeight: func(model) {
        me._contentHeight = nil;
    },

    #
    # @param  ghost  model  PressureLabel model.
    # @return void
    #
    reDrawContent: func(model) {
        var x = 0;
        var y = 0;

        me._inHgUnit.setVisible(false);
        me._hPaVal.setVisible(false);
        me._hPaUnit.setVisible(false);
        me._mmHgVal.setVisible(false);
        me._mmHgUnit.setVisible(false);

        y += model._inHg == nil
            ? me._printLineAtmosphericPressureNone(x, y, model)
            : me._printLineAtmosphericPressure(x, y, model);

        # model.setLayoutMaximumSize([MAX_SIZE, y]);
        model.setLayoutMinimumSize([model._size[0], y]);
        model.setLayoutSizeHint([model._size[0], y]);
    },

    #
    # @param  double  x  Init position of x.
    # @param  double  y  Init position of y.
    # @param  ghost  model  PressureLabel model.
    # @return double  New Y position.
    #
    _printLineAtmosphericPressureNone: func(x, y, model) {
        me._label.setTranslation(x, y);

        x += model._valueMarginX;
        me._inHgVal.setText("n/a").setTranslation(x, y);

        return me._draw.shiftY(me._inHgVal, 0);
    },

    #
    # @param  double  x  Init position of x.
    # @param  double  y  Init position of y.
    # @param  ghost  model  PressureLabel model.
    # @return double  New Y position.
    #
    _printLineAtmosphericPressure: func(x, y, model) {
        me._label.setTranslation(x, y);

        # inHg
        x += model._valueMarginX;
        me._inHgVal.setText(sprintf("%.02f", model._inHg)).setTranslation(x, y);
        x += me._draw.shiftX(me._inHgVal);
        me._inHgUnit.setTranslation(x, y).setVisible(true);

        # hPa
        x += 82;
        me._hPaVal.setText(sprintf("%d", model._hPa)).setTranslation(x, y).setVisible(true);
        x += 5;
        me._hPaUnit.setTranslation(x, y).setVisible(true);

        # mmHg
        x += 42;
        me._mmHgVal.setText(sprintf("%d", model._mmHg)).setTranslation(x, y).setVisible(true);
        x += me._draw.shiftX(me._mmHgVal);
        me._mmHgUnit.setTranslation(x, y).setVisible(true);

        return me._draw.shiftY(me._mmHgUnit, 0);
    },
};
