#
# Which Runway - Add-on for FlightGear
#
# Written and developer by Roman Ludwicki (PlayeRom, SP-ROM)
#
# Copyright (C) 2024 Roman Ludwicki
#
# RunwayInfo widget is an Open Source project and it is licensed
# under the GNU Public License v3 (GPLv3)
#

#
# RunwayInfo widget View
#
DefaultStyle.widgets["runway-info-view"] = {
    #
    # Constructor
    #
    # @param  ghost  parent
    # @param  hash  cfg
    # @return void
    #
    new: func(parent, cfg) {
        me._root = parent.createChild("group", "runway-info-view");

        me._colors = cfg.get("colors");

        me._fontSansRegular = canvas.font_mapper("sans");
        me._fontSansBold    = canvas.font_mapper("sans", "bold");

        me._draw = Draw.new(me._root, me._fontSansBold);

        me._LABEL = 0;
        me._VAL   = 1;
        me._UNIT  = 2;
        me._VAL2  = 3;
        me._UNIT2 = 4;

        me._runwayTexts = {
            label: me._draw.createTextLabel("Runway/Helipad:"),
            id   : me._draw.createTextValue("31L").setFontSize(20),
            wind : me._draw.createTextLabel("Headwind/Tailwind"),
        };

        me._hdTw = [
            me._draw.createTextLabel("Headwind/Tailwind:", me._colors.BLUE),
            me._draw.createTextValue("n/a", me._colors.BLUE),
            me._draw.createTextUnit("kts", me._colors.BLUE),
        ];

        me._crosswind = [
            me._draw.createTextLabel("Crosswind:", me._colors.BLUE),
            me._draw.createTextValue("n/a", me._colors.BLUE),
            me._draw.createTextUnit("kts", me._colors.BLUE),
        ];

        me._hdgTrue = [
            me._draw.createTextLabel("Heading true:"),
            me._draw.createTextValue("°"),
        ];

        me._hdgMag = [
            me._draw.createTextLabel("Heading mag:"),
            me._draw.createTextValue("°"),
        ];

        me._rwyLength = [
            me._draw.createTextLabel("Length:"),
            me._draw.createTextValue("0"),
            me._draw.createTextUnit("ft /"),
            me._draw.createTextValue("0"),
            me._draw.createTextUnit("m"),
        ];

        me._rwyWidth = [
            me._draw.createTextLabel("Width:"),
            me._draw.createTextValue("0"),
            me._draw.createTextUnit("ft /"),
            me._draw.createTextValue("0"),
            me._draw.createTextUnit("m"),
        ];

        me._surface = [
            me._draw.createTextLabel("Surface:"),
            me._draw.createTextValue("n/a"),
        ];

        me._reciprocal = [
            me._draw.createTextLabel("Reciprocal:"),
            me._draw.createTextValue("n/a"),
        ];

        me._ils = [
            me._draw.createTextLabel("ILS:"),
            me._draw.createTextValue("n/a"),
        ];

        me._contentHeight = nil;
    },

    #
    # Callback called when user resized the window.
    #
    # @param  ghost  model  RunwayInfo model.
    # @param  int  w, h  Width and height of widget.
    # @return ghost
    #
    setSize: func(model, w, h) {
        me.reDrawContent(model);

        return me;
    },

    #
    # @param  ghost  model  RunwayInfo model.
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
    # @param  ghost  model  RunwayInfo model.
    # @return void
    #
    reDrawContent: func(model) {
        if (me._contentHeight == nil) {
            me._contentHeight = me._setTranslations(model);
        }

        me._drawRunwayInfo(model);

        # model.setLayoutMaximumSize([model._size[0], me._contentHeight]);
        model.setLayoutMinimumSize([model._size[0], me._contentHeight]);
        model.setLayoutSizeHint([model._size[0], me._contentHeight]);
    },

    #
    # @param  ghost  model  RunwayInfo model.
    # @return double  New Y position.
    #
    _setTranslations: func(model) {
        var x = 0;
        var y = 0;

        # Set runway label
        me._runwayTexts.label.setTranslation(x, y);
        x += me._draw.shiftX(me._runwayTexts.label);
        me._runwayTexts.id.setTranslation(x, y);
        x += me._draw.shiftX(me._runwayTexts.id, 10);
        me._runwayTexts.wind.setTranslation(x, y);
        y += me._draw.shiftY(me._runwayTexts.wind);

        y += me._draw.setTextTranslations(y, me._hdTw, model._valueMarginX);
        y += me._draw.setTextTranslations(y, me._crosswind, model._valueMarginX);
        y += me._draw.setTextTranslations(y, me._hdgTrue, model._valueMarginX);
        y += me._draw.setTextTranslations(y, me._hdgMag, model._valueMarginX);
        y += me._draw.setTextTranslations(y, me._rwyLength, model._valueMarginX);
        y += me._draw.setTextTranslations(y, me._rwyWidth, model._valueMarginX);
        y += me._draw.setTextTranslations(y, me._surface, model._valueMarginX);
        y += me._draw.setTextTranslations(y, me._reciprocal, model._valueMarginX);
        y += me._draw.setTextTranslations(y, me._ils, model._valueMarginX, true);

        return y;
    },

    #
    # @param  ghost  model  RunwayInfo model.
    # @return void
    #
    _drawRunwayInfo: func(model) {
        var rwy = model._runway;

        me._setRunwayLabel(rwy);

        # Headwind or Tailwind:
        me._hdTw[me._LABEL].setText(me._getMainWindLabel(rwy.headwind));
        me._hdTw[me._VAL].setText(me._getWindValue(rwy.headwind, rwy.headwindGust));
        if (rwy.headwind == nil) {
            me._hdTw[me._UNIT].setVisible(false);
        } else {
            var x = model._valueMarginX + me._draw.shiftX(me._hdTw[me._VAL]);
            var (xT, yT) = me._hdTw[me._UNIT].getTranslation();
            me._hdTw[me._UNIT]
                .setTranslation(x, yT)
                .setVisible(true);
        }

        # Crosswind:
        var xwUnit = me._crosswindUnit(rwy.crosswind);
        me._crosswind[me._VAL].setText(me._getWindValue(rwy.crosswind, rwy.crosswindGust));
        if (xwUnit == nil) {
            me._crosswind[me._UNIT].setVisible(false);
        } else {
            var x = model._valueMarginX + me._draw.shiftX(me._crosswind[me._VAL]);
            var (xT, yT) = me._crosswind[me._UNIT].getTranslation();
            me._crosswind[me._UNIT]
                .setText(xwUnit)
                .setTranslation(x, yT)
                .setVisible(true);
        }

        var rwyHdgTrue = math.round(rwy.heading);
        var rwyHdgMag = math.round(globals.geo.normdeg(rwy.heading - model._aptMagVar));

        me._hdgTrue[me._VAL].setText(sprintf("%d°", rwyHdgTrue));
        me._hdgMag[me._VAL].setText(sprintf("%d°", rwyHdgMag));

        me._rwyLength[me._VAL].setText(sprintf("%d", math.round(rwy.length * globals.M2FT)));
        me._rwyLength[me._VAL2].setText(sprintf("%d", math.round(rwy.length)));
        var (xTL, yTL) = me._rwyLength[me._VAL].getTranslation();
        me._draw.setTextTranslations(yTL, me._rwyLength, model._valueMarginX);

        me._rwyWidth[me._VAL].setText(sprintf("%d", math.round(rwy.width * globals.M2FT)));
        me._rwyWidth[me._VAL2].setText(sprintf("%d", math.round(rwy.width)));
        var (xTW, yTW) = me._rwyWidth[me._VAL].getTranslation();
        me._draw.setTextTranslations(yTW, me._rwyWidth, model._valueMarginX);

        me._surface[me._VAL].setText(me._getSurface(rwy.surface));
        me._reciprocal[me._VAL].setText(rwy.reciprocal or "n/a");
        me._ils[me._VAL].setText(me._getIlsValue(rwy, rwyHdgTrue, rwyHdgMag, model._aptMagVar));
    },

    #
    # @param  hash  runway  Runway data object.
    # @return void
    #
    _setRunwayLabel: func(runway) {
        me._runwayTexts.label.setText(runway.type ~ ":");

        var x = me._draw.shiftX(me._runwayTexts.label);
        var (xT, yT) = me._runwayTexts.id.getTranslation();
        me._runwayTexts.id.setText(runway.rwyId).setTranslation(x, yT);

        x += me._draw.shiftX(me._runwayTexts.id, 10);
        me._runwayTexts.wind.setText(me._geWindLabelByDir(runway.normDiffDeg))
            .setTranslation(x, yT)
            .setColor(me._geWindColorByDir(runway.normDiffDeg))
            .setFont(me._geWindFontByDir(runway.normDiffDeg));
    },

    #
    # @param  int|nil  normDiffDeg
    # @return string  Wind label: "Headwind", "Crosswind" or "Tailwind"
    #
    _geWindLabelByDir: func(normDiffDeg) {
           if (normDiffDeg == nil)                                   return "n/a";
        elsif (normDiffDeg <= whichRunway.Metar.HEADWIND_THRESHOLD)  return "Headwind";
        elsif (normDiffDeg <= whichRunway.Metar.CROSSWIND_THRESHOLD) return "Crosswind";
        else                                                         return "Tailwind";
    },

    #
    # @param  int|nil  normDiffDeg
    # @return vector  RGB color.
    #
    _geWindColorByDir: func(normDiffDeg) {
           if (normDiffDeg == nil)                                   return style.getColor("text_color");
        elsif (normDiffDeg <= whichRunway.Metar.HEADWIND_THRESHOLD)  return me._colors.GREEN;
        elsif (normDiffDeg <= whichRunway.Metar.CROSSWIND_THRESHOLD) return me._colors.AMBER;
        else                                                         return style.getColor("text_color");
    },

    #
    # @param  int|nil  normDiffDeg
    # @return string  Font path.
    #
    _geWindFontByDir: func(normDiffDeg) {
           if (normDiffDeg == nil)                                   return me._fontSansRegular;
        elsif (normDiffDeg <= whichRunway.Metar.CROSSWIND_THRESHOLD) return me._fontSansBold;
        else                                                         return me._fontSansRegular;
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
    # @param  double|nil  wind
    # @param  double|nil  gust
    # @return string
    #
    _getWindValue: func(wind, gust) {
        if (wind == nil) {
            return "n/a";
        }

        var result = sprintf("%d", math.round(math.abs(wind)));
        if (gust != nil) {
            gust = sprintf("%d", math.round(math.abs(gust)));
            if (gust > 0) {
                result ~= "-" ~ gust;
            }
        }

        return result;
    },

    #
    # @param  double|nil  crosswind
    # @return string|nil
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
