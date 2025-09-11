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
    # @param  func  objUpdatedCallback
    # @param  func  funcUpdatedCallback
    # @return me
    #
    new: func(tabId, objUpdatedCallback, funcUpdatedCallback) {
        var me = { parents: [METAR] };

        me._pathToMyMetar = g_Addon.node.getPath() ~ "/" ~ tabId ~ "/metar";

        me._listener = setlistener(me._pathToMyMetar ~ "/data", func() {
            logprint(LOG_ALERT, "Which Runway ----- METAR for ", tabId, " has been updated");
            call(funcUpdatedCallback, [], objUpdatedCallback);
        });

        me._realWxEnabledNode = props.globals.getNode("/environment/realwx/enabled");

        # me._metarWindDirNode   = props.globals.getNode("/environment/metar/base-wind-dir-deg");
        # me._metarWindSpeedNode = props.globals.getNode("/environment/metar/base-wind-speed-kt");

        # me._simWindDirNode   = props.globals.getNode("/environment/wind-from-heading-deg");
        # me._simWindSpeedNode = props.globals.getNode("/environment/wind-speed-kt");

        return me;
    },

    #
    # Destructor
    #
    # @return void
    #
    del: func() {
        removelistener(me._listener);
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
    # @return double
    #
    getWindDir: func() {
        var dir = getprop(me._pathToMyMetar ~ "/base-wind-dir-deg");
        if (dir != nil) {
            return dir;
        }

        # if (me.isRealWeatherEnabled() and me._metarWindDirNode != nil) {
        #     return me._metarWindDirNode.getValue();
        # }

        # if (me._simWindDirNode != nil) {
        #     return me._simWindDirNode.getValue();
        # }

        return 0;
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

        # if (me.isRealWeatherEnabled() and me._metarWindSpeedNode != nil) {
        #     return me._metarWindSpeedNode.getValue();
        # }

        # if (me._simWindSpeedNode != nil) {
        #     return me._simWindSpeedNode.getValue();
        # }

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
};
