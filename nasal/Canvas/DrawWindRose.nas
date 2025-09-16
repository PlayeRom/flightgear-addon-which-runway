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
    # @param  hash  draw  Draw object.
    # @return hash
    #
    new: func(draw) {
        var me = { parents: [DrawWindRose] };

        me._draw = draw;

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
    # @param  double  windKt  Wind speed in knots.
    # @param  hash  runway  Object with runway data.
    # @return void
    #
    drawWindRose: func(centerX, centerY, radius, windDir, windKt, runway) {
        me._radius = radius;

        var spokeStepDeg = 10; # graduation lines every 10°
        var colorStroke = [0.2, 0.2, 0.2];

        # Draw spokes every spokeStepDeg
        for (var deg = 0; deg < 360; deg += spokeStepDeg) {
            var rad = (deg - 90) * globals.D2R;
            var cosRad = math.cos(rad);
            var sinRad = math.sin(rad);

            var x1 = centerX + cosRad * (me._radius * 0.9);
            var y1 = centerY + sinRad * (me._radius * 0.9);
            var x2 = centerX + cosRad * me._radius;
            var y2 = centerY + sinRad * me._radius;

            me._draw.createPath()
                .moveTo(x1, y1)
                .lineTo(x2, y2)
                .setColor(colorStroke)
                .setFill(colorStroke)
                .setStroke(colorStroke)
                .setStrokeLineWidth(math.mod(deg, 30) == 0 ? 2 : 1);

            var markPadding = 20;

            if (math.mod(deg, 90) == 0) {
                # Directional descriptions (N, E, S, W) every 90°
                me._draw.createText(me._getGeoDirMark(deg))
                    .setTranslation(
                        centerX + cosRad * (me._radius + markPadding),
                        centerY + sinRad * (me._radius + markPadding),
                    )
                    .setAlignment("center-center")
                    .setColor(Colors.DEFAULT_TEXT)
                    .setFontSize(18);
            } elsif (math.mod(deg, 30) == 0) {
                # Direction numbers every 30°
                me._draw.createText(Utils.toString(deg))
                    .setTranslation(
                        centerX + cosRad * (me._radius + markPadding),
                        centerY + sinRad * (me._radius + markPadding),
                    )
                    .setAlignment("center-center")
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
    # @param  int  deg
    # @return string
    #
    _getGeoDirMark: func(deg) {
           if (deg == 0)   return "N";
        elsif (deg == 90)  return "E";
        elsif (deg == 180) return "S";
        elsif (deg == 270) return "W";

        return "?";
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

        var cosRad = math.cos(angleRad);
        var sinRad = math.sin(angleRad);

        # Ends of the lines (the center of the rose as a reference point)
        var xStart = centerX - cosRad * (lenPix / 2);
        var yStart = centerY - sinRad * (lenPix / 2);
        var xEnd   = centerX + cosRad * (lenPix / 2);
        var yEnd   = centerY + sinRad * (lenPix / 2);

        # Runway
        me._draw.createPath()
            .moveTo(xStart, yStart)
            .lineTo(xEnd, yEnd)
            .setColor([0,0,0])
            .setFill([0,0,0])
            .setStroke([0.5, 0.5, 0.5])
            .setStrokeLineWidth(widthPix);

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
        var text = me._draw.createText(rwyId)
            .setFontSize(isHighlighted ? 16 : 12)
            .setColor(isHighlighted ? me._geWindColorByDir(normDiffDeg) : Colors.DEFAULT_TEXT)
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
           if (normDiffDeg == nil)                       return Colors.DEFAULT_TEXT;
        elsif (normDiffDeg <= Metar.HEADWIND_THRESHOLD)  return Colors.GREEN;
        elsif (normDiffDeg <= Metar.CROSSWIND_THRESHOLD) return Colors.AMBER;

        return Colors.DEFAULT_TEXT;
    },

    #
    # Draw wind arrow.
    #
    # @param  double  centerX  Center of wind rose in pixels.
    # @param  double  centerY  Center of wind rose in pixels.
    # @param  double|nil  windDir  Wind direction in degrees.
    # @param  double  windKt  Wind speed in knots.
    # @return void
    #
    _drawWindArrow: func(centerX, centerY, windDir, windKt) {
        if (windDir == nil) {
            return;
        }

        var windRad = (windDir - 90) * globals.D2R;  # direction in radians

        var cosRad = math.cos(windRad);
        var sinRad = math.sin(windRad);

        # Line from opposite side to end (full diameter)
        var xStart = centerX - cosRad * me._radius;
        var yStart = centerY - sinRad * me._radius;
        var xEnd   = centerX + cosRad * me._radius;
        var yEnd   = centerY + sinRad * me._radius;

        me._draw.createPath()
            .moveTo(xStart, yStart)
            .lineTo(xEnd, yEnd)
            .setColor(Colors.BLUE)
            .setFill(Colors.BLUE)
            .setStroke(Colors.BLUE)
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

        me._draw.createText(sprintf("%03d° %d kt", windDir, math.round(windKt)))
            .setTranslation(xLabel, yLabel)
            .setColor(Colors.BLUE)
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
        me._draw.createPath()
            .moveTo(x, y)
            .lineTo(x - math.cos(left) * arrowLength, y - math.sin(left) * arrowLength)
            .setColor(Colors.BLUE)
            .setFill(Colors.BLUE)
            .setStroke(Colors.BLUE)
            .setStrokeLineWidth(me._windLineWidth);

        # Right arrowhead line
        me._draw.createPath()
            .moveTo(x, y)
            .lineTo(x - math.cos(right) * arrowLength, y - math.sin(right) * arrowLength)
            .setColor(Colors.BLUE)
            .setFill(Colors.BLUE)
            .setStroke(Colors.BLUE)
            .setStrokeLineWidth(me._windLineWidth);
    },
};
