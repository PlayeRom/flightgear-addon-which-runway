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
    # @param  vector  runwaysData  All runways.
    # @return void
    #
    drawWindRose: func(centerX, centerY, radius, windDir, windKt, runway, runwaysData) {
        me._draw.createClipContent(
            top   : centerY - (radius * 1.45),
            right : centerX + (radius * 1.45),
            bottom: centerY + (radius * 1.45),
            left  : centerX - (radius * 1.45),
        );
        me._draw.enableClipContent();

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

        var drawn = [runway.rwyId]; # array of drawn runway ids to avoid drawing reciprocal twice
        if (runway.reciprocal != nil) {
            append(drawn, runway.reciprocal.id);
        }

        foreach (var rwy; runwaysData) {
            if (contains(drawn, rwy.rwyId)) {
                continue; # already drawn
            }

            me._drawRunway(centerX, centerY, rwy, runway);

            if (rwy.reciprocal != nil) {
                append(drawn, rwy.reciprocal.id);
            }
        }

        # Draw main runway in center of wind rose
        me._drawRunway(centerX, centerY, runway);

        me._drawWindArrow(centerX, centerY, windDir, windKt);

        me._draw.disableClipContent();
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
    # @param  hash  rwy  Runway object to draw in center.
    # @param  hash|nil  refRwy  Reference runway as main runway when draw another runway around.
    # @return void
    #
    _drawRunway: func(centerX, centerY, rwy, refRwy = nil) {
        var isMainRwy = refRwy == nil;

        # Scale: meters → pixels
        var MAX_RWY_LENGTH = 5000.0;
        var scale = (me._radius * 2) / MAX_RWY_LENGTH;

        # Runway length and width in pixels
        var lenPix   = rwy.length * scale;
        var widthPix = rwy.width  * scale;

        var METERS_PER_DEG_LAT   = 111320.0;
        var EARTH_EQUATOR_METERS = 40075000.0;

        var xStart = 0;
        var yStart = 0;
        var xEnd   = 0;
        var yEnd   = 0;

        var angleRad = (rwy.heading - 90) * globals.D2R;
        var cosRad = math.cos(angleRad);
        var sinRad = math.sin(angleRad);

        if (isMainRwy) {
            # The main runway in the center of the wind rose
            xStart = centerX - cosRad * (lenPix / 2);
            yStart = centerY - sinRad * (lenPix / 2);
            xEnd   = centerX + cosRad * (lenPix / 2);
            yEnd   = centerY + sinRad * (lenPix / 2);
        } else {
            # Convert runway center to meters relative to refRwy.
            var refRwyReciprocal = me._getReciprocalLatLon(refRwy);
            var refCenterLat = (refRwy.lat + refRwyReciprocal.lat()) / 2.0;
            var refCenterLon = (refRwy.lon + refRwyReciprocal.lon()) / 2.0;

            var rwyReciprocal = me._getReciprocalLatLon(rwy);
            var thisCenterLat = (rwy.lat + rwyReciprocal.lat()) / 2.0;
            var thisCenterLon = (rwy.lon + rwyReciprocal.lon()) / 2.0;

            # Difference in meters.
            var lat0 = (refCenterLat + thisCenterLat) / 2.0;
            var mPerLon = (EARTH_EQUATOR_METERS * math.cos(lat0 * globals.D2R)) / 360.0;

            var dXM = (thisCenterLat - refCenterLat) * METERS_PER_DEG_LAT;
            var dYM = (thisCenterLon - refCenterLon) * mPerLon;

            # Translation to pixels relative to the center of the wind rose.
            centerX = centerX + dYM * scale;
            centerY = centerY - dXM * scale;

            # The ends of the runway along the runway heading.
            xStart = centerX - cosRad * (lenPix / 2);
            yStart = centerY - sinRad * (lenPix / 2);
            xEnd   = centerX + cosRad * (lenPix / 2);
            yEnd   = centerY + sinRad * (lenPix / 2);
        }

        # Draw runway
        me._draw.createPath()
            .moveTo(xStart, yStart)
            .lineTo(xEnd, yEnd)
            .setColor(isMainRwy ? [0, 0, 0] : [0.8, 0.8, 0.8])
            .setFill(isMainRwy ? [0, 0, 0] : [0.8, 0.8, 0.8])
            .setStrokeLineWidth(widthPix);

        # Threshold markings
        if (rwy.reciprocal != nil) {
            # For reciprocal
            me._drawRunwayId(centerX, centerY, rwy.reciprocal.id, rwy.normDiffDeg, angleRad, lenPix, false, isMainRwy);
        }

        angleRad = (rwy.heading + 90) * globals.D2R;
        me._drawRunwayId(centerX, centerY, rwy.rwyId, rwy.normDiffDeg, angleRad, lenPix, isMainRwy, isMainRwy);
    },

    #
    # @param  hash  runway
    # @return hash  The geo.Coord object.
    #
    _getReciprocalLatLon: func(runway) {
        var coord = geo.Coord.new();

        if (runway.reciprocal == nil) {
            # Helipads do not have reciprocal, so we calculate them by shifting
            # by the heading and the length of the helipad.
            coord.set_latlon(runway.lat, runway.lon);
            coord.apply_course_distance(runway.heading, runway.length);
        } else {
            coord.set_latlon(runway.reciprocal.lat, runway.reciprocal.lon);
        }

        return coord;
    },

    #
    # Draw runway id near runway end.
    #
    # @param  double  x, y  Center of wind rose in pixels.
    # @param  string  rwyId  Runway id to draw.
    # @param  double  angleRad  Angle of runway in radians.
    # @param  double  lenPix  Length of runway in pixels.
    # @param  bool  isMainThreshold
    # @param  bool  isMainRwy
    # @return void
    #
    _drawRunwayId: func(x, y, rwyId, normDiffDeg, angleRad, lenPix, isMainThreshold, isMainRwy) {
        var color = Colors.DEFAULT_TEXT;
        if (isMainThreshold) {
            color = me._geWindColorByDir(normDiffDeg);
        } elsif (!isMainRwy) {
            color = [0.7, 0.7, 0.7];
        }

        var text = me._draw.createText(rwyId)
            .setFontSize(isMainThreshold ? 16 : 12)
            .setColor(color)
            .setAlignment("center-center")
            .setTranslation(
                x + math.cos(angleRad) * (lenPix / 2 + (isMainThreshold ? 16 : 12)),
                y + math.sin(angleRad) * (lenPix / 2 + (isMainThreshold ? 16 : 12)),
            );

        if (isMainThreshold) {
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
