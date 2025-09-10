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
    # @return me
    #
    new: func() {
        var me = { parents: [Wind] };

        me._pathToMyMetar = g_Addon.node.getPath() ~ "/metar";

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
        if (getprop(me._pathToMyMetar ~ "/data") == nil) {
            return false;
        }

        var lat = getprop(me._pathToMyMetar ~ "/station-latitude-deg");
        var lon = getprop(me._pathToMyMetar ~ "/station-longitude-deg");

        var result = airportinfo(lat, lon).id == getprop(me._pathToMyMetar ~ "/station-id");

        return result;
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
    # Get color of headwind (can be call as static method).
    #
    # @return vector
    #
    getHeadwindColor: func() {
        return [0.0, 0.5, 0.0];
    },

    #
    # Get color of crosswind (can be call as static method).
    #
    # @return vector
    #
    getCrosswindColor: func() {
        return [0.9, 0.5, 0.0];
    },
};
