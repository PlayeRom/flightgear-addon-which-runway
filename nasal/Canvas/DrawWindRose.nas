#
# Which runway - Add-on for FlightGear
#
# Written and developer by Roman Ludwicki (PlayeRom, SP-ROM)
#
# Copyright (C) 2025 Roman Ludwicki
#
# Which Runway is an Open Source project and it is licensed
# under the GNU Public License v3 (GPLv3)
#

#
# Class do draw wind rose on canvas
#
var DrawWindRose = {
    #
    # Constructor
    #
    # @param  ghost  canvasContent  Canvas object where wind rose will be drawn.
    # @return me
    #
    new: func(canvasContent) {
        var me = { parents: [DrawWindRose] };

        me._canvas = canvasContent;

        me._textColor = [0.1, 0.1, 0.1];
        me._colorWind = [0.0, 0.5, 1.0];
        me._windLineWidth = 2;
        me._radius = 0;

        return me;
    },

    #
    # Destructor
    #
    # @return void
    #
    del: func() {
    },

    #
    # Draw wind rose.
    #
    # @param  double  centerX  X coordinate of center in pixels.
    # @param  double  centerY  Y coordinate of center in pixels.
    # @param  double  radius  Radius in pixels.
    # @param  double|nil  windDir  Wind direction in degrees.
    # @param  double|nil  windKt  Wind speed in knots.
    # @param  hash  runway  Object with runway data.
    # @return void
    #
    drawWindRose: func(centerX, centerY, radius, windDir, windKt, runway) {
        me._radius = radius;

        var spokeStepDeg = 10; # graduation lines every 10°
        var colorStroke = [0.2, 0.2, 0.2];

        # Draw spokes every spokeStepDeg
        for (var a = 0; a < 360; a += spokeStepDeg) {
            var rad = (a - 90) * globals.D2R;
            var x1 = centerX + math.cos(rad) * (me._radius * 0.9);
            var y1 = centerY + math.sin(rad) * (me._radius * 0.9);
            var x2 = centerX + math.cos(rad) * me._radius;
            var y2 = centerY + math.sin(rad) * me._radius;

            me._canvas.createChild("path")
                .moveTo(x1, y1)
                .lineTo(x2, y2)
                .setColor(colorStroke)
                .setFill(colorStroke)
                .setStroke(colorStroke)
                .setStrokeLineWidth(math.mod(a, 30) == 0 ? 2 : 1);

            var markPadding = 20;

            if (math.mod(a, 90) == 0) {
                # Directional descriptions (N, E, S, W) every 90°

                var label = "";
                     if (a == 0)   label = "N";
                else if (a == 90)  label = "E";
                else if (a == 180) label = "S";
                else               label = "W";

                me._canvas.createChild("text")
                    .setAlignment("center-center")
                    .setText(label)
                    .setTranslation(
                        centerX + math.cos(rad) * (me._radius + markPadding),
                        centerY + math.sin(rad) * (me._radius + markPadding),
                    )
                    .setColor(me._textColor)
                    .setFontSize(18);
            } else if (math.mod(a, 30) == 0) {
                # Direction numbers every 30°

                me._canvas.createChild("text")
                    .setAlignment("center-center")
                    .setText(sprintf("%d", a))
                    .setTranslation(
                        centerX + math.cos(rad) * (me._radius + markPadding),
                        centerY + math.sin(rad) * (me._radius + markPadding),
                    )
                    .setColor([0.4, 0.4, 0.4])
                    .setFontSize(16);
            }
        }

        # var drawn = []; # array of drawn runway ids to avoid drawing reciprocal twice
        # foreach (var rwy; runwaysData) {
        #     if (contains(drawn, rwy.rwyId)) {
        #         continue; # already drawn
        #     }
        #     me._drawRunway(centerX, centerY, me._radius, airport, rwy);

        #     append(drawn, rwy.reciprocalId);
        # }
        me._drawRunway(centerX, centerY, runway);

        me._drawWindArrow(centerX, centerY, windDir, windKt);
    },

    #
    # Draw runway on wind rose.
    #
    # @param  double  centerX  X coordinate of center in pixels.
    # @param  double  centerY  Y coordinate of center in pixels.
    # @param  hash  runway  Object with runway data.
    # @return void
    #
    _drawRunway: func(centerX, centerY, runway) {
        # Scaling the length and width of the strip to the rose pixels
        # Length in pixels - proportion to the largest stripe or radius of the rose
        var maxRwyLength = 5000.0;  # e.g. the largest runway in meters at your airport
        var lenPix = (runway.length / maxRwyLength) * me._radius * 2;
        var widthPix = (runway.width / 60.0) * 8; # width, 60 m = max 8 px

        # Calculating the runway angle in radians
        var angleRad = (runway.heading - 90) * globals.D2R;

        # Ends of the lines (the center of the rose as a reference point)
        var xStart = centerX - math.cos(angleRad) * (lenPix / 2);
        var yStart = centerY - math.sin(angleRad) * (lenPix / 2);
        var xEnd   = centerX + math.cos(angleRad) * (lenPix / 2);
        var yEnd   = centerY + math.sin(angleRad) * (lenPix / 2);

        # Runway
        me._canvas.createChild("path")
            .moveTo(xStart, yStart)
            .lineTo(xEnd, yEnd)
            .setColor([0,0,0])
            .setFill([0,0,0])
            .setStroke([0.5, 0.5, 0.5])
            .setStrokeLineWidth(widthPix)
            ;

        # Add runway labels
        me._drawRunwayId(centerX, centerY, runway.reciprocalId, runway.normDiffDeg, angleRad, lenPix);
        angleRad = (runway.heading + 90) * globals.D2R;
        me._drawRunwayId(centerX, centerY, runway.rwyId, runway.normDiffDeg, angleRad, lenPix, true);
    },

    #
    # Draw runway id near runway end.
    #
    # @param  double  x, y  Center of wind rose in pixels.
    # @param  string  rwyId  Runway id to draw.
    # @param  double  angleRad  Angle of runway in radians.
    # @param  double  lenPix  Length of runway in pixels.
    # @return void
    #
    _drawRunwayId: func(x, y, rwyId, normDiffDeg, angleRad, lenPix, isHighlighted = false) {
        var text = me._canvas.createChild("text")
            .setText(rwyId)
            .setFontSize(isHighlighted ? 16 : 12)
            .setColor(isHighlighted ? me._geWindColorByDir(normDiffDeg) : [0, 0, 0])
            .setAlignment("center-center")
            .setTranslation(
                x + math.cos(angleRad) * (lenPix / 2 + 12),
                y + math.sin(angleRad) * (lenPix / 2 + 12),
            );

        if (isHighlighted) {
            text.setFont(Fonts.SANS_BOLD);
        }
    },

    #
    # @param  int|nil  normDiffDeg
    # @return vector  RGB color.
    #
    _geWindColorByDir: func(normDiffDeg) {
             if (normDiffDeg == nil)                      return [0, 0, 0];
        else if (normDiffDeg <= Wind.HEADWIND_THRESHOLD)  return Colors.HEADWIND;
        else if (normDiffDeg <= Wind.CROSSWIND_THRESHOLD) return Colors.CROSSWIND;
        else                                              return [0, 0, 0];
    },

    #
    # Draw wind arrow.
    #
    # @param  double  centerX  Center of wind rose in pixels.
    # @param  double  centerY  Center of wind rose in pixels.
    # @param  double|nil  windDir  Wind direction in degrees.
    # @param  double|nil  windKt  Wind speed in knots.
    # @return void
    #
    _drawWindArrow: func(centerX, centerY, windDir, windKt) {
        if (windDir == nil or windKt == nil) {
            return;
        }

        var windRad = (windDir - 90) * globals.D2R;  # direction in radians

        # Line from opposite side to end (full diameter)
        var xStart = centerX - math.cos(windRad) * me._radius;
        var yStart = centerY - math.sin(windRad) * me._radius;
        var xEnd   = centerX + math.cos(windRad) * me._radius;
        var yEnd   = centerY + math.sin(windRad) * me._radius;

        me._canvas.createChild("path")
            .moveTo(xStart, yStart)
            .lineTo(xEnd, yEnd)
            .setColor(me._colorWind)
            .setFill(me._colorWind)
            .setStroke(me._colorWind)
            .setStrokeLineWidth(me._windLineWidth);

        # Arrowhead
        windRad = (windDir + 90) * globals.D2R;
        var slenderness = 25;
        var left  = windRad + slenderness * globals.D2R;
        var right = windRad - slenderness * globals.D2R;

        # Arrowhead at the front of the line
        me._drawArrowhead(xStart, yStart, left, right);

        # Arrowhead at the end of the line
        me._drawArrowhead(xEnd, yEnd, left, right);

        # Text with values ​​(direction/speed)
        me._drawArrowWindLabel(xEnd, yEnd, centerX, centerY, windDir, windKt);
    },

    #
    # @param  double  xEnd
    # @param  double  yEnd
    # @param  double  centerX
    # @param  double  centerY
    # @param  double  windDir  Wind direction in degrees.
    # @param  double  windKt  Wind speed in knots.
    # @return void
    #
    _drawArrowWindLabel: func(xEnd, yEnd, centerX, centerY, windDir, windKt) {
        var margin = 50;  # distance from the end of the arrow

        # Vector from the center of the rose to the end of the arrow
        var dx = xEnd - centerX;
        var dy = yEnd - centerY;

        # Vector length
        var len = math.sqrt(dx * dx + dy * dy);

        # Normalization and displacement
        var xLabel = xEnd + (dx / len) * margin;
        var yLabel = yEnd + (dy / len) * margin;

        var info = sprintf("%03d° %d kt", windDir, math.round(windKt));
        me._canvas.createChild("text")
            .setText(info)
            .setTranslation(xLabel, yLabel)
            .setColor(me._colorWind)
            .setFontSize(11)
            .setAlignment("center-center");
    },

    #
    # @param  double  x
    # @param  double  y
    # @param  double  left
    # @param  double  right
    # @return void
    #
    _drawArrowhead: func(x, y, left, right) {
        var arrowLength = 12;

        # Left arrowhead line
        me._canvas.createChild("path")
            .moveTo(x, y)
            .lineTo(x - math.cos(left) * arrowLength, y - math.sin(left) * arrowLength)
            .setColor(me._colorWind)
            .setFill(me._colorWind)
            .setStroke(me._colorWind)
            .setStrokeLineWidth(me._windLineWidth);

        # Right arrowhead line
        me._canvas.createChild("path")
            .moveTo(x, y)
            .lineTo(x - math.cos(right) * arrowLength, y - math.sin(right) * arrowLength)
            .setColor(me._colorWind)
            .setFill(me._colorWind)
            .setStroke(me._colorWind)
            .setStrokeLineWidth(me._windLineWidth);
    },
};
