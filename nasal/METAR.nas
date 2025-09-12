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
# Class to handle METAR
#
var METAR = {
    #
    # Static constants
    #
    HEADWIND_THRESHOLD : 45, # Headwind from 0 to 45
    CROSSWIND_THRESHOLD: 90, # Crosswind from 46 to 90, tailwind from 91

    #
    # Constructor
    #
    # @param  string  tabId  Tab ID.
    # @param  ghost  objCallbacks
    # @param  func  funcUpdatedCallback
    # @param  func  funcRealWxCallback
    # @return me
    #
    new: func(tabId, objCallbacks, funcUpdatedCallback, funcRealWxCallback) {
        var me = { parents: [METAR] };

        me._tabId = tabId;
        me._objCallbacks = objCallbacks;
        me._funcUpdatedCallback = funcUpdatedCallback;
        me._funcRealWxCallback = funcRealWxCallback;

        me._pathToMyMetar = g_Addon.node.getPath() ~ "/" ~ me._tabId ~ "/metar";

        me._realWxEnabledNode = props.globals.getNode("/environment/realwx/enabled");

        me._listeners = Listeners.new();
        me._setListeners();

        return me;
    },

    #
    # Destructor
    #
    # @return void
    #
    del: func() {
        me._listeners.del();
    },

    #
    # Set listeners.
    #
    # @return void
    #
    _setListeners: func() {
        # Redraw canvas if METAR has been changed.
        me._listeners.add(
            node: me._pathToMyMetar ~ "/data",
            code: func() {
                logprint(LOG_ALERT, "Which Runway ----- METAR for ", me._tabId, " has been updated");
                call(me._funcUpdatedCallback, [], me._objCallbacks);
            },
        );

        # Redraw canvas if Live Data is enabled/disabled.
        me._listeners.add(
            node: "/environment/realwx/enabled",
            code: func(node) {
                call(me._funcRealWxCallback, [], me._objCallbacks);
            },
            init: false,
            type: Listeners.ON_CHANGE_ONLY,
        );
    },

    #
    # Run FGCommand to download METAR for given ICAO code.
    #
    # @param  string  icao  ICAO code of airport.
    # @param  bool  force
    # @return void
    #
    download: func(icao, force = false) {
        # TIP 1: the "request-metar" command is set "station-id" property immediately.
        # TIP 2: the fgcommand method will not download the METAR if time-to-live > 0,
        #        and if time-to-live passes, the METAR will update automatically!
        # TIP 3: METAR will not be downloaded if the Live Data weather scenario is disabled.

        if (force) {
            # The fgcommand will only trigger a METAR download when the time-to-live expires.
            # So we set this to 0 to force a refresh.
            setprop(me._pathToMyMetar ~ "/time-to-live", 0);
        }

        fgcommand("request-metar", props.Node.new({
            "path": me._pathToMyMetar,
            "station": icao,
        }));
    },

    #
    # Get wind direction in true deg.
    #
    # @param  ghost  airport
    # @return double|nil
    #
    getWindDir: func(airport) {
        if (!me.canUseMETAR(airport) or me.isVariableWind()) {
            return nil;
        }

        return getprop(me._pathToMyMetar ~ "/base-wind-dir-deg");
    },

    #
    # Get wind speed in knots.
    #
    # @return double
    #
    getWindSpeedKt: func() {
        var speed = getprop(me._pathToMyMetar ~ "/base-wind-speed-kt");
        if (speed != nil) {
            return speed;
        }

        return 0;
    },

    #
    # @return bool
    #
    isRealWeatherEnabled: func() {
        return me._realWxEnabledNode.getValue();
    },

    #
    # Get full METAR string or nil if not downloaded.
    #
    # @return string|nil
    #
    getMETAR: func() {
        return getprop(me._pathToMyMetar ~ "/data");
    },

    #
    # Return true if live METAR can be using.
    #
    # @return bool
    #
    canUseMETAR: func(airport) {
        return airport.has_metar and me.isRealWeatherEnabled();
    },

    #
    # Get QNH with 3 values: mmHg, hPa and inHg.
    #
    # @param  ghost  airport  Airport object.
    # @return string
    #
    getQNHValues: func(airport) {
        if (!me.canUseMETAR(airport)) {
            return "n/a";
        }

        var pressQNH = getprop(me._pathToMyMetar ~ "/pressure-sea-level-inhg");
        if (pressQNH == nil) {
            return "n/a";
        }

        return sprintf(
            "%d / %4d / %.2f",
            math.round(pressQNH / 29.92 * 760),  # mmHg
            math.round(pressQNH / 29.92 * 1013), # hPa
            math.round(pressQNH, 0.01),          # inHg
        );
    },

    #
    # Get QFE with 3 values: mmHg, hPa and inHg.
    #
    # @param  ghost  airport  Airport object.
    # @return string
    #
    getQFEValues: func(airport) {
        if (!me.canUseMETAR(airport)) {
            return "n/a";
        }

        var pressQNH = getprop(me._pathToMyMetar ~ "/pressure-sea-level-inhg");
        if (pressQNH == nil) {
            return "n/a";
        }

        var pressQFE = pressQNH - airport.elevation * M2FT / 1000 * 1.06;

        return sprintf(
            "%d / %4d / %.2f",
            math.round(pressQFE / 29.92 * 760),   # mmHg
            math.round(pressQFE / 29.92 * 1013),  # hPa
            math.round(pressQFE, 0.01),           # inHg
        );
    },

    #
    # Return true if wind is variable in METAR.
    #
    # @return bool
    #
    isVariableWind: func() {
        var metar = me.getMETAR();
        if (metar == nil) {
            return false;
        }

        var pos = find(" VRB", metar);
        if (pos == -1) {
            return false;
        }

        # After VRB must be followed by at least 5 characters: 2 digits + max 3 unit
        if (size(metar) < pos + 8) {
            return false;
        }

        var digits = substr(metar, pos + 4, 2);  # 2 digits
        if (!string.isdigit(digits[0]) or !string.isdigit(digits[1])) {
            return false;
        }

        # Check units
        var unit = substr(metar, pos + 6, 2);
        if (unit == "KT") {
            return true;
        }

        unit = substr(metar, pos + 6, 3);
        if (unit == "MPS" or unit == "KMH" or unit == "MPH") {
            return true;
        }

        return false;
    },
};
