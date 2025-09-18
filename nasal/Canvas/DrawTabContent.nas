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
    # @return hash
    #
    new: func(tabsContent, tabContent, tabId) {
        var me = { parents: [DrawTabContent] };

        me._tabsContent = tabsContent;
        me._tabContent = tabContent;
        me._tabId = tabId;
        me._icao = "";
        me._icaoEdit = nil;
        me._isHoldUpdateNearest = false;

        me._metar = Metar.new(me._tabId, me, me._metarUpdatedCallback, me._realWxUpdatedCallback);
        me._runwaysData = RunwaysData.new(me._metar);

        me._scrollArea = me._createScrollArea();

        me._scrollContent = me._getScrollAreaContent(
            context  : me._scrollArea,
            font     : Fonts.SANS_REGULAR,
            fontSize : 16,
            alignment: "left-baseline",
        );
        me._scrollLayout = canvas.VBoxLayout.new();
        me._scrollArea.setLayout(me._scrollLayout);
        me._tabContent.addItem(me._scrollArea, 1); # 2nd param = stretch

        me._messageView = canvas.gui.widgets.MessageView.new(me._scrollContent, canvas.style, {})
            .setVisible(true);

        me._airportInfoView = canvas.gui.widgets.AirportInfoView.new(me._scrollContent, canvas.style, {})
            .setVisible(false);

        me._metarInfoView = canvas.gui.widgets.MetarInfoView.new(me._scrollContent, canvas.style, {})
            .setVisible(false)
            .setMetarRangeNm(DrawTabContent.METAR_RANGE_NM);

        me._weatherInfoView = canvas.gui.widgets.WeatherInfoView.new(me._scrollContent, canvas.style, {})
            .setVisible(false);

        me._runwaysLayout = canvas.VBoxLayout.new();

        me._scrollLayout.addItem(me._messageView, 1);
        me._scrollLayout.addItem(me._airportInfoView);
        me._scrollLayout.addItem(me._metarInfoView);
        me._scrollLayout.addItem(me._weatherInfoView);
        me._scrollLayout.addItem(me._runwaysLayout);

        # Add some stretch in case the scroll area is larger than the content
        me._scrollLayout.addStretch(1);


        # Build 16 slots for runways
        me._runwayWidgets = std.Vector.new();
        for (var i = 0; i < 16; i += 1) {
            var runwayHLayout = canvas.HBoxLayout.new();

            var runwayInfoView = canvas.gui.widgets.RunwayInfoView.new(me._scrollContent, canvas.style, {})
                .setVisible(false);

            var windRoseView = canvas.gui.widgets.WindRoseView.new(me._scrollContent, canvas.style, {})
                .setVisible(false);

            var runwayVCenter = canvas.VBoxLayout.new(); # wrapper for set runway info vertically centered
            runwayVCenter.addStretch(1);
            runwayVCenter.addItem(runwayInfoView, 1);
            runwayVCenter.addStretch(1);

            runwayHLayout.addItem(runwayVCenter, 1);
            runwayHLayout.addItem(windRoseView, 2);

            me._runwaysLayout.addItem(runwayHLayout);

            me._runwayWidgets.append({
                runwayInfoView: runwayInfoView,
                windRoseView: windRoseView,
            });
        }

        if (me._isTabNearest() or me._isTabAlternate()) {
            me._btnLoadIcaos = std.Vector.new();
            for (var i = 0; i < 5; i += 1) {
                var btn = canvas.gui.widgets.Button.new(me._tabsContent, canvas.style, {})
                    .setText("----");

                me._btnLoadIcaos.append(btn);
            }
        }

        me._drawBottomBar();

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
        me._runwaysData.del();
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
        var scrollArea = canvas.gui.widgets.ScrollArea.new(me._tabsContent, canvas.style, {});

        scrollArea.setColorBackground(canvas.style.getColor("bg_color"));
        scrollArea.setContentsMargins(
            DrawTabContent.PADDING, # left
            0,                      # top
            0,                      # right
            0,                      # bottom
        );

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
            me._reDrawContentWithMessage("ICAO code \"" ~ me._icao ~ "\" not found!", true);
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
        me._airportInfoView.setVisible(false);
        me._metarInfoView.setVisible(false);
        me._weatherInfoView.setVisible(false);

        me._hideAllRunways();

        me._messageView
            .setText(message, isError)
            .setVisible(true)
            .updateView();

        me._scrollArea.scrollToTop();
        me._scrollArea.scrollToLeft();
    },

    #
    # Hide all runways widgets.
    #
    # @return void
    #
    _hideAllRunways: func() {
        foreach (var widget; me._runwayWidgets.vector) {
            widget.runwayInfoView.setVisible(false);
            widget.windRoseView.setVisible(false);
        }
    },

    #
    # Draw whole content.
    #
    # @return void
    #
    _reDrawContent: func() {
        var airport = globals.airportinfo(me._icao);
        if (airport == nil) {
            me._reDrawContentWithMessage("ICAO code \"" ~ me._icao ~ "\" not found!", true);
            return;
        }

        var aptMagVar = globals.magvar(airport);

        me._messageView.setVisible(false);

        me._airportInfoView
            .setAirport(airport)
            .setAirportMagVar(aptMagVar)
            .setVisible(true)
            .updateView();

        me._metarInfoView
            .setIsRealWeatherEnabled(me._metar.isRealWeatherEnabled())
            .setIsMetarFromNearestAirport(me._metar.isMetarFromNearestAirport())
            .setDistanceToStation(me._metar.getDistanceToStation(airport))
            .setMetarIcao(me._metar.getIcao())
            .setMetar(me._metar.getMetar(airport))
            .setVisible(true)
            .updateView();

        me._weatherInfoView
            .setIsMetarData(me._metar.canUseMetar(airport))
            .setWind(
                me._metar.getWindDir(airport),
                me._metar.getWindSpeedKt(),
                me._metar.getWindGustSpeedKt(),
            )
            .setQnhValues(me._metar.getQnhValues(airport))
            .setQfeValues(me._metar.getQfeValues(airport))
            .setVisible(true)
            .updateView();


        var runways = me._runwaysData.getRunways(airport);
        var runwaysSize = size(runways);
        var runwayWidgetsSize = me._runwayWidgets.size();

        if (runwaysSize > runwayWidgetsSize) {
            logprint(LOG_ALERT, "Which Runway ----- ", airport.id, " has ", runwaysSize,
                " runways (including helipads), more than allocated (", runwayWidgetsSize, ")"
            );
        }

        forindex (var index; me._runwayWidgets.vector) {
            var widgets = me._runwayWidgets.vector[index];

            if (index >= runwaysSize) {
                widgets.runwayInfoView.setVisible(false);
                widgets.windRoseView.setVisible(false);
                continue;
            }

            var rwy = runways[index];

            widgets.runwayInfoView
                .setRunwayData(rwy)
                .setAirportMagVar(aptMagVar)
                .setVisible(true)
                .updateView();

            widgets.windRoseView
                .setRadius(175)
                .setWind(
                    me._metar.getWindDir(airport),
                    me._metar.getWindSpeedKt(),
                )
                .setRunway(rwy)
                .setRunways(runways)
                .setVisible(true)
                .updateView();
        }

        me._scrollArea.scrollToTop();
        me._scrollArea.scrollToLeft();
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
