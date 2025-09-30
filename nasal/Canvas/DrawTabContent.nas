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
    VALUE_MARGIN_X: 110, # the distance between label and value.

    #
    # Constructor
    #
    # @param  ghost  tabsContent  Tabs canvas content.
    # @param  ghost  tabContent  Single tab canvas content.
    # @param  string  tabId
    # @param  hash  runwaysUse  RwyUse object.
    # @return hash
    #
    new: func(tabsContent, tabContent, tabId, runwaysUse) {
        var me = {
            parents: [
                DrawTabContent,
                DrawTabBase.new(tabId),
            ],
            _tabsContent: tabsContent,
            _tabContent: tabContent,
            _runwaysUse: runwaysUse,
        };

        me._icao = "";
        me._icaoEdit = nil;

        me._timer = Timer.make(3, me, me._updateDynamicData);

        me._metar = Metar.new(
            me._tabId,
            Callback.new(me._metarUpdatedCallback, me),
            Callback.new(me._realWxUpdatedCallback, me),
        );
        me._runwaysData = RunwaysData.new(me._metar, me._runwaysUse);

        me._bottomBar = BottomBar.new(
            tabsContent: me._tabsContent,
            tabId: me._tabId,
            downloadMetarCallback: Callback.new(me._downloadMetar, me),
        );

        var scrollMargins = {
            left  : DrawTabContent.PADDING,
            top   : 0,
            right : 0,
            bottom: 0,
        };

        me._scrollArea = ScrollAreaHelper.create(me._tabsContent, scrollMargins);
        me._scrollContent = ScrollAreaHelper.getContent(
            context  : me._scrollArea,
            font     : canvas.font_mapper("sans"),
            fontSize : 16,
            alignment: "left-baseline",
        );

        me._scrollLayout = canvas.VBoxLayout.new();
        me._scrollArea.setLayout(me._scrollLayout);
        me._tabContent.addItem(me._scrollArea, 1); # 2nd param = stretch
        me._tabContent.addSpacing(10);
        me._tabContent.addItem(me._getBottomBarByTabId());
        me._tabContent.addSpacing(10);

        me._messageView = canvas.gui.widgets.MessageLabel.new(parent: me._scrollContent, cfg: { colors: Colors })
            .setVisible(true);

        me._airportInfoView = canvas.gui.widgets.AirportInfo.new(me._scrollContent)
            .setMarginForValue(DrawTabContent.VALUE_MARGIN_X)
            .setVisible(false);

        me._metarInfoView = canvas.gui.widgets.MetarInfo.new(parent: me._scrollContent, cfg: { colors: Colors })
            .setVisible(false);
            # .setMetarRangeNm(DrawTabContent.METAR_RANGE_NM);

        me._pressureLabelQnh = canvas.gui.widgets.PressureLabel.new(me._scrollContent)
            .setMarginForValue(DrawTabContent.VALUE_MARGIN_X)
            .setLabel("QNH:")
            .setVisible(false);

        me._pressureLabelQfe = canvas.gui.widgets.PressureLabel.new(me._scrollContent)
            .setMarginForValue(DrawTabContent.VALUE_MARGIN_X)
            .setLabel("QFE:")
            .setVisible(false);

        me._windLabel = canvas.gui.widgets.WindLabel.new(parent: me._scrollContent, cfg: { colors: Colors })
            .setVisible(false);

        me._drawRwyUseControls = DrawRwyUseControls.new(
            me._tabId,
            me._scrollContent,
            Callback.new(me._reDrawContent, me),
        );

        me._rwyUseLayout = me._drawRwyUseControls.createRwyUseLayout();

        me._rwyUseNoDataWarning = canvas.gui.widgets.Label.new(me._scrollContent)
            .setText("The preferred runway cannot be selected, so the best headwind is used.")
            .setVisible(false);
        me._rwyUseNoDataWarning.setColor(Colors.AMBER);

        me._runwaysLayout = canvas.VBoxLayout.new();

        me._scrollLayout.addSpacing(10);
        me._scrollLayout.addItem(me._messageView, 1); # 2nd param = stretch
        me._scrollLayout.addSpacing(10);
        me._scrollLayout.addItem(me._airportInfoView);
        me._scrollLayout.addSpacing(10);
        me._scrollLayout.addItem(me._metarInfoView);
        me._scrollLayout.addSpacing(10);
        me._scrollLayout.addItem(me._pressureLabelQnh);
        me._scrollLayout.addItem(me._pressureLabelQfe);
        me._scrollLayout.addSpacing(20);
        me._scrollLayout.addItem(me._windLabel);
        me._scrollLayout.addSpacing(20);
        me._scrollLayout.addItem(me._rwyUseLayout);
        me._scrollLayout.addItem(me._rwyUseNoDataWarning);
        me._scrollLayout.addSpacing(0);
        me._scrollLayout.addItem(me._runwaysLayout);

        # Add some stretch in case the scroll area is larger than the content
        me._scrollLayout.addStretch(1);

        # Build 16 slots for runways
        me._runwayWidgets = std.Vector.new();
        for (var i = 0; i < 16; i += 1) {
            var runwayHLayout = canvas.HBoxLayout.new();

            var runwayInfoView = canvas.gui.widgets.RunwayInfo.new(parent: me._scrollContent, cfg: { colors: Colors })
                .setMarginForValue(DrawTabContent.VALUE_MARGIN_X)
                .setVisible(false);

            var windRoseView = canvas.gui.widgets.WindRose.new(parent: me._scrollContent, cfg: { colors: Colors })
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
        me._bottomBar.del();
        me._drawRwyUseControls.del();

        me._timer.stop();

        call(DrawTabBase.del, [], me);
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
                        me._bottomBar.updateNearestAirportButtons();

                        if (me._bottomBar.isHoldUpdateNearest()) {
                            # The ICAO code update is blocked by a checkbox, so we're leaving.
                            return;
                        }
                    }

                    if (node != nil) {
                        Log.print(me._tabId, " got a new ICAO = ", node.getValue());
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
                code: func { me._bottomBar.updateNearestAirportButtons(); },
                init: true, # if set to true, the listener will additionally be triggered when it is created.
                type: Listeners.ON_CHANGE_ONLY, # the listener will only trigger when the property is changed.
            );
        }

        me._listeners.add(
            node: me._addonNodePath ~ "/settings/rwyuse/aircraft-type",
            code: func(node) {
                if (node != nil) {
                    me._drawRwyUseControls.setAircraftType(node.getValue());
                    me._reDrawContent();
                }
            },
            type: Listeners.ON_CHANGE_ONLY,
        );
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
        elsif (me._isTabAlternate()) return "Enter the ICAO code of an airport below.";

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

        var newIcao = globals.string.uc(icao);
        if (newIcao != me._icao) {
            # ICAO changed, set current UTC time
            me._drawRwyUseControls.setUtcTimeToCurrent();
        }

        me._icao = newIcao;

        me._bottomBar.setIcao(me._icao);

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
        var airports = globals.findAirportsWithinRange(airport, g_Settings.getMaxMetarRangeNm());
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
        me._pressureLabelQnh.setVisible(false);
        me._pressureLabelQfe.setVisible(false);
        me._windLabel.setVisible(false);
        me._rwyUseNoDataWarning.setVisible(false);
        me._rwyUseLayout.setVisible(false);
        me._drawRwyUseControls.getRwyUseInfoWidget().setVisible(false);

        me._hideAllRunways();

        me._messageView
            .setText(message, isError)
            .setVisible(true)
            .updateView();

        me._scrollArea.scrollToTop();
        me._scrollArea.scrollToLeft();

        me._timer.stop();
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
        if (g_isDevMode) {
            Profiler.start("DrawTabContent._reDrawContent " ~ me._tabId);
        }

        var airport = globals.airportinfo(me._icao);
        if (airport == nil) {
            me._reDrawContentWithMessage(me._getNoIcaoMessage(), true);
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
            .setMetarRangeNm(g_Settings.getMaxMetarRangeNm())
            .setIsRealWeatherEnabled(me._metar.isRealWeatherEnabled())
            .setIsMetarFromNearestAirport(me._metar.isMetarFromNearestAirport())
            .setDistanceToStation(me._metar.getDistanceToStation(airport))
            .setMetarIcao(me._metar.getIcao())
            .setMetar(me._metar.getMetar(airport))
            .setVisible(true)
            .updateView();

        var qnh = me._metar.getQnhValues(airport);
        me._pressureLabelQnh
            .setInHg(qnh == nil ? nil : qnh.inHg)
            .setHPa(qnh == nil ? nil : qnh.hPa)
            .setMmHg(qnh == nil ? nil : qnh.mmHg)
            .setVisible(true)
            .updateView();

        var qfe = me._metar.getQfeValues(airport);
        me._pressureLabelQfe
            .setInHg(qfe == nil ? nil : qfe.inHg)
            .setHPa(qfe == nil ? nil : qfe.hPa)
            .setMmHg(qfe == nil ? nil : qfe.mmHg)
            .setVisible(true)
            .updateView();

        me._windLabel
            .setIsMetarData(me._metar.canUseMetar(airport))
            .setWind(
                me._metar.getWindDir(airport),
                me._metar.getWindSpeedKt(),
                me._metar.getWindGustSpeedKt(),
            )
            .setVisible(true)
            .updateView();

        me._reDrawRunways(airport, aptMagVar);

        me._scrollArea.scrollToTop();
        me._scrollArea.scrollToLeft();

        me._timer.start();

        if (g_isDevMode) {
            Profiler.stop();
        }
    },

    #
    # @param  ghost  airport
    # @param  double  aptMagVar
    # @return void
    #
    _reDrawRunways: func(airport, aptMagVar) {
        var scheduleUtcHour   = me._drawRwyUseControls.getScheduleUtcHour();
        var scheduleUtcMinute = me._drawRwyUseControls.getScheduleUtcMinute();

        var runways = me._runwaysData.getRunways(
            airport: airport,
            isRwyUse: me._drawRwyUseControls.isRwyUse(),
            aircraftType: me._drawRwyUseControls.getAircraftType(),
            isTakeoff: me._drawRwyUseControls.isTakeoff(),
            utcHour: scheduleUtcHour,
            utcMinute: scheduleUtcMinute,
        );

        if (g_Settings.getRwyUseEnabled()) {
            var rwyUseStatus = me._runwaysData.getRwyUseStatus();
            if (rwyUseStatus == RunwaysData.CODE_NO_XML) {
                me._rwyUseLayout.setVisible(false);
                me._rwyUseNoDataWarning
                    .setText("The airport does not have data on preferred runways, so the best headwind is used.")
                    .setVisible(true);
            } else {
                me._rwyUseLayout.setVisible(true);

                if (rwyUseStatus == RunwaysData.CODE_NO_SCHEDULE
                    or rwyUseStatus == RunwaysData.CODE_NO_WIND_CRITERIA
                ) {
                    me._rwyUseNoDataWarning
                        .setText(me._getWarningMsgForNoRwyUse(rwyUseStatus))
                        .setVisible(true);
                } else {
                    me._rwyUseNoDataWarning.setVisible(false);
                }

                var acType = me._drawRwyUseControls.getAircraftType();
                var windCriteria = me._runwaysUse.getWind(me._icao, acType);
                var traffic = me._runwaysUse.getUsedTrafficFullName(me._icao, acType);
                var dailyOpHours = me._runwaysUse.getDailyOperatingHours(me._icao, acType);

                var schedule = me._runwaysUse.getScheduleByTime(
                    me._icao,
                    me._drawRwyUseControls.getAircraftType(),
                    scheduleUtcHour,
                    scheduleUtcMinute,
                );

                if (schedule == RwyUse.ERR_NO_SCHEDULE) {
                    schedule = nil;
                }

                me._drawRwyUseControls.getRwyUseInfoWidget()
                    .setUtcTime(sprintf("%02d:%02d", scheduleUtcHour, scheduleUtcMinute))
                    .setWindCriteria(
                        windCriteria == nil ? "n/a" : windCriteria.tail,
                        windCriteria == nil ? "n/a" : windCriteria.cross,
                    )
                    .setSchedule(schedule)
                    .setTraffic(traffic)
                    .setDailyOperatingHours(dailyOpHours)
                    .setVisible(me._drawRwyUseControls.isRwyUse())
                    .updateView();
            }
        } else {
            me._rwyUseLayout.setVisible(false);
            me._rwyUseNoDataWarning.setVisible(false);
        }

        var runwaysSize = size(runways);
        var runwayWidgetsSize = me._runwayWidgets.size();

        if (runwaysSize > runwayWidgetsSize) {
            Log.print(airport.id, " has ", runwaysSize,
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
    },

    #
    # Get warning message for no rwyuse data.
    #
    # @param  int  rwyUseStatus
    # @return string
    #
    _getWarningMsgForNoRwyUse: func(rwyUseStatus) {
        if (rwyUseStatus == RunwaysData.CODE_NO_SCHEDULE) {
            return "No preferred runway for the selected time, so the best headwind is used.";
        } elsif (rwyUseStatus == RunwaysData.CODE_NO_WIND_CRITERIA) {
            return "No preferred runway meets the wind criteria, so the best headwind is used.";
        }

        # General message
        return "The preferred runway cannot be selected, so the best headwind is used.";
    },

    #
    # Get bottom bar with buttons.
    #
    # @return ghost|nil  Canvas layout object with controls or nil if failed.
    #
    _getBottomBarByTabId: func() {
           if (me._isTabNearest())                         return me._bottomBar.drawBottomBarForNearest();
        elsif (me._isTabDeparture() or me._isTabArrival()) return me._bottomBar.drawBottomBarForScheduledTab();
        elsif (me._isTabAlternate())                       return me._bottomBar.drawBottomBarForAlternate();

        return nil;
    },

    #
    # Scroll content vertically.
    #
    # @param  int  dy  Delta Y in pixels. A negative value scrolls up, a positive value scrolls down.
    # @return void
    #
    vertScrollBarBy: func(dy) {
        me._scrollArea.vertScrollBarBy(dy);
    },

    _updateDynamicData: func() {
        me._airportInfoView.updateDynamicData();
    },
};
