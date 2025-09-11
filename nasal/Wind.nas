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
# Wind class
#
var Wind = {
    #
    # Static constants
    #
    HEADWIND_THRESHOLD : 45, # Headwind from 0 to 45
    CROSSWIND_THRESHOLD: 90, # Crosswind from 46 to 90, tailwind from 91

    #
    # Constructor
    #
    # @param  string  tabId  Tab ID.
    # @return me
    #
    new: func(tabId) {
        var me = { parents: [Wind] };

        me._pathToMyMetar = g_Addon.node.getPath() ~ "/" ~ tabId ~ "/metar";

        # me._realWxEnabledNode = props.globals.getNode("/environment/realwx/enabled");

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
    },

    #
    # Run FGCommand to download METAR for given ICAO code.
    #
    # @param  string  icao  ICAO code of airport.
    # @return void
    #
    downloadMetar: func(icao) {
        # The "request-metar" command is set "station-id" property immediately.

        fgcommand("request-metar", props.Node.new({
            "path": me._pathToMyMetar,
            "station": icao,
        }));
    },

    #
    # Return true if METAR data is set in our property.
    #
    # @return bool
    #
    isMetarSet: func() {
        if (me.getMETAR() == nil) {
            return false;
        }

        var lat = getprop(me._pathToMyMetar ~ "/station-latitude-deg");
        var lon = getprop(me._pathToMyMetar ~ "/station-longitude-deg");

        var airport = airportinfo(lat, lon);
        if (airport == nil) {
            return false;
        }

        return airport.id == getprop(me._pathToMyMetar ~ "/station-id");
    },

    #
    # Get wind direction in true deg.
    #
    # @return double
    #
    getDirection: func() {
        var dir = getprop(me._pathToMyMetar ~ "/base-wind-dir-deg");
        if (dir != nil) {
            return dir;
        }

        # if (me._isRealWeatherEnabled() and me._metarWindDirNode != nil) {
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
    getSpeedKt: func() {
        var speed = getprop(me._pathToMyMetar ~ "/base-wind-speed-kt");
        if (speed != nil) {
            return speed;
        }

        # if (me._isRealWeatherEnabled() and me._metarWindSpeedNode != nil) {
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
    # _isRealWeatherEnabled: func() {
    #     return me._realWxEnabledNode.getValue();
    # },

    #
    # Get full METAR string or nil if not downloaded.
    #
    # @return string|nil
    #
    getMETAR: func() {
        return getprop(me._pathToMyMetar ~ "/data");
    },

    #
    # Get QNH with 3 values: mmHg, hPa and inHg.
    #
    # @return string
    #
    getQNHValues: func() {
        var pressQNH = getprop(me._pathToMyMetar ~ "/pressure-sea-level-inhg");

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
        var pressQNH = getprop(me._pathToMyMetar ~ "/pressure-sea-level-inhg");
        var pressQFE = pressQNH - airport.elevation * M2FT / 1000 * 1.06;

        return sprintf(
            "%d / %4d / %.2f",
            math.round(pressQFE / 29.92 * 760),   # mmHg
            math.round(pressQFE / 29.92 * 1013),  # hPa
            math.round(pressQFE, 0.01),           # inHg
        );
    },
};
