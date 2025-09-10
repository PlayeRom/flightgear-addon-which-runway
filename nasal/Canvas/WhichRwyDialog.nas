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
# WhichRwyDialog dialog class
#
var WhichRwyDialog = {
    #
    # Constants
    #
    WINDOW_WIDTH  : 800,
    WINDOW_HEIGHT : 700,
    PADDING       : 10,
    MARGIN_Y      : 10,

    #
    # Constructor
    #
    # @return me
    #
    new: func() {
        var me = { parents: [
            WhichRwyDialog,
            Dialog.new(WhichRwyDialog.WINDOW_WIDTH, WhichRwyDialog.WINDOW_HEIGHT, "Which Runway", true),
        ] };

        # Get closest airport ICAO code as default:
        me._icao = getprop("/sim/airport/closest-airport-id");

        me._timer = maketimer(0.1, me, me._checkMetarCallback);

        me._wind = Wind.new();
        me._runwaysData = RunwaysData.new(me._wind);

        me._defaultTextColor = [0.3, 0.3, 0.3];

        me.setPositionOnCenter();

        var margins = {
            left   : WhichRwyDialog.PADDING,
            top    : WhichRwyDialog.PADDING,
            right  : 0,
            bottom : WhichRwyDialog.PADDING,
        };
        me._scrollData = me.createScrollArea(margins: margins);

        me.vbox.addItem(me._scrollData, 1); # 2nd param = stretch

        me._scrollDataContent = me.getScrollAreaContent(
            context  : me._scrollData,
            font     : Fonts.getRegular(),
            fontSize : 16,
            alignment: "left-baseline"
        );

        me._drawBottomBar();

        me._windRose = WindRose.new(me._scrollDataContent);

        return me;
    },

    #
    # Destructor
    #
    # @return void
    #
    del: func() {
        me._timer.stop();

        me._windRose.del();
        me._runwaysData.del();
        me._wind.del();

        call(Dialog.del, [], me);
    },

    #
    # @return void
    #
    show: func() {
        me._doanloadMetar();

        call(Dialog.show, [], me);
    },

    #
    # @return void
    #
    hide: func() {
        me._timer.stop();

        call(Dialog.hide, [], me);
    },

    #
    # Initialize download of METAR data.
    #
    # @return void
    #
    _doanloadMetar: func() {
        me._timer.stop();

        if (airportinfo(me._icao) == nil) {
            me._reDrawContentWithMessage("ICAO code `" ~ me._icao ~ "` not found!", true);
            return;
        }

        me._wind.downloadMetar(me._icao);
        me._timer.start();
    },

    #
    # Callback for timer to check if METAR data is set.
    #
    # @return void
    #
    _checkMetarCallback: func() {
        if (me._wind.isMetarSet()) {
            me._timer.stop();
            me._reDrawContent();
        } else {
            me._reDrawContentWithMessage("Loading...");
        }
    },

    #
    # Redraw whole content with given message text.
    #
    # @param  string  message  Error message.
    # @param  bool  isError  If true then message is error message (red color).
    # @return void
    #
    _reDrawContentWithMessage: func(message, isError = false) {
        me._scrollDataContent.removeAllChildren();

        me._printMessage(message, isError);

        me._scrollData.scrollToTop();
        me._scrollData.scrollToLeft();
    },

    #
    # Draw whole content.
    #
    # @return void
    #
    _reDrawContent: func() {
        me._scrollDataContent.removeAllChildren();

        var airport = airportinfo(me._icao);
        if (airport == nil) {
            me._printMessage("ICAO code `" ~ me._icao ~ "` not found!", true);
        } else {
            runwaysData = me._runwaysData.getRunways(airport);

            var x = 0;
            var y = 0;

            var roseRadius = 200;

            var text = me._scrollDataContent.createChild("text")
                .setText(airport.id ~ ", " ~ airport.name)
                .setTranslation(x, y)
                .setColor(me._defaultTextColor)
                .setFontSize(24)
                .setFont(Fonts.getBold());

            y += text.getSize()[1] + WhichRwyDialog.MARGIN_Y;

            text = me._scrollDataContent.createChild("text")
                .setText("Wind: " ~ math.round(me._wind.getDirection()) ~ "° at " ~ math.round(me._wind.getSpeedKt()) ~ " kts")
                .setTranslation(x, y)
                .setColor(me._defaultTextColor)
                .setFontSize(20)
                .setFont(Fonts.getBold());

            y += text.getSize()[1] + 25;

            foreach (var rwy; runwaysData) {
                y += me._printRunwayLabel(0, y, rwy);

                var label = rwy.headwind < 0 ? "Tailwind:" : "Headwind:";
                y += me._printLineWithValue(0, y, label, math.round(math.abs(rwy.headwind)), "kts");

                var unit = "kts" ~ (rwy.crosswind == 0 ? "" : (rwy.crosswind < 0 ? " from left" : " from right"));
                y += me._printLineWithValue(0, y, "Crosswind:", math.round(math.abs(rwy.crosswind)), unit);
                y += me._printLineWithValue(0, y, "Heading:", math.round(rwy.heading) ~ "°");
                y += me._printLineWithValue(0, y, "Length:", math.round(rwy.length), "m");
                y += me._printLineWithValue(0, y, "Width:", math.round(rwy.width), "m");
                y += me._printLineWithValue(0, y, "Reciprocal:", rwy.reciprocalId);
                y += me._printLineWithValue(0, y, "ILS:", rwy.ils == nil ? "No" : (sprintf("%.3f/%.0f°", rwy.ils.frequency / 100, rwy.ils.course)));

                me._windRose.drawWindRose(
                    500,
                    y,
                    roseRadius,
                    me._wind.getDirection(),
                    me._wind.getSpeedKt(),
                    rwy,
                );

                # Margin between runways
                y += (roseRadius * 2);
            }
        }

        me._scrollData.scrollToTop();
        me._scrollData.scrollToLeft();
    },

    #
    # @param  int  x  Init position of x.
    # @param  int  y  Init position of y.
    # @param  hash  runway  Runway data object.
    # @return int  New position of y shifted by height of printed runway label.
    #
    _printRunwayLabel: func(x, y, runway) {
        var text = me._scrollDataContent.createChild("text")
            .setText("Runway: ")
            .setTranslation(x, y)
            .setColor(me._defaultTextColor);

        x += text.getSize()[0] + 5;
        text = me._scrollDataContent.createChild("text")
            .setText(runway.rwyId)
            .setTranslation(x, y)
            .setColor([0.0, 0.0, 0.0])
            .setFontSize(20)
            .setFont(Fonts.getBold());

        x += text.getSize()[0] + 10;
        text = me._scrollDataContent.createChild("text")
            .setText(me._geWindLabelByDir(runway.normDiffDeg))
            .setTranslation(x, y)
            .setColor(me._geWindColorByDir(runway.normDiffDeg))
            .setFont(me._geWindFontByDir(runway.normDiffDeg));

        return text.getSize()[1] + WhichRwyDialog.MARGIN_Y;
    },

    #
    # @param  int  normDiffDeg
    # @return string  Wind label: "Headwind", "Crosswind" or "Tailwind"
    #
    _geWindLabelByDir: func(normDiffDeg) {
             if (normDiffDeg <= Wind.HEADWIND_THRESHOLD)  return "Headwind";
        else if (normDiffDeg <= Wind.CROSSWIND_THRESHOLD) return "Crosswind";
        else                                              return "Tailwind";
    },

    #
    # @param  int  normDiffDeg
    # @return vector  RGB color.
    #
    _geWindColorByDir: func(normDiffDeg) {
             if (normDiffDeg <= Wind.HEADWIND_THRESHOLD)  return Wind.getHeadwindColor();
        else if (normDiffDeg <= Wind.CROSSWIND_THRESHOLD) return Wind.getCrosswindColor();
        else                                              return me._defaultTextColor;
    },

    #
    # @param  int  normDiffDeg
    # @return string  Font path.
    #
    _geWindFontByDir: func(normDiffDeg) {
        if (normDiffDeg <= Wind.CROSSWIND_THRESHOLD) return Fonts.getBold();
        else                                         return Fonts.getRegular();
    },

    #
    # @param  int  x  Init position of x.
    # @param  int  y  Init position of y.
    # @param  string  label  Label text.
    # @param  string|int  value  Value to display.
    # @param  string|nil  unit  Unit to display.
    # @return int  New position of y shifted by height of printed line.
    #
    _printLineWithValue: func(x, y, label, value, unit = nil) {
        var text = me._scrollDataContent.createChild("text")
            .setText(label)
            .setTranslation(x, y)
            .setColor(me._defaultTextColor);

        x += 100;
        text = me._scrollDataContent.createChild("text")
            .setText(value)
            .setTranslation(x, y)
            .setColor(me._defaultTextColor)
            .setFont(Fonts.getBold());

        if (unit != nil) {
            x += text.getSize()[0] + 5;
            text = me._scrollDataContent.createChild("text")
                .setText(unit)
                .setTranslation(x, y)
                .setColor(me._defaultTextColor);
        }

        return text.getSize()[1] + WhichRwyDialog.MARGIN_Y;
    },

    #
    # @param  string  message  Error message.
    # @param  bool  isError  If true then message is error message (red color).
    # @return void
    #
    _printMessage: func(message, isError = false) {
        me._scrollDataContent.createChild("text")
            .setText(message)
            .setTranslation(0, 0)
            .setColor(isError ? [0.8, 0.3, 0.3] : me._defaultTextColor)
            .setFontSize(20)
            .setFont(Fonts.getRegular());
    },

    #
    # @param  string  text  Label text.
    # @param  bool  wordWrap  If true then text will be wrapped.
    # @return ghost  Label widget.
    #
    # _getLabel: func(text, wordWrap = true) {
    #     return canvas.gui.widgets.Label.new(me._scrollDataContent, canvas.style, {wordWrap: wordWrap})
    #         .setText(text);
    # },

    #
    # @param  string  text  Label of button.
    # @param  func  callback  Function which will be executed after click the button.
    # @return ghost  Button widget.
    #
    _getButton: func(text, callback) {
        return canvas.gui.widgets.Button.new(me.group, canvas.style, {})
            .setText(text)
            .setFixedSize(75, 26)
            .listen("clicked", callback);
    },

    #
    # @return ghost  HBoxLayout object with controls.
    #
    _drawBottomBar: func() {
        var buttonBox = canvas.HBoxLayout.new();

        var label = canvas.gui.widgets.Label.new(me.group, canvas.style, {})
            .setText("ICAO:");

        var enterIcao = func(icao) {
            me._icao = icao;
            me._doanloadMetar();
        };

        var icaoEdit = canvas.gui.widgets.LineEdit.new(me.group, canvas.style, {})
            .setText(me._icao)
            .setPlaceholder("EPWA")
            .setFixedSize(80, 26)
            .listen("editingFinished", func(e) {
                enterIcao(e.detail.text);
            });

        var btnLoad = me._getButton("Load", func() {
            enterIcao(icaoEdit.text())
        });

        buttonBox.addStretch(1);
        buttonBox.addItem(label);
        buttonBox.addItem(icaoEdit);
        buttonBox.addItem(btnLoad);
        buttonBox.addStretch(1);

        me.vbox.addSpacing(10);
        me.vbox.addItem(buttonBox);
        me.vbox.addSpacing(10);

        return buttonBox;
    },
};
