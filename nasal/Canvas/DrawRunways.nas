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
    # @param  ghost  canvasContent  Canvas object where runways will be drawn.
    # @param  ghost  metar  METAR object.
    # @return me
    #
    new: func(canvasContent, metar) {
        var me = { parents: [DrawRunways] };

        me._canvas = canvasContent;
        me._metar = metar;
        me._runwaysData = RunwaysData.new(metar);
        me._drawWindRose = DrawWindRose.new(canvasContent);

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
    # @return double  New position of y shifted by height of printed line.
    #
    drawRunways: func(y, airport) {
        var runwaysData = me._runwaysData.getRunways(airport);
        var roseRadius = 175;
        var aptMagVar = magvar(airport);

        foreach (var rwy; runwaysData) {
            y += me._printRunwayLabel(0, y, rwy);

            y += me.printLineWithValue(0, y,
                me._getMainWindLabel(rwy.headwind),
                me._getMainWindValue(rwy.headwind, rwy.headwindGust),
                rwy.headwind == nil ? nil : "kts",
                true,
            );

            var rwyHdgTrue = math.round(rwy.heading);
            var rwyHdgMag = Utils.normalizeCourse(rwy.heading - aptMagVar);

            y += me.printLineWithValue(0, y, "Crosswind:", me._crosswindValue(rwy.crosswind, rwy.crosswindGust), me._crosswindUnit(rwy.crosswind), true);
            y += me.printLineWithValue(0, y, "Heading true:", rwyHdgTrue ~ "°");
            y += me.printLineWithValue(0, y, "Heading mag:", rwyHdgMag ~ "°");
            y += me.printLineWithValue(0, y, "Length:", math.round(rwy.length), "m");
            y += me.printLineWithValue(0, y, "Width:", math.round(rwy.width), "m");
            y += me.printLineWithValue(0, y, "Surface:", me._getSurface(rwy.surface));
            y += me.printLineWithValue(0, y, "Reciprocal:", rwy.reciprocalId);
            y += me.printLineWithValue(0, y, "ILS:", me._getIlsValue(rwy, rwyHdgTrue, rwyHdgMag, aptMagVar));

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
        var text = me._canvas.createChild("text")
            .setText(runway.type ~ ":")
            .setTranslation(x, y)
            .setColor(Colors.DEFAULT_TEXT);

        x += text.getSize()[0] + 5;
        text = me._canvas.createChild("text")
            .setText(runway.rwyId)
            .setTranslation(x, y)
            .setColor([0.0, 0.0, 0.0])
            .setFontSize(20)
            .setFont(Fonts.SANS_BOLD);

        x += text.getSize()[0] + 10;
        text = me._canvas.createChild("text")
            .setText(me._geWindLabelByDir(runway.normDiffDeg))
            .setTranslation(x, y)
            .setColor(me._geWindColorByDir(runway.normDiffDeg))
            .setFont(me._geWindFontByDir(runway.normDiffDeg));

        return text.getSize()[1] + DrawTabContent.MARGIN_Y;
    },

    #
    # @param  int|nil  normDiffDeg
    # @return string  Wind label: "Headwind", "Crosswind" or "Tailwind"
    #
    _geWindLabelByDir: func(normDiffDeg) {
             if (normDiffDeg == nil)                       return "n/a";
        else if (normDiffDeg <= METAR.HEADWIND_THRESHOLD)  return "Headwind";
        else if (normDiffDeg <= METAR.CROSSWIND_THRESHOLD) return "Crosswind";
        else                                               return "Tailwind";
    },

    #
    # @param  int|nil  normDiffDeg
    # @return vector  RGB color.
    #
    _geWindColorByDir: func(normDiffDeg) {
             if (normDiffDeg == nil)                       return Colors.DEFAULT_TEXT;
        else if (normDiffDeg <= METAR.HEADWIND_THRESHOLD)  return Colors.HEADWIND;
        else if (normDiffDeg <= METAR.CROSSWIND_THRESHOLD) return Colors.CROSSWIND;
        else                                               return Colors.DEFAULT_TEXT;
    },

    #
    # @param  int|nil  normDiffDeg
    # @return string  Font path.
    #
    _geWindFontByDir: func(normDiffDeg) {
             if (normDiffDeg == nil)                       return Fonts.SANS_REGULAR;
        else if (normDiffDeg <= METAR.CROSSWIND_THRESHOLD) return Fonts.SANS_BOLD;
        else                                               return Fonts.SANS_REGULAR;
    },

    #
    # @param  double|nil  headwind
    # @return string
    #
    _getMainWindLabel: func(headwind) {
             if (headwind == nil) return "Wind:";
        else if (headwind < 0)    return "Tailwind:";
        else                      return "Headwind:";
    },

    #
    # @param  double|nil  headwind
    # @param  double|nil  headwindGust
    # @return string|decimal
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
    # @param  double  x  Init position of x.
    # @param  double  y  Init position of y.
    # @param  string  label  Label text.
    # @param  string|int|double  value  Value to display.
    # @param  string|nil  unit  Unit to display.
    # @param  bool  isWindColor
    # @return double  New position of y shifted by height of printed line.
    #
    printLineWithValue: func(x, y, label, value, unit = nil, isWindColor = false) {
        var text = me._canvas.createChild("text")
            .setText(label)
            .setTranslation(x, y)
            .setColor(isWindColor ? Colors.WIND : Colors.DEFAULT_TEXT);

        x += 110;
        text = me._canvas.createChild("text")
            .setText(value)
            .setTranslation(x, y)
            .setColor(isWindColor ? Colors.WIND : Colors.DEFAULT_TEXT)
            .setFont(Fonts.SANS_BOLD);

        if (unit != nil) {
            x += text.getSize()[0] + 5;
            text = me._canvas.createChild("text")
                .setText(unit)
                .setTranslation(x, y)
                .setColor(isWindColor ? Colors.WIND : Colors.DEFAULT_TEXT);
        }

        return text.getSize()[1] + DrawTabContent.MARGIN_Y;
    },

    #
    # Get surface name by ID.
    #
    # @param  int  surfaceId
    # @return string
    #
    _getSurface: func(surfaceId) {
             if (surfaceId == 1 or (surfaceId >= 20 and surfaceId <= 38)) return "asphalt";
        else if (surfaceId == 2 or (surfaceId >= 50 and surfaceId <= 57)) return "concrete";
        else if (surfaceId == 3)  return "turf";
        else if (surfaceId == 4)  return "dirt";
        else if (surfaceId == 5)  return "gravel";
        else if (surfaceId == 6)  return "asphalt helipad";
        else if (surfaceId == 7)  return "concrete helipad";
        else if (surfaceId == 8)  return "turf helipad";
        else if (surfaceId == 9)  return "dirt helipad";
        else if (surfaceId == 12) return "lakebed";
        else if (surfaceId == 13) return "water";
        else if (surfaceId == 14) return "ice"; # also snow
        else if (surfaceId == 15) return "transparent"; # Hard surface, but no texture/markings (use in custom scenery)

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
