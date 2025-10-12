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
# DrawTabContent class.
#
var DrawTabContent = {
    #
    # Statics:
    #
    PADDING           :  10,
    APT_VALUE_MARGIN_X: 100, # the distance between label and value for airport info.
    RWY_VALUE_MARGIN_X:  95, # the distance between label and value for runways info.
    MAX_RUNWAY_SLOTS  :  16,

    #
    # Constructor.
    #
    # @param  ghost  tabsContent  Tabs canvas content.
    # @param  ghost  tabContent  Single tab canvas content.
    # @param  string  tabId
    # @param  hash  runwayUse  RwyUse object.
    # @param  hash  basicWeather  BasicWeather object.
    # @param  string  aircraftType  As "com", "gen", "mil, "ul".
    # @return hash
    #
    new: func(tabsContent, tabContent, tabId, runwayUse, basicWeather, aircraftType) {
        var obj = {
            parents: [
                DrawTabContent,
                DrawTabBase.new(tabId),
            ],
            _tabsContent: tabsContent,
            _tabContent: tabContent,
            _runwayUse: runwayUse,
            _basicWeather: basicWeather,
            _aircraftType: aircraftType,
        };

        obj._icao = "";
        obj._icaoEdit = nil;

        obj._metar = Metar.new(
            obj._tabId,
            obj._basicWeather,
            Callback.new(obj._metarUpdatedCallback, obj),
            Callback.new(obj._realWxUpdatedCallback, obj),
        );

        obj._basicWeather.registerEngineWxChangeCallback(Callback.new(obj._weatherEngineChangedCallback, obj));
        obj._basicWeather.registerWxChangeCallback(Callback.new(obj._metarUpdatedCallback, obj));

        obj._runwayFinder = RunwayFinder.new(obj._metar, obj._runwayUse);

        obj._topBar = TopBar.new(
            obj._tabsContent,
            Callback.new(obj._scrollToAirport, obj),
            Callback.new(obj._scrollToRunway, obj),
        );

        obj._bottomBar = BottomBar.new(
            obj._tabsContent,
            obj._tabId,
            Callback.new(obj._downloadMetar, obj),
        );

        var scrollMargins = {
            left  : DrawTabContent.PADDING,
            top   : 0,
            right : 0,
            bottom: 0,
        };

        obj._scrollArea = ScrollAreaHelper.create(obj._tabsContent, scrollMargins);
        obj._scrollContent = ScrollAreaHelper.getContent(
            context  : obj._scrollArea,
            font     : canvas.font_mapper("sans"),
            fontSize : 16,
            alignment: "left-baseline",
        );

        obj._scrollLayout = canvas.VBoxLayout.new();
        obj._scrollArea.setLayout(obj._scrollLayout);

        obj._tabContent.addSpacing(10);
        obj._tabContent.addItem(obj._topBar.drawTopBar());
        obj._tabContent.addSpacing(10);
        obj._tabContent.addItem(obj._scrollArea, 1); # 2nd param = stretch
        obj._tabContent.addSpacing(10);
        obj._tabContent.addItem(obj._getBottomBarByTabId());
        obj._tabContent.addSpacing(10);

        obj._messageView = canvas.gui.widgets.MessageLabel.new(parent: obj._scrollContent, cfg: { colors: Colors })
            .setVisible(true);

        obj._airportInfoView = canvas.gui.widgets.AirportInfo.new(obj._scrollContent)
            .setMarginForValue(DrawTabContent.APT_VALUE_MARGIN_X)
            .setVisible(false);

        obj._metarInfoView = canvas.gui.widgets.MetarInfo.new(parent: obj._scrollContent, cfg: { colors: Colors })
            .setVisible(false);

        obj._pressureLabelQnh = canvas.gui.widgets.PressureLabel.new(obj._scrollContent)
            .setMarginForValue(DrawTabContent.APT_VALUE_MARGIN_X)
            .setLabel("QNH:")
            .setVisible(false);

        obj._pressureLabelQfe = canvas.gui.widgets.PressureLabel.new(obj._scrollContent)
            .setMarginForValue(DrawTabContent.APT_VALUE_MARGIN_X)
            .setLabel("QFE:")
            .setVisible(false);

        obj._windLabel = canvas.gui.widgets.WindLabel.new(parent: obj._scrollContent, cfg: { colors: Colors })
            .setVisible(false);

        obj._drawRwyUseControls = DrawRwyUseControls.new(
            obj._tabId,
            obj._scrollContent,
            Callback.new(obj._reDrawContent, obj),
            obj._aircraftType,
        );

        obj._rwyUseLayout = obj._drawRwyUseControls.createRwyUseLayout();

        obj._rwyUseNoDataWarning = canvas.gui.widgets.Label.new(obj._scrollContent)
            .setText("The preferred runway cannot be selected, so the best headwind is used.")
            .setVisible(false);
        obj._rwyUseNoDataWarning.setColor(Colors.AMBER);

        obj._runwaysLayout = canvas.VBoxLayout.new();

        obj._scrollLayout.addSpacing(10);
        obj._scrollLayout.addItem(obj._messageView, 1); # 2nd param = stretch
        obj._scrollLayout.addSpacing(10);
        obj._scrollLayout.addItem(obj._airportInfoView);
        obj._scrollLayout.addSpacing(10);
        obj._scrollLayout.addItem(obj._metarInfoView);
        obj._scrollLayout.addSpacing(10);
        obj._scrollLayout.addItem(obj._pressureLabelQnh);
        obj._scrollLayout.addItem(obj._pressureLabelQfe);
        obj._scrollLayout.addSpacing(20);
        obj._scrollLayout.addItem(obj._windLabel);
        obj._scrollLayout.addSpacing(20);
        obj._scrollLayout.addItem(obj._rwyUseLayout);
        obj._scrollLayout.addItem(obj._rwyUseNoDataWarning);
        obj._scrollLayout.addSpacing(0);
        obj._scrollLayout.addItem(obj._runwaysLayout);

        # Add some stretch in case the scroll area is larger than the content
        obj._scrollLayout.addStretch(1);

        # Build x slots for runways
        obj._runwayWidgets = std.Vector.new();
        for (var i = 0; i < DrawTabContent.MAX_RUNWAY_SLOTS; i += 1) {
            var runwayHLayout = canvas.HBoxLayout.new();

            var runwayInfoView = canvas.gui.widgets.RunwayInfo.new(parent: obj._scrollContent, cfg: { colors: Colors })
                .setMarginForValue(DrawTabContent.RWY_VALUE_MARGIN_X)
                .setVisible(false)
                .setHwXwThresholds(Metar.HEADWIND_THRESHOLD, Metar.CROSSWIND_THRESHOLD);

            var windRoseView = canvas.gui.widgets.WindRose.new(parent: obj._scrollContent, cfg: { colors: Colors })
                .setVisible(false)
                .setHwXwThresholds(Metar.HEADWIND_THRESHOLD, Metar.CROSSWIND_THRESHOLD);

            var runwayVCenter = canvas.VBoxLayout.new(); # wrapper for set runway info vertically centered
            runwayVCenter.addStretch(1);
            runwayVCenter.addItem(runwayInfoView, 1);
            runwayVCenter.addStretch(1);

            runwayHLayout.addItem(runwayVCenter, 1);
            runwayHLayout.addItem(windRoseView, 2);

            obj._runwaysLayout.addItem(runwayHLayout);

            obj._runwayWidgets.append({
                runwayInfoView: runwayInfoView,
                windRoseView: windRoseView,
            });
        }

        obj._listeners = Listeners.new();
        obj._setListeners();

        if (obj._isTabAlternate()) {
            obj._reDrawContentWithMessage("Enter the ICAO code of an airport below.");
        }

        return obj;
    },

    #
    # Destructor.
    #
    # @return void
    #
    del: func() {
        me._listeners.del();
        me._runwayFinder.del();
        me._metar.del();
        me._bottomBar.del();
        me._drawRwyUseControls.del();

        call(DrawTabBase.del, [], me);
    },

    #
    # Set listeners.
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
                    me._reDrawContent(false);
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
    # Get error message if ICAO is nil or empty.
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

        var newIcao = string.uc(icao);
        if (newIcao != me._icao) {
            # ICAO changed, set current UTC time
            me._drawRwyUseControls.setUtcTimeToCurrent();
        }

        me._icao = newIcao;

        me._bottomBar.setIcao(me._icao);

        var airport = airportinfo(me._icao);
        if (airport == nil) {
            me._reDrawContentWithMessage("ICAO code \"" ~ me._icao ~ "\" not found!", true);
            return;
        }

        if (me._basicWeather.isBasicWxManCfgEnabled() or !me._metar.isRealWeatherEnabled()) {
            # Redraw with basic weather without METAR
            # or
            # Redraw with offline METAR data.
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
        var airports = findAirportsWithinRange(airport, g_Settings.getMaxMetarRangeNm());
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
        me._reDrawContent(false);
    },

    #
    # Callback function, called when real weather flag han been changed.
    #
    # @return void
    #
    _realWxUpdatedCallback: func() {
        me.reload();
    },

    #
    # Callback function, called when weather engine han been changed.
    #
    # @return void
    #
    _weatherEngineChangedCallback: func() {
        me.reload();
    },

    #
    # Reload all view with METAR.
    #
    # @return void
    #
    reload: func() {
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

        me._scrollToAirport();
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
    # @param  bool  isResetScroll  True means that the scroll position will be set to 0, 0 (top-left position).
    # @return void
    #
    _reDrawContent: func(isResetScroll = true) {
        if (g_isDevMode) {
            Profiler.start("DrawTabContent._reDrawContent " ~ me._tabId);
        }

        var airport = airportinfo(me._icao);
        if (airport == nil) {
            me._reDrawContentWithMessage(me._getNoIcaoMessage(), true);
            return;
        }

        var aptMagVar = magvar(airport);

        me._messageView.setVisible(false);

        me._airportInfoView
            .setAirport(airport)
            .setAirportMagVar(aptMagVar)
            .setVisible(true)
            .updateView();

        me._metarInfoView
            .setMetarRangeNm(g_Settings.getMaxMetarRangeNm())
            .setIsBasicWxEnabled(me._basicWeather.isBasicWxManCfgEnabled())
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
            .setIsWindData(me._basicWeather.isBasicWxManCfgEnabled() or me._metar.canUseMetar(airport))
            .setWind(
                me._metar.getWindDir(airport),
                me._metar.getWindSpeedKt(),
                me._metar.getWindGustSpeedKt(),
            )
            .setVisible(true)
            .updateView();

        me._reDrawRunways(airport, aptMagVar);

        if (isResetScroll) {
            me._scrollToAirport();
        }

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

        var runways = me._runwayFinder.getRunways(
            airport: airport,
            isRwyUse: me._drawRwyUseControls.isRwyUse(),
            aircraftType: me._drawRwyUseControls.getAircraftType(),
            isTakeoff: me._drawRwyUseControls.isTakeoff(),
            utcHour: scheduleUtcHour,
            utcMinute: scheduleUtcMinute,
        );

        if (g_Settings.getRwyUseEnabled()) {
            var rwyUseStatus = me._runwayFinder.getRwyUseStatus();
            if (rwyUseStatus == RunwayFinder.CODE_NO_XML) {
                me._rwyUseLayout.setVisible(false);
                me._rwyUseNoDataWarning
                    .setText("The airport does not have data on preferred runways, so the best headwind is used.")
                    .setVisible(true);
            } else {
                me._rwyUseLayout.setVisible(true);

                if (rwyUseStatus == RunwayFinder.CODE_NO_SCHEDULE
                    or rwyUseStatus == RunwayFinder.CODE_NO_WIND_CRITERIA
                ) {
                    me._rwyUseNoDataWarning
                        .setText(me._getWarningMsgForNoRwyUse(rwyUseStatus))
                        .setVisible(true);
                } else {
                    me._rwyUseNoDataWarning.setVisible(false);
                }

                var acType = me._drawRwyUseControls.getAircraftType();
                var windCriteria = me._runwayUse.getWind(me._icao, acType);
                var traffic = me._runwayUse.getUsedTrafficFullName(me._icao, acType);
                var dailyOpHours = me._runwayUse.getDailyOperatingHours(me._icao, acType);

                var schedule = me._runwayUse.getScheduleByTime(
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

        me._topBar.updateRunwayButtons(me._icao, runways);
    },

    #
    # Get warning message for no rwyuse data.
    #
    # @param  int  rwyUseStatus
    # @return string
    #
    _getWarningMsgForNoRwyUse: func(rwyUseStatus) {
        if (rwyUseStatus == RunwayFinder.CODE_NO_SCHEDULE) {
            return "No preferred runway for the selected time, so the best headwind is used.";
        } elsif (rwyUseStatus == RunwayFinder.CODE_NO_WIND_CRITERIA) {
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

    #
    # Scroll content to show airport info.
    #
    # @return void
    #
    _scrollToAirport: func() {
        me._scrollArea.scrollToTop();
        me._scrollArea.scrollToLeft();
    },

    #
    # Scroll content to show runway by given runway index.
    #
    # @param  int  index
    # @return void
    #
    _scrollToRunway: func(index) {
        if (me._runwaysLayout == nil) {
            return;
        }

        var count = me._runwaysLayout.count();
        if (index < 0 or index >= count) {
            return;
        }

        var item = me._runwaysLayout.itemAt(index);
        if (item == nil) {
            return;
        }

        var (x, y, w, h) = item.geometry();
        if (h == 0) {
            # The runwayInfoView and windRoseView widgets inside item are invisible
            return;
        }

        var scale = me._getScrollHeightScale();

        me._scrollArea.vertScrollBarTo(y * scale);
    },

    #
    # Called periodically to update dynamic data.
    #
    # @return void
    #
    updateDynamicData: func() {
        if (me._airportInfoView != nil and me._airportInfoView.isVisible()) {
            me._airportInfoView.updateDynamicData();
        }
    },

    #
    # @return double
    #
    _getScrollHeightScale: func() {
        # TODO: use ScrollArea methods as they become available.
        var scrollTrackHeight = me._scrollArea._scroller_delta[1];
        var contentHeight     = me._scrollArea._max_scroll[1];
        if (contentHeight == 0) {
            contentHeight = 1; # prevent divide by 0
        }

        return scrollTrackHeight / contentHeight;
    },

    #
    # @return double
    #
    getScrollPageHeight: func() {
        # TODO: use ScrollArea methods as they become available.
        var contentHeight = me._scrollArea._content_size[1];
        var maxScroll     = me._scrollArea._max_scroll[1];
        var scrollerTrack = me._scrollArea._scroller_delta[1];

        if (maxScroll == 0 or scrollerTrack == 0) {
            return 0;
        }

        var visibleHeight = contentHeight - maxScroll;
        return (visibleHeight / maxScroll) * scrollerTrack;
    },
};
