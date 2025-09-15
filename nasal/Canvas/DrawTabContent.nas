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
    PADDING       : 10,
    METAR_RANGE_NM: 30,

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
            me._btnLoadIcaos = std.Vector.new();
            for (var i = 0; i < 5; i += 1) {
                me._btnLoadIcaos.append(canvas.gui.widgets.Button.new(me._tabsContent, canvas.style, {}).setText("----"));
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

        ########################################################################

        me._metar = Metar.new(tabId, me, me._metarUpdatedCallback, me._realWxUpdatedCallback);
        me._draw = Draw.new(me._scrollContent);
        me._drawMetar = DrawMetar.new(me._draw, me._metar);
        me._drawRunways = DrawRunways.new(me._draw, me._metar);

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
        me._drawRunways.del();
        me._drawMetar.del();
        me._draw.del();
        me._metar.del();
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
        elsif (me._isTabDeparture()) return "/autopilot/route-manager/departure/airport";
        elsif (me._isTabArrival())   return "/autopilot/route-manager/destination/airport";
        elsif (me._isTabAlternate()) return nil;

        return nil;
    },

    #
    # Get error message if ICAO is null or empty.
    #
    # @return string
    #
    _getNoIcaoMessage: func() {
           if (me._isTabNearest())   return "Cannot find the ICAO code of the nearest airport, please enter the ICAO code manually.";
        elsif (me._isTabDeparture()) return "No ICAO code. Enter the departure airport in Route Manager first.";
        elsif (me._isTabArrival())   return "No ICAO code. Enter the arrival airport in Route Manager first.";

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

        var airport = globals.airportinfo(me._icao);
        if (airport == nil) {
            me._reDrawContentWithMessage("ICAO code `" ~ me._icao ~ "` not found!", true);
            return;
        }

        if (!me._metar.isRealWeatherEnabled()) {
            # Redraw without METAR data.
            me._metar.disableMetarFromNearestAirport();
            me._reDrawContent();
            return;
        }

        if (airport.has_metar) {
            # Download METAR from current airport.
            me._reDrawContentWithMessage("Loading...");
            me._metar.download(icao: me._icao, force: true);
            return;
        }

        # Try downloading a METAR from the nearest airport.
        var nearestAirport = me._getNearestAirportWithMetar(airport);
        if (nearestAirport == nil) {
            # Not found, redraw without METAR data.
            me._metar.disableMetarFromNearestAirport();
            me._reDrawContent();
            return;
        }

        me._reDrawContentWithMessage("Loading...");
        me._metar.download(icao: nearestAirport.id, force: true, isNearest: true);
    },

    #
    # Get nearest airport which has a METAR.
    #
    # @param  ghost  airport  The airport we are searching around.
    # @param  airport|nil  Airport or nil if not found.
    #
    _getNearestAirportWithMetar: func(airport) {
        var airports = globals.findAirportsWithinRange(airport, DrawTabContent.METAR_RANGE_NM);
        foreach (var nearest; airports) {
            if (nearest.has_metar) {
                return nearest;
            }
        }

        return nil;
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

        me._draw.printMessage(message, isError);

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

        var airport = globals.airportinfo(me._icao);
        if (airport == nil) {
            me._draw.printMessage("ICAO code `" ~ me._icao ~ "` not found!", true);
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
    # @return double  New position of y shifted by height of printed line.
    #
    _drawAirportAndMetar: func(airport) {
        var x = 0;
        var y = 0;

        y += me._draw.printLineAirportName(x, y, airport).y;
        y += me._draw.printLineWithValue(x, y, "Lat, Lon:", me._getLatLonInfo(airport)).y;
        y += me._draw.printLineWith2Values(x, y, "Elevation:", math.round(airport.elevation * globals.M2FT), "ft", math.round(airport.elevation), "m").y;
        y += me._draw.printLineWithValue(x, y, "Mag Var:", sprintf("%.2f°", magvar(airport))).y;
        y += me._draw.printLineWithValue(x, y, "Has METAR:", airport.has_metar ? "Yes" : "No").y;
        y += Draw.MARGIN_Y;

        y = me._drawMetar.drawMetar(x, y, airport);

        var qnhValues = me._metar.getQnhValues(airport);
        var qfeValues = me._metar.getQfeValues(airport);

        y += qnhValues == nil
            ? me._draw.printLineWithValue(x, y, "QNH:", "n/a").y
            : me._draw.printLineAtmosphericPressure(x, y, "QNH:", qnhValues).y;

        y += qfeValues == nil
            ? me._draw.printLineWithValue(x, y, "QFE:", "n/a").y
            : me._draw.printLineAtmosphericPressure(x, y, "QFE:", qfeValues).y;

        y += (Draw.MARGIN_Y * 2);

        # Wind
        y += me._draw.printLineWind(x, y, "Wind " ~ me._getWindInfoText(airport)).y;

        y += (Draw.MARGIN_Y * 4);

        return y;
    },

    #
    # @param  ghost  airport
    # @return string
    #
    _getWindInfoText: func(airport) {
        if (me._metar.canUseMetar(airport)) {
            var windDir = me._metar.getWindDir(airport);
            windDir = windDir == nil
                ? "variable"
                : math.round(windDir) ~ "°";

            var result = windDir ~ " at " ~ math.round(me._metar.getWindSpeedKt()) ~ " kts";

            var gust = math.round(me._metar.getWindGustSpeedKt());
            if (gust > 0) {
                result ~= " with gust at " ~ gust ~ " kts";
            }

            return result;
        }

        return "n/a";
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
        elsif (me._isTabDeparture() or me._isTabArrival()) return me._drawBottomBarForScheduledTab();
        elsif (me._isTabAlternate())                       return me._drawBottomBarForAlternate();

        return nil;
    },

    #
    # @return ghost  Canvas layout object with controls.
    #
    _drawBottomBarForNearest: func() {
        var buttonBox = canvas.HBoxLayout.new();

        buttonBox.addStretch(1);
        foreach (var btn; me._btnLoadIcaos.vector) {
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
                    var newIcao = getprop("/sim/airport/closest-airport-id");
                    if (newIcao != me._icao) {
                        me._downloadMetar(newIcao);
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
        foreach (var btn; me._btnLoadIcaos.vector) {
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
        var airports = globals.findAirportsWithinRange(50); # range in NM
        var airportSize = size(airports);

        forindex (var index; me._btnLoadIcaos.vector) {
            var airport = index < airportSize ? airports[index] : nil;

            if (airport == nil) {
                # logprint(LOG_ALERT, "Which Runway ----- _updateNearestAirportButtons button ", index, " disable");

                me._btnLoadIcaos.vector[index]
                    .setText("----")
                    .setVisible(false)
                    .listen("clicked", nil);
            } else {
                # logprint(LOG_ALERT, "Which Runway ----- _updateNearestAirportButtons button ", index, " enable with ICAO ", airport.id);

                func() {
                    var icao = airport.id;

                    me._btnLoadIcaos.vector[index]
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
