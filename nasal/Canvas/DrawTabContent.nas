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
# DrawTabContent class
#
var DrawTabContent = {
    #
    # Statics:
    #
    PADDING  : 10,
    MARGIN_Y : 10,

    #
    # Constructor
    #
    # @param  ghost  tabsContent  Tabs canvas content.
    # @param  ghost  tabContent  Single tab canvas content.
    # @param  string  tabId
    # @return me
    #
    new: func(tabsContent, tabContent, tabId) {
        var me = { parents: [DrawTabContent] };

        me._tabsContent = tabsContent;
        me._tabContent = tabContent;
        me._tabId = tabId;
        me._icao = "";
        me._icaoEdit = nil;
        me._isHoldUpdateNearest = false;

        if (me._isTabNearest() or me._isTabAlternate()) {
            me._btnLoadICAOs = std.Vector.new();
            for (var i = 0; i < 5; i += 1) {
                me._btnLoadICAOs.append(canvas.gui.widgets.Button.new(me._tabsContent, canvas.style, {}).setText("----"));
            }
        }

        me._scrollArea = me._createScrollArea();

        me._tabContent.addItem(me._scrollArea, 1); # 2nd param = stretch

        me._scrollContent = me._getScrollAreaContent(
            context  : me._scrollArea,
            font     : Fonts.SANS_REGULAR,
            fontSize : 16,
            alignment: "left-baseline",
        );

        me._drawBottomBar();



        me._metar = METAR.new(tabId, me, me._metarUpdatedCallback, me._realWxUpdatedCallback);
        me._drawRunways = DrawRunways.new(me._scrollContent, me._metar);

        me._listeners = Listeners.new();
        me._setListeners();

        if (me._isTabAlternate()) {
            me._reDrawContentWithMessage("Enter the ICAO code of an airport below.");
        }

        return me;
    },

    #
    # Destructor
    #
    # @return void
    #
    del: func() {
        me._listeners.del();
        me._metar.del();
        me._drawRunways.del();
    },

    #
    # Set listeners
    #
    # @return void
    #
    _setListeners: func() {
        # Get ICAO code from appropriate property and listen it for update METAR.
        var icaoProperty = me._getICAOPropertyByTabId();
        if (icaoProperty != nil) {
            me._listeners.add(
                node: icaoProperty,
                code: func(node) {
                    if (me._isTabNearest()) {
                        me._updateNearestAirportButtons();

                        if (me._isHoldUpdateNearest) {
                            # The ICAO code update is blocked by a checkbox, so we're leaving.
                            return;
                        }
                    }

                    if (node != nil) {
                        logprint(LOG_ALERT, "Which Runway ----- ", me._tabId, " got a new ICAO = ", node.getValue());
                        me._downloadMetar(node.getValue());
                    }
                },
                init: true, # if set to true, the listener will additionally be triggered when it is created.
                type: Listeners.ON_CHANGE_ONLY, # the listener will only trigger when the property is changed.
            );
        }

        if (me._isTabAlternate()) {
            me._listeners.add(
                node: "/sim/airport/closest-airport-id",
                code: func { me._updateNearestAirportButtons(); },
                init: true, # if set to true, the listener will additionally be triggered when it is created.
                type: Listeners.ON_CHANGE_ONLY, # the listener will only trigger when the property is changed.
            );
        }
    },

    #
    # Create ScrollArea widget.
    #
    # @return ghost  ScrollArea widget.
    #
    _createScrollArea: func() {
        var margins = {
            left   : DrawTabContent.PADDING,
            top    : DrawTabContent.PADDING,
            right  : 1,
            bottom : DrawTabContent.PADDING,
        };

        var scrollArea = canvas.gui.widgets.ScrollArea.new(me._tabsContent, canvas.style, {});

        scrollArea.setColorBackground(canvas.style.getColor("bg_color"));
        scrollArea.setContentsMargins(margins.left, margins.top, margins.right, margins.bottom);

        return scrollArea;
    },

    #
    # @param  ghost  context  Parent object as ScrollArea widget.
    # @param  string|nil  font  Font file name.
    # @param  int|nil  fontSize  Font size.
    # @param  string|nil  alignment  Content alignment value.
    # @return ghost  Content group of ScrollArea.
    #
    _getScrollAreaContent: func(context, font = nil, fontSize = nil, alignment = nil) {
        var scrollContent = context.getContent();

        if (font != nil) {
            scrollContent.set("font", font);
        }

        if (fontSize != nil) {
            scrollContent.set("character-size", fontSize);
        }

        if (alignment != nil) {
            scrollContent.set("alignment", alignment);
        }

        return scrollContent;
    },

    #
    # Return true if current tab it's "Nearest" tab
    #
    # @return bool
    #
    _isTabNearest: func() {
        return me._tabId == WhichRwyDialog.TAB_NEAREST;
    },

    #
    # Return true if current tab it's "Departure" tab
    #
    # @return bool
    #
    _isTabDeparture: func() {
        return me._tabId == WhichRwyDialog.TAB_DEPARTURE;
    },

    #
    # Return true if current tab it's "Arrival" tab
    #
    # @return bool
    #
    _isTabArrival: func() {
        return me._tabId == WhichRwyDialog.TAB_ARRIVAL;
    },

    #
    # Return true if current tab it's "Alternate" tab
    #
    # @return bool
    #
    _isTabAlternate: func() {
        return me._tabId == WhichRwyDialog.TAB_ALTERNATE;
    },

    #
    # Get property path to auto update METAR.
    #
    # @return string|nil
    #
    _getICAOPropertyByTabId: func() {
             if (me._isTabNearest())   return "/sim/airport/closest-airport-id";
        else if (me._isTabDeparture()) return "/autopilot/route-manager/departure/airport";
        else if (me._isTabArrival())   return "/autopilot/route-manager/destination/airport";
        else if (me._isTabAlternate()) return nil;

        return nil;
    },

    #
    # Return true if user can change ICAO code on this tab.
    #
    # @return bool
    #
    _canChangeICAO: func() {
             if (me._isTabNearest())   return true;
        else if (me._isTabDeparture()) return false;
        else if (me._isTabArrival())   return false;
        else if (me._isTabAlternate()) return true;

        return true;
    },

    #
    # Get error message if ICAO is null or empty.
    #
    # @return string
    #
    _getNoIcaoMessage: func() {
             if (me._isTabNearest())   return "Cannot find the ICAO code of the nearest airport, please enter the ICAO code manually.";
        else if (me._isTabDeparture()) return "No ICAO code. Enter the departure airport in Route Manager first.";
        else if (me._isTabArrival())   return "No ICAO code. Enter the arrival airport in Route Manager first.";

        return "No ICAO code.";
    },

    #
    # Initialize download of METAR data.
    #
    # @param  string|nil  icao
    # @return void
    #
    _downloadMetar: func(icao) {
        if (icao == nil or icao == "") {
            me._reDrawContentWithMessage(me._getNoIcaoMessage(), true);
            return;
        }

        me._icao = globals.string.uc(icao);

        if (me._icaoEdit != nil) {
            me._icaoEdit.setText(me._icao);
        }

        var airport = airportinfo(me._icao);
        if (airport == nil) {
            me._reDrawContentWithMessage("ICAO code `" ~ me._icao ~ "` not found!", true);
            return;
        }

        if (me._metar.canUseMETAR(airport)) {
            me._reDrawContentWithMessage("Loading...");
            me._metar.download(me._icao, true);
        } else {
            me._reDrawContent();
        }
    },

    #
    # Callback function, called when METAR has been updated.
    #
    # @return void
    #
    _metarUpdatedCallback: func() {
        me._reDrawContent();
    },

    #
    # Callback function, called when real weather flag han been changed.
    #
    # @return void
    #
    _realWxUpdatedCallback: func() {
        me._downloadMetar(me._icao);
    },

    #
    # Redraw whole content with given message text.
    #
    # @param  string  message  Error message.
    # @param  bool  isError  If true then message is error message (red color).
    # @return void
    #
    _reDrawContentWithMessage: func(message, isError = false) {
        me._scrollContent.removeAllChildren();

        me._printMessage(message, isError);

        me._scrollArea.scrollToTop();
        me._scrollArea.scrollToLeft();
    },

    #
    # Draw whole content.
    #
    # @return void
    #
    _reDrawContent: func() {
        me._scrollContent.removeAllChildren();

        var airport = airportinfo(me._icao);
        if (airport == nil) {
            me._printMessage("ICAO code `" ~ me._icao ~ "` not found!", true);
        } else {
            var y = me._drawAirportAndMetar(airport);

            me._drawRunways.drawRunways(y, airport);
        }

        me._scrollArea.scrollToTop();
        me._scrollArea.scrollToLeft();
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
        var text = me._scrollContent.createChild("text")
            .setText(airport.id ~ " – " ~ airport.name)
            .setTranslation(x, y)
            .setColor(Colors.DEFAULT_TEXT)
            .setFontSize(24)
            .setFont(Fonts.SANS_BOLD);

        y += text.getSize()[1] + DrawTabContent.MARGIN_Y;

        y += me._drawRunways.printLineWithValue(x, y, "Lat, Lon:", me._getLatLonInfo(airport));
        y += me._drawRunways.printLineWithValue(x, y, "Elevation:", math.round(airport.elevation), "m");
        y += me._drawRunways.printLineWithValue(x, y, "Mag Var:", sprintf("%.2f°", magvar(airport)));
        y += me._drawRunways.printLineWithValue(x, y, "Has METAR:", airport.has_metar ? "Yes" : "No");
        y += DrawTabContent.MARGIN_Y;

        # Airport METAR
        if (me._metar.isRealWeatherEnabled()) {
            var metar = airport.has_metar ? me._metar.getMETAR() : nil;
            text = me._scrollContent.createChild("text")
                .setText(metar == nil ? "No METAR" : metar ~ "  ") # <- add spaces at the end to add padding to a very long METAR
                .setTranslation(x, y)
                .setColor(Colors.DEFAULT_TEXT);
        } else {
            text = me._scrollContent.createChild("text")
                .setText("For METAR, it is necessary to select the Live Data weather scenario!")
                .setTranslation(x, y)
                .setColor(Colors.ERROR_TEXT);
        }

        y += text.getSize()[1] + (DrawTabContent.MARGIN_Y * 2);

        y += me._drawRunways.printLineWithValue(x, y, "QNH:", me._metar.getQNHValues(airport));
        y += me._drawRunways.printLineWithValue(x, y, "QFE:", me._metar.getQFEValues(airport));
        y += text.getSize()[1] + (DrawTabContent.MARGIN_Y * 2);

        # Wind
        text = me._scrollContent.createChild("text")
            .setText("Wind " ~ me._getWindInfoText(airport))
            .setTranslation(x, y)
            .setColor(Colors.WIND)
            .setFontSize(20)
            .setFont(Fonts.SANS_BOLD);

        y += text.getSize()[1] + (DrawTabContent.MARGIN_Y * 5);

        return y;
    },

    #
    # @param  ghost  airport
    # @return string
    #
    _getWindInfoText: func(airport) {
        if (me._metar.canUseMETAR(airport)) {
            var windDir = me._metar.getWindDir(airport);
            windDir = windDir == nil
                ? "variable"
                : math.round(windDir) ~ "°";

            return windDir ~ " at " ~ math.round(me._metar.getWindSpeedKt()) ~ " kts";
        }

        return "n/a";
    },

    #
    # @param  string  message  Error message.
    # @param  bool  isError  If true then message is error message (red color).
    # @return void
    #
    _printMessage: func(message, isError = false, fontSize = 20) {
        me._scrollContent.createChild("text")
            .setText(message)
            .setTranslation(0, 0)
            .setColor(isError ? Colors.ERROR_TEXT : Colors.DEFAULT_TEXT)
            .setFontSize(fontSize);
    },

    #
    # Get string with airport geo coordinates in decimal and sexagesimal formats.
    #
    # @param  ghost  airport
    # @return string
    #
    _getLatLonInfo: func(airport) {
        var decimal = sprintf("%.4f, %.4f", airport.lat, airport.lon);

        var signNS = airport.lat >= 0 ? "N" : "S";
        var signEW = airport.lon >= 0 ? "E" : "W";
        var sexagesimal = sprintf("%s %d°%02d'%.1f'', %s %d°%02d'%.1f''",
            signNS,
            math.abs(int(airport.lat)),
            math.abs(int(airport.lat * 60 - int(airport.lat) * 60)),
            math.abs(airport.lat * 3600 - int(airport.lat * 60) * 60),
            signEW,
            math.abs(int(airport.lon)),
            math.abs(int(airport.lon * 60 - int(airport.lon) * 60)),
            math.abs(airport.lon * 3600 - int(airport.lon * 60) * 60),
        );

        return decimal ~ "  /  " ~ sexagesimal;
    },

    #
    # @return ghost  Canvas layout object with controls.
    #
    _drawBottomBar: func() {
        var buttonBox = me._getButtonBoxByTabId();

        me._tabContent.addSpacing(10);
        me._tabContent.addItem(buttonBox);
        me._tabContent.addSpacing(10);

        return buttonBox;
    },

    #
    # @return ghost  Canvas layout object with controls.
    #
    _getButtonBoxByTabId: func() {
             if (me._isTabNearest())                         return me._drawBottomBarForNearest();
        else if (me._isTabDeparture() or me._isTabArrival()) return me._drawBottomBarForScheduledTab();
        else if (me._isTabAlternate())                       return me._drawBottomBarForAlternate();

        return nil;
    },

    #
    # @return ghost  Canvas layout object with controls.
    #
    _drawBottomBarForNearest: func() {
        var buttonBox = canvas.HBoxLayout.new();

        buttonBox.addStretch(1);
        foreach (var btn; me._btnLoadICAOs.vector) {
            buttonBox.addItem(btn);
        }

        var label = canvas.gui.widgets.Label.new(me._tabsContent, canvas.style, {})
            .setText("ICAO:");

        me._icaoEdit = canvas.gui.widgets.LineEdit.new(me._tabsContent, canvas.style, {})
            .setText(me._icao)
            .setFixedSize(80, 26)
            .listen("editingFinished", func(e) {
                me._downloadMetar(e.detail.text);
            });

        var btnLoad = me._getButton("Load", func() {
            me._downloadMetar(me._icaoEdit.text());
        });

        var holdUpdateCheckbox = canvas.gui.widgets.CheckBox.new(me._tabsContent, canvas.style, { wordWrap: false })
            .setText("Hold update")
            .setChecked(false)
            .listen("toggled", func(e) {
                me._isHoldUpdateNearest = e.detail.checked;

                if (!me._isHoldUpdateNearest) {
                    # If the option is unchecked, immediately update the airport
                    # with the nearest one if it has changed from the current one.
                    var newICAO = getprop("/sim/airport/closest-airport-id");
                    if (newICAO != me._icao) {
                        me._downloadMetar(newICAO);
                    }
                }
            });

        buttonBox.addStretch(1);
        buttonBox.addItem(label);
        buttonBox.addItem(me._icaoEdit);
        buttonBox.addItem(btnLoad);
        buttonBox.addStretch(1);
        buttonBox.addItem(holdUpdateCheckbox);
        buttonBox.addStretch(1);

        return buttonBox;
    },

    #
    # @return ghost  Canvas layout object with controls.
    #
    _drawBottomBarForScheduledTab: func() {
        var buttonBox = canvas.HBoxLayout.new();

        var btnLoad = me._getButton("Update METAR", func() {
            me._downloadMetar(me._icao);
        });

        buttonBox.addStretch(1);
        buttonBox.addItem(btnLoad);
        buttonBox.addStretch(1);

        return buttonBox;
    },

    #
    # @return ghost  Canvas layout object with controls.
    #
    _drawBottomBarForAlternate: func() {
        var buttonBox = canvas.HBoxLayout.new();

        buttonBox.addStretch(1);
        foreach (var btn; me._btnLoadICAOs.vector) {
            buttonBox.addItem(btn);
        }

        var label = canvas.gui.widgets.Label.new(me._tabsContent, canvas.style, {})
            .setText("ICAO:");

        me._icaoEdit = canvas.gui.widgets.LineEdit.new(me._tabsContent, canvas.style, {})
            .setText(me._icao)
            .setFixedSize(80, 26)
            .listen("editingFinished", func(e) {
                me._downloadMetar(e.detail.text);
            });

        var btnLoad = me._getButton("Load", func() {
            me._downloadMetar(me._icaoEdit.text());
        });

        buttonBox.addStretch(1);
        buttonBox.addItem(label);
        buttonBox.addItem(me._icaoEdit);
        buttonBox.addItem(btnLoad);
        buttonBox.addStretch(1);

        return buttonBox;
    },

    #
    # @param  string  text  Label of button.
    # @param  func  callback  Function which will be executed after click the button.
    # @return ghost  Button widget.
    #
    _getButton: func(text, callback) {
        return canvas.gui.widgets.Button.new(me._tabsContent, canvas.style, {})
            .setText(text)
            .listen("clicked", callback);
    },

    #
    # Update buttons with nearest airports.
    #
    # @return void
    #
    _updateNearestAirportButtons: func() {
        # logprint(LOG_ALERT, "Which Runway ----- _updateNearestAirportButtons call");
        var airports = findAirportsWithinRange(50);
        var airportSize = size(airports);

        forindex (var index; me._btnLoadICAOs.vector) {
            var airport = index < airportSize ? airports[index] : nil;

            if (airport == nil) {
                # logprint(LOG_ALERT, "Which Runway ----- _updateNearestAirportButtons button ", index, " disable");

                me._btnLoadICAOs.vector[index]
                    .setText("----")
                    .setVisible(false)
                    .listen("clicked", nil);
            } else {
                # logprint(LOG_ALERT, "Which Runway ----- _updateNearestAirportButtons button ", index, " enable with ICAO ", airport.id);

                func() {
                    var icao = airport.id;

                    me._btnLoadICAOs.vector[index]
                        .setText(icao)
                        .setVisible(true)
                        .listen("clicked", func() {
                            me._downloadMetar(icao);
                        });
                }();
            }
        }
    },
};
