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
# Class do draw runways with wind rose on canvas
#
var DrawRunways = {
    #
    # Constructor
    #
    # @param  hash  draw  Draw object.
    # @param  hash  metar  Metar object.
    # @return hash
    #
    new: func(draw, metar) {
        var me = { parents: [DrawRunways] };

        me._draw = draw;
        me._metar = metar;

        me._runwaysData = RunwaysData.new(metar);
        me._drawWindRose = DrawWindRose.new(draw);

        return me;
    },

    #
    # Destructor
    #
    # @return void
    #
    del: func() {
        me._drawWindRose.del();
        me._runwaysData.del();
    },

    #
    # Draw runways information with wind rose.
    #
    # @param  double  y  Init position of y.
    # @param  ghost  airport
    # @param  double  aptMagVar  Airport magnetic variation.
    # @return double  New position of y shifted by height of printed line.
    #
    drawRunways: func(y, airport, aptMagVar) {
        var runwaysData = me._runwaysData.getRunways(airport);
        var roseRadius = 175;

        foreach (var rwy; runwaysData) {
            y += me._printRunwayLabel(0, y, rwy);

            # Headwind or Tailwind:
            y += me._draw.printLineWithValue(
                x: 0,
                y: y,
                label: me._getMainWindLabel(rwy.headwind),
                value: me._getMainWindValue(rwy.headwind, rwy.headwindGust),
                unit: rwy.headwind == nil ? nil : "kts",
                color: Colors.BLUE,
            ).y;

            y += me._draw.printLineWithValue(
                x: 0,
                y: y,
                label: "Crosswind:",
                value: me._crosswindValue(rwy.crosswind, rwy.crosswindGust),
                unit: me._crosswindUnit(rwy.crosswind),
                color: Colors.BLUE,
            ).y;

            var rwyHdgTrue = math.round(rwy.heading);
            var rwyHdgMag = Utils.normalizeCourse(rwy.heading - aptMagVar);

            y += me._draw.printLineWithValue(0, y, "Heading true:", rwyHdgTrue ~ "°").y;
            y += me._draw.printLineWithValue(0, y, "Heading mag:", rwyHdgMag ~ "°").y;
            y += me._draw.printLineWith2Values(0, y, "Length:", math.round(rwy.length * globals.M2FT), "ft", math.round(rwy.length), "m").y;
            y += me._draw.printLineWith2Values(0, y, "Width:", math.round(rwy.width * globals.M2FT), "ft", math.round(rwy.width), "m").y;
            y += me._draw.printLineWithValue(0, y, "Surface:", me._getSurface(rwy.surface)).y;
            y += me._draw.printLineWithValue(0, y, "Reciprocal:", rwy.reciprocalId).y;
            y += me._draw.printLineWithValue(0, y, "ILS:", me._getIlsValue(rwy, rwyHdgTrue, rwyHdgMag, aptMagVar)).y;

            me._drawWindRose.drawWindRose(
                500,
                y - 50, # -50 for move wind rose up.
                roseRadius,
                me._metar.getWindDir(airport),
                me._metar.getWindSpeedKt(),
                rwy,
            );

            # Margin between runways
            y += (roseRadius * 1.5);
        }

        return y;
    },

    #
    # @param  double  x  Init position of x.
    # @param  double  y  Init position of y.
    # @param  hash  runway  Runway data object.
    # @return double  New position of y shifted by height of printed runway label.
    #
    _printRunwayLabel: func(x, y, runway) {
        var text = me._draw.createText(runway.type ~ ":")
            .setTranslation(x, y)
            .setColor(Colors.DEFAULT_TEXT);

        x += text.getSize()[0] + 5;
        text = me._draw.createText(runway.rwyId)
            .setTranslation(x, y)
            .setColor(Colors.DEFAULT_TEXT)
            .setFontSize(20)
            .setFont(Fonts.SANS_BOLD);

        x += text.getSize()[0] + 10;
        text = me._draw.createText(me._geWindLabelByDir(runway.normDiffDeg))
            .setTranslation(x, y)
            .setColor(me._geWindColorByDir(runway.normDiffDeg))
            .setFont(me._geWindFontByDir(runway.normDiffDeg));

        return text.getSize()[1] + Draw.MARGIN_Y;
    },

    #
    # @param  int|nil  normDiffDeg
    # @return string  Wind label: "Headwind", "Crosswind" or "Tailwind"
    #
    _geWindLabelByDir: func(normDiffDeg) {
           if (normDiffDeg == nil)                       return "n/a";
        elsif (normDiffDeg <= Metar.HEADWIND_THRESHOLD)  return "Headwind";
        elsif (normDiffDeg <= Metar.CROSSWIND_THRESHOLD) return "Crosswind";
        else                                             return "Tailwind";
    },

    #
    # @param  int|nil  normDiffDeg
    # @return vector  RGB color.
    #
    _geWindColorByDir: func(normDiffDeg) {
           if (normDiffDeg == nil)                       return Colors.DEFAULT_TEXT;
        elsif (normDiffDeg <= Metar.HEADWIND_THRESHOLD)  return Colors.GREEN;
        elsif (normDiffDeg <= Metar.CROSSWIND_THRESHOLD) return Colors.AMBER;
        else                                             return Colors.DEFAULT_TEXT;
    },

    #
    # @param  int|nil  normDiffDeg
    # @return string  Font path.
    #
    _geWindFontByDir: func(normDiffDeg) {
           if (normDiffDeg == nil)                       return Fonts.SANS_REGULAR;
        elsif (normDiffDeg <= Metar.CROSSWIND_THRESHOLD) return Fonts.SANS_BOLD;
        else                                             return Fonts.SANS_REGULAR;
    },

    #
    # @param  double|nil  headwind
    # @return string
    #
    _getMainWindLabel: func(headwind) {
           if (headwind == nil) return "Wind:";
        elsif (headwind < 0)    return "Tailwind:";
        else                    return "Headwind:";
    },

    #
    # @param  double|nil  headwind
    # @param  double|nil  headwindGust
    # @return string|double
    #
    _getMainWindValue: func(headwind, headwindGust) {
        if (headwind == nil) {
            return "n/a";
        }

        var result =  math.round(math.abs(headwind));
        if (headwindGust != nil) {
            headwindGust = math.round(math.abs(headwindGust));
            if (headwindGust > 0) {
                result ~= "-" ~ headwindGust;
            }
        }

        return result;
    },

    #
    # @param  double|nil  crosswind
    # @param  double|nil  crosswindGust
    # @return string
    #
    _crosswindValue: func(crosswind, crosswindGust) {
        if (crosswind == nil) {
            return "n/a";
        }

        var result = math.round(math.abs(crosswind));
        if (crosswindGust != nil) {
            crosswindGust = math.round(math.abs(crosswindGust));
            if (crosswindGust > 0) {
                result ~= "-" ~ crosswindGust;
            }
        }

        return result;
    },

    #
    # @param  double|nil  crosswind
    # @return string|double
    #
    _crosswindUnit: func(crosswind) {
        if (crosswind == nil) {
            return nil;
        }

        var unit = "kts";

        if (crosswind == 0) {
            return unit;
        }

        return unit ~ (crosswind < 0 ? " from left" : " from right");
    },

    #
    # Get surface name by ID.
    #
    # @param  int  surfaceId
    # @return string
    #
    _getSurface: func(surfaceId) {
           if (surfaceId == 1 or (surfaceId >= 20 and surfaceId <= 38)) return "asphalt";
        elsif (surfaceId == 2 or (surfaceId >= 50 and surfaceId <= 57)) return "concrete";
        elsif (surfaceId == 3)  return "turf";
        elsif (surfaceId == 4)  return "dirt";
        elsif (surfaceId == 5)  return "gravel";
        elsif (surfaceId == 6)  return "asphalt helipad";
        elsif (surfaceId == 7)  return "concrete helipad";
        elsif (surfaceId == 8)  return "turf helipad";
        elsif (surfaceId == 9)  return "dirt helipad";
        elsif (surfaceId == 12) return "lakebed";
        elsif (surfaceId == 13) return "water";
        elsif (surfaceId == 14) return "ice"; # also snow
        elsif (surfaceId == 15) return "transparent"; # Hard surface, but no texture/markings (use in custom scenery)

        return "unknown";
    },

    #
    # @param  hash  rwy  Runway hash with data.
    # @param  int  rwyHdgTrue  True heading of runway.
    # @param  int  rwyHdgMag  Magnetic heading of runway.
    # @param  double  aptMagVar  Magnetic variation of airport.
    # @return string
    #
    _getIlsValue: func(rwy, rwyHdgTrue, rwyHdgMag, aptMagVar) {
        if (rwy.ils == nil) {
            return "No";
        }

        # TODO: Here's the question: should we use the course from the ILS object, or should we take the runway heading?
        # From what I've checked, the ILS course sometimes differs from the runway heading (assuming FG always uses true,
        # which it does, which isn't entirely correct for ILS). So, to avoid any visual discrepancies of 1 degree,
        # I just use the runway heading for now.
        var ilsCourse = rwyHdgMag;

        # var ilsCourse = math.round(rwy.ils.course);
        # if (ilsCourse == rwyHdgTrue and ilsCourse != rwyHdgMag) {
        #     # FG gives ILS course as true, what is incorrect, convert true to magnetic.
        #     # ilsCourse = Utils.normalizeCourse(ilsCourse - aptMagVar);
        # }

        return sprintf("%s %.3f/%d°", rwy.ils.id, rwy.ils.frequency / 100, ilsCourse);
    },
};
