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
            font     : Fonts.SANS_REGULAR,
            fontSize : 16,
            alignment: "left-baseline",
        );

        me._drawBottomBar();

        me._drawRunways = DrawRunways.new(me._scrollDataContent, me._wind);

        # A variable that remembers whether the Loading screen has already been drawn,
        # so as not to redraw it unnecessarily in the timer.
        me._isLoading = false;

        return me;
    },

    #
    # Destructor
    #
    # @return void
    #
    del: func() {
        me._timer.stop();

        me._drawRunways.del();
        me._wind.del();

        call(Dialog.del, [], me);
    },

    #
    # @return void
    #
    show: func() {
        me._downloadMetar();

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
    _downloadMetar: func() {
        me._isLoading = false;
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
            me._isLoading = false;
        } else if (!me._isLoading) {
            me._isLoading = true;
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
            var y = me._drawAirportAndMetar(airport);

            me._drawRunways.drawRunways(y, airport);
        }

        me._scrollData.scrollToTop();
        me._scrollData.scrollToLeft();
    },

    #
    # Draw airport and METAR information.
    #
    # @param  ghost  airport
    # @return int  New position of y shifted by height of printed line.
    #
    _drawAirportAndMetar: func(airport) {
        var x = 0;
        var y = 0;

        # Airport ICAO and name
        var text = me._scrollDataContent.createChild("text")
            .setText(airport.id ~ ", " ~ airport.name)
            .setTranslation(x, y)
            .setColor(Colors.DEFAULT_TEXT)
            .setFontSize(24)
            .setFont(Fonts.SANS_BOLD);

        y += text.getSize()[1] + WhichRwyDialog.MARGIN_Y;

        # Airport METAR
        var metar = me._wind.getMETAR();
        text = me._scrollDataContent.createChild("text")
            .setText(metar == nil ? "No METAR" : metar)
            .setTranslation(x, y)
            .setColor(Colors.DEFAULT_TEXT)
            .setFontSize(12);

        y += text.getSize()[1] + (WhichRwyDialog.MARGIN_Y * 2.5);

        # Wind
        text = me._scrollDataContent.createChild("text")
            .setText("Wind " ~ math.round(me._wind.getDirection()) ~ "° at " ~ math.round(me._wind.getSpeedKt()) ~ " kts")
            .setTranslation(x, y)
            .setColor(Colors.DEFAULT_TEXT)
            .setFontSize(20)
            .setFont(Fonts.SANS_BOLD);

        y += text.getSize()[1] + (WhichRwyDialog.MARGIN_Y * 5);

        return y;
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
            .setColor(isError ? Colors.ERROR_TEXT : Colors.DEFAULT_TEXT)
            .setFontSize(20);
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
            me._downloadMetar();
        };

        var icaoEdit = canvas.gui.widgets.LineEdit.new(me.group, canvas.style, {})
            .setText(me._icao)
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
