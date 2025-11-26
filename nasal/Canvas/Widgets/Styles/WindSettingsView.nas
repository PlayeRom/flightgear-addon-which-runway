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
# WindSettings widget View
#
DefaultStyle.widgets["wind-settings-view"] = {
    #
    # Constructor
    #
    # @param  hash  parent
    # @param  hash  cfg
    # @return void
    #
    new: func(parent, cfg) {
        me._root = parent.createChild("group", "wind-settings-view");

        me._colors = cfg.get("colors");

        me._fontSansBold = canvas.font_mapper("sans", "bold");

        me._draw = Draw.new(me._root, me._fontSansBold);

        me._svgImg = me._draw.createSvg("Textures/plane-top.svg");

        me._hwLine = me._draw.createPath()
            .setColor(me._colors.GREEN)
            .setFill(me._colors.GREEN)
            .setStroke(me._colors.GREEN)
            .setStrokeLineWidth(2);

        me._xwLine = me._draw.createPath()
            .setColor(me._colors.AMBER)
            .setFill(me._colors.AMBER)
            .setStroke(me._colors.AMBER)
            .setStrokeLineWidth(2);

        me._hwLabel = me._draw.createText("Headwind")
            .setAlignment("center-center")
            .setColor(me._colors.GREEN)
            .setFont(canvas.font_mapper("sans"))
            .setFontSize(12);

        me._xwLeftLabel = me._draw.createText("Crosswind\nLeft")
            .setAlignment("center-center")
            .setColor(me._colors.AMBER)
            .setFont(canvas.font_mapper("sans"))
            .setFontSize(12);

        me._xwRightLabel = me._draw.createText("Crosswind\nRight")
            .setAlignment("center-center")
            .setColor(me._colors.AMBER)
            .setFont(canvas.font_mapper("sans"))
            .setFontSize(12);

        me._twLabel = me._draw.createText("Tailwind")
            .setAlignment("center-center")
            .setColor(canvas.style.getColor("text_color"))
            .setFont(canvas.font_mapper("sans"))
            .setFontSize(12);
    },

    #
    # Callback called when user resized the window
    #
    # @param  ghost  model  WindSettings model.
    # @param  int  w, h  Width and height of widget
    # @return ghost
    #
    setSize: func(model, w, h) {
        me.reDrawContent(model);

        return me;
    },

    #
    # @param  ghost  model  WindSettings model.
    # @return void
    #
    update: func(model) {
    },

    #
    # @param  ghost  model  WindSettings model.
    # @return void
    #
    reDrawContent: func(model) {
        var centerX = model._radius;
        var centerY = model._radius;

        me._drawWindRose(model, centerX, centerY);

        var height = centerY * 2;

        # model.setLayoutMaximumSize([MAX_SIZE, height]);
        model.setLayoutMinimumSize([height, height]);
        model.setLayoutSizeHint([height, height]);
    },

    #
    # Draw wind rose.
    #
    # @param  ghost  model  WindSettings model.
    # @param  double  centerX  Center of wind rose in pixels.
    # @param  double  centerY  Center of wind rose in pixels.
    # @return void
    #
    _drawWindRose: func(model, centerX, centerY) {
        var spokeStepDeg = 10; # graduation lines every 10°
        var colorStroke = [0.2, 0.2, 0.2];

        me._draw.createPath()
            .circle(model._radius, centerX, centerY)
            .setColor(colorStroke)
            .setFill(colorStroke)
            .setStroke(colorStroke)
            .setStrokeLineWidth(1);

        me._svgImg.setScale(2);
        var (planeWidth, planeHeight) = me._svgImg.getSize();
        me._svgImg.setTranslation(
            centerX - (planeWidth * 0.5),
            centerY - (planeHeight * 0.5),
        );

        # Draw spokes every spokeStepDeg
        for (var deg = 0; deg < 360; deg += spokeStepDeg) {
            var rad = (deg - 90) * globals.D2R;
            var cosRad = math.cos(rad);
            var sinRad = math.sin(rad);

            var x1 = centerX + cosRad * (model._radius * 0.9);
            var y1 = centerY + sinRad * (model._radius * 0.9);
            var x2 = centerX + cosRad * model._radius;
            var y2 = centerY + sinRad * model._radius;

            me._draw.createPath()
                .moveTo(x1, y1)
                .lineTo(x2, y2)
                .setColor(colorStroke)
                .setFill(colorStroke)
                .setStroke(colorStroke)
                .setStrokeLineWidth(math.mod(deg, 30) == 0 ? 2 : 1);
        }

        me.updateView(model);
    },

    #
    # @param  ghost  model  WindSettings model.
    # @return void
    #
    updateView: func(model) {
        var centerX = model._radius;
        var centerY = model._radius;

        var hwThresholdRight = ( model._hwAngle - 90) * globals.D2R;
        var hwThresholdLeft  = (-model._hwAngle - 90) * globals.D2R;
        var endHw1X = centerX + model._radius * math.cos(hwThresholdRight);
        var endHw1Y = centerY + model._radius * math.sin(hwThresholdRight);

        var endHw2X = centerX + model._radius * math.cos(hwThresholdLeft);
        var endHw2Y = centerY + model._radius * math.sin(hwThresholdLeft);

        me._hwLine
            .reset()
            .moveTo(endHw1X, endHw1Y)
            .lineTo(centerX, centerY)
            .lineTo(endHw2X, endHw2Y);


        var xwThresholdRight = ( model._xwAngle - 90) * globals.D2R;
        var xwThresholdLeft  = (-model._xwAngle - 90) * globals.D2R;
        var endXw1X = centerX + model._radius * math.cos(xwThresholdRight);
        var endXw1Y = centerY + model._radius * math.sin(xwThresholdRight);

        var endXw2X = centerX + model._radius * math.cos(xwThresholdLeft);
        var endXw2Y = centerY + model._radius * math.sin(xwThresholdLeft);

        me._xwLine
            .reset()
            .moveTo(endXw1X, endXw1Y)
            .lineTo(centerX, centerY)
            .lineTo(endXw2X, endXw2Y);

        var textRadius = model._radius * 0.7;

        me._hwLabel.setTranslation(
            centerX + textRadius * math.cos((0 - 90) * globals.D2R),
            centerY + textRadius * math.sin((0 - 90) * globals.D2R),
        );

        me._xwLeftLabel.setTranslation(
            centerX + textRadius * math.cos(xwThresholdLeft - ((xwThresholdLeft - hwThresholdLeft) * 0.5)),
            centerY + textRadius * math.sin(xwThresholdLeft - ((xwThresholdLeft - hwThresholdLeft) * 0.5)),
        );

        me._xwRightLabel.setTranslation(
            centerX + textRadius * math.cos(xwThresholdRight - ((xwThresholdRight - hwThresholdRight) * 0.5)),
            centerY + textRadius * math.sin(xwThresholdRight - ((xwThresholdRight - hwThresholdRight) * 0.5)),
        );

        me._twLabel.setTranslation(
            centerX + textRadius * math.cos((180 - 90) * globals.D2R),
            centerY + textRadius * math.sin((180 - 90) * globals.D2R),
        );
    },
};
