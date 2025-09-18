#
# Which Runway - Add-on for FlightGear
#
# Written and developer by Roman Ludwicki (PlayeRom, SP-ROM)
#
# Copyright (C) 2024 Roman Ludwicki
#
# WindRoseView widget is an Open Source project and it is licensed
# under the GNU Public License v3 (GPLv3)
#

#
# WindRoseView widget View
#
DefaultStyle.widgets["wind-rose-view"] = {
    #
    # Constructor
    #
    # @param  ghost  parent
    # @param  hash  cfg
    # @return void
    #
    new: func(parent, cfg) {
        me._root = parent.createChild("group", "wind-rose-view");

        # me._content = me._root.createChild("group", "clip-content")
        #     .set("clip-frame", Element.PARENT);

        me._draw = Draw.new(me._root);

        me._windLineWidth = 2;
    },

    #
    # Callback called when user resized the window
    #
    # @param  ghost  model  WindRoseView model.
    # @param  int  w, h  Width and height of widget
    # @return ghost
    #
    setSize: func(model, w, h) {
        me.reDrawContent(model);

        return me;
    },

    #
    # @param  ghost  model  WindRoseView model.
    # @return void
    #
    update: func(model) {
        # me._content.set("clip", "rect(0, " ~ model._size[0] ~ ", " ~ model._size[1] ~ ", 0)");
    },

    #
    # @param  ghost  model  WindRoseView model.
    # @return void
    #
    reDrawContent: func(model) {
        me._root.removeAllChildren();

        var centerX = model._radius * 1.45;
        var centerY = model._radius * 1.45;

        me._drawWindRose(model, centerX, centerY);

        var height = centerY * 2;

        # model.setLayoutMaximumSize([MAX_SIZE, height]);
        model.setLayoutMinimumSize([height, height]);
        model.setLayoutSizeHint([height, height]);
    },

    #
    # Draw wind rose.
    #
    # @param  ghost  model  WindRoseView model.
    # @param  double  centerX  Center of wind rose in pixels.
    # @param  double  centerY  Center of wind rose in pixels.
    # @return void
    #
    _drawWindRose: func(model, centerX, centerY) {
        var spokeStepDeg = 10; # graduation lines every 10°
        var colorStroke = [0.2, 0.2, 0.2];

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

            var markPadding = 20;

            if (math.mod(deg, 90) == 0) {
                # Directional descriptions (N, E, S, W) every 90°
                me._draw.createText(me._getGeoDirMark(deg))
                    .setTranslation(
                        centerX + cosRad * (model._radius + markPadding),
                        centerY + sinRad * (model._radius + markPadding),
                    )
                    .setAlignment("center-center")
                    .setColor(whichRunway.Colors.DEFAULT_TEXT)
                    .setFontSize(18);
            } elsif (math.mod(deg, 30) == 0) {
                # Direction numbers every 30°
                me._draw.createText(deg)
                    .setTranslation(
                        centerX + cosRad * (model._radius + markPadding),
                        centerY + sinRad * (model._radius + markPadding),
                    )
                    .setAlignment("center-center")
                    .setColor([0.4, 0.4, 0.4])
                    .setFontSize(16);
            }
        }

        var drawn = [model._runway.rwyId]; # array of drawn runway ids to avoid drawing reciprocal twice
        if (model._runway.reciprocal != nil) {
            append(drawn, model._runway.reciprocal.id);
        }

        foreach (var rwy; model._runways) {
            if (contains(drawn, rwy.rwyId)) {
                continue; # already drawn
            }

            me._drawRunway(model, centerX, centerY, rwy, model._runway);

            if (rwy.reciprocal != nil) {
                append(drawn, rwy.reciprocal.id);
            }
        }

        # Draw main runway in center of wind rose
        me._drawRunway(model, centerX, centerY, model._runway);

        me._drawWindArrow(model, centerX, centerY);
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
    # @param  ghost  model  WindRoseView model.
    # @param  double  centerX  Center of wind rose in pixels.
    # @param  double  centerY  Center of wind rose in pixels.
    # @param  hash  rwy  Runway object to draw in center.
    # @param  hash|nil  refRwy  Reference runway as main runway when draw another runway around.
    # @return void
    #
    _drawRunway: func(model, centerX, centerY, rwy, refRwy = nil) {
        var isMainRwy = refRwy == nil;

        # Scale: meters → pixels
        var scale = (model._radius * 2) / model._maxRwyLength;

        # Runway length and width in pixels
        var lenPix   = rwy.length * scale;
        var widthPix = rwy.width  * scale;

        var METERS_PER_DEG_LAT   = 111320.0;
        var EARTH_EQUATOR_METERS = 40075000.0;

        var rwyCenterX = centerX;
        var rwyCenterY = centerY;
        var startClipped = false;
        var endClipped = false;
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

            var dxPx = dYM * scale;
            var dyPx = -dXM * scale;

            # Translation to pixels relative to the center of the wind rose.
            rwyCenterX = centerX + dxPx;
            rwyCenterY = centerY + dyPx;

            # The ends of the runway along the runway heading.
            xStart = rwyCenterX - cosRad * (lenPix / 2);
            yStart = rwyCenterY - sinRad * (lenPix / 2);
            xEnd   = rwyCenterX + cosRad * (lenPix / 2);
            yEnd   = rwyCenterY + sinRad * (lenPix / 2);

            var clipped = me._clipLineToCircle(xStart, yStart, xEnd, yEnd, centerX, centerY, model._radius * 1.1);
            if (clipped == nil) {
                # Runway outside the wind rose, don't draw it
                return;
            }

            startClipped = (clipped[0].x != xStart or clipped[0].y != yStart);
            endClipped   = (clipped[1].x != xEnd   or clipped[1].y != yEnd);

            xStart = clipped[0].x;
            yStart = clipped[0].y;
            xEnd   = clipped[1].x;
            yEnd   = clipped[1].y;
        }

        # Draw runway
        me._draw.createPath()
            .moveTo(xStart, yStart)
            .lineTo(xEnd, yEnd)
            .setColor(isMainRwy ? [0, 0, 0] : [0.8, 0.8, 0.8])
            .setFill(isMainRwy ? [0, 0, 0] : [0.8, 0.8, 0.8])
            .setStrokeLineWidth(widthPix);

        # Threshold markings
        if (rwy.reciprocal != nil and !endClipped) {
            # For reciprocal
            me._drawRunwayId(rwyCenterX, rwyCenterY, rwy.reciprocal.id, rwy.normDiffDeg, angleRad, lenPix, false, isMainRwy);
        }

        if (!startClipped) {
            angleRad = (rwy.heading + 90) * globals.D2R;
            me._drawRunwayId(rwyCenterX, rwyCenterY, rwy.rwyId, rwy.normDiffDeg, angleRad, lenPix, isMainRwy, isMainRwy);
        }
    },

    #
    # @param  double  x1, y1  Start point of line.
    # @param  double  x2, y2  End point of line.
    # @param  double  cx, cy  Center of wind rose.
    # @param  double  radius  Radius to clip.
    # @return vector|nil  Return vector with 2 point (start, end) or nil.
    #
    _clipLineToCircle: func(x1, y1, x2, y2, cx, cy, radius) {
        var radiusPow2 = radius * radius;

        # segment vector
        var dx = x2 - x1;
        var dy = y2 - y1;

        # offset from the center of the circle
        var fx = x1 - cx;
        var fy = y1 - cy;

        # quadratic equation: (dx^2 + dy^2) t^2 + 2(fx*dx + fy*dy) t + (fx^2 + fy^2 - radius^2) = 0
        var a = dx * dx + dy * dy;
        var b = 2 * (fx * dx + fy * dy);
        var c = fx * fx + fy * fy - radiusPow2;

        var disc = b * b - 4 * a * c;
        if (disc < 0) {
            # nothing to clip
            return nil;
        }

        disc = math.sqrt(disc);
        var t1 = (-b - disc) / (2 * a);
        var t2 = (-b + disc) / (2 * a);

        var points = [];

        if (t1 >= 0 and t1 <= 1) {
            append(points, {
                x: x1 + t1 * dx,
                y: y1 + t1 * dy,
            });
        }

        if (t2 >= 0 and t2 <= 1) {
            append(points, {
                x: x1 + t2 * dx,
                y: y1 + t2 * dy,
            });
        }

        # zwróć odcinek przycięty
        var inside1 = (math.pow(x1 - cx, 2) + math.pow(y1 - cy, 2)) <= radiusPow2;
        var inside2 = (math.pow(x2 - cx, 2) + math.pow(y2 - cy, 2)) <= radiusPow2;

           if (inside1 and inside2)          return [ {x: x1, y: y1}, { x: x2, y: y2} ];
        elsif (inside1 and size(points) > 0) return [ {x: x1, y: y1}, points[0] ];
        elsif (inside2 and size(points) > 0) return [ points[0], {x: x2, y: y2} ];
        elsif (size(points) == 2)            return [ points[0], points[1] ];

        return nil; # whole line is out of circle
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
        var color = whichRunway.Colors.DEFAULT_TEXT;
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
            text.setFont(whichRunway.Fonts.SANS_BOLD);
        }
    },

    #
    # @param  int|nil  normDiffDeg
    # @return vector  RGB color.
    #
    _geWindColorByDir: func(normDiffDeg) {
           if (normDiffDeg == nil)                                   return whichRunway.Colors.DEFAULT_TEXT;
        elsif (normDiffDeg <= whichRunway.Metar.HEADWIND_THRESHOLD)  return whichRunway.Colors.GREEN;
        elsif (normDiffDeg <= whichRunway.Metar.CROSSWIND_THRESHOLD) return whichRunway.Colors.AMBER;

        return whichRunway.Colors.DEFAULT_TEXT;
    },

    #
    # Draw wind arrow.
    #
    # @param  ghost  model  WindRoseView model.
    # @param  double  centerX  Center of wind rose in pixels.
    # @param  double  centerY  Center of wind rose in pixels.
    # @param  double|nil  windDir  Wind direction in degrees.
    # @return void
    #
    _drawWindArrow: func(model, centerX, centerY) {
        if (model._windDir == nil) {
            return;
        }

        var windRad = (model._windDir - 90) * globals.D2R;  # direction in radians

        var cosRad = math.cos(windRad);
        var sinRad = math.sin(windRad);

        # Line from opposite side to end (full diameter)
        var xStart = centerX - cosRad * model._radius;
        var yStart = centerY - sinRad * model._radius;
        var xEnd   = centerX + cosRad * model._radius;
        var yEnd   = centerY + sinRad * model._radius;

        me._draw.createPath()
            .moveTo(xStart, yStart)
            .lineTo(xEnd, yEnd)
            .setColor(whichRunway.Colors.BLUE)
            .setFill(whichRunway.Colors.BLUE)
            .setStroke(whichRunway.Colors.BLUE)
            .setStrokeLineWidth(me._windLineWidth);

        # Arrowhead
        windRad = (model._windDir + 90) * globals.D2R;
        var slenderness = 25;
        var left  = windRad + slenderness * globals.D2R;
        var right = windRad - slenderness * globals.D2R;

        # Arrowhead at the front of the line
        me._drawArrowhead(xStart, yStart, left, right);

        # Arrowhead at the end of the line
        me._drawArrowhead(xEnd, yEnd, left, right);

        # Text with values ​​(direction/speed)
        me._drawArrowWindLabel(model, xEnd, yEnd, centerX, centerY);
    },

    #
    # @param  ghost  model  WindRoseView model.
    # @param  double  xEnd
    # @param  double  yEnd
    # @param  double  centerX
    # @param  double  centerY
    # @return void
    #
    _drawArrowWindLabel: func(model, xEnd, yEnd, centerX, centerY) {
        var margin = 50;  # distance from the end of the arrow

        # Vector from the center of the rose to the end of the arrow
        var dx = xEnd - centerX;
        var dy = yEnd - centerY;

        # Vector length
        var len = math.sqrt(dx * dx + dy * dy);

        # Normalization and displacement
        var xLabel = xEnd + (dx / len) * margin;
        var yLabel = yEnd + (dy / len) * margin;

        me._draw.createText(sprintf("%03d° %d kt", model._windDir, math.round(model._windKt)))
            .setTranslation(xLabel, yLabel)
            .setColor(whichRunway.Colors.BLUE)
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
            .setColor(whichRunway.Colors.BLUE)
            .setFill(whichRunway.Colors.BLUE)
            .setStroke(whichRunway.Colors.BLUE)
            .setStrokeLineWidth(me._windLineWidth);

        # Right arrowhead line
        me._draw.createPath()
            .moveTo(x, y)
            .lineTo(x - math.cos(right) * arrowLength, y - math.sin(right) * arrowLength)
            .setColor(whichRunway.Colors.BLUE)
            .setFill(whichRunway.Colors.BLUE)
            .setStroke(whichRunway.Colors.BLUE)
            .setStrokeLineWidth(me._windLineWidth);
    },
};
