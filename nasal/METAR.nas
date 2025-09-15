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
    QNH_TO_QFE_FACTOR  : 1.06,

    #
    # Constructor
    #
    # @param  string  tabId  Tab ID.
    # @param  hash  objCallbacks
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

        # If we download a METAR from an airport other than the current one,
        # because the current one does not have a META, we set this variable to true.
        # Therefore, if this variable is set, it means we have a METAR,
        # even if the current airport doesn't have a METAR.
        me._isMetarFromNearestAirport = false;

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
    # @param  string  icao  ICAO code of the airport whose METAR we want to download.
    # @param  bool  force
    # @param  bool  isNearest  True if it's ICAO from nearest airport.
    # @return void
    #
    download: func(icao, force = false, isNearest = false) {
        # TIP 1: the "request-metar" command is set "station-id" property immediately.
        # TIP 2: the fgcommand method will not download the METAR if time-to-live > 0,
        #        and if time-to-live passes, the METAR will update automatically!
        #        After download METAR the time-to-live is set to 900 seconds (15 min.)
        # TIP 3: METAR will not be downloaded if the Live Data weather scenario is disabled.

        me._isMetarFromNearestAirport = isNearest;

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
    # Turns off the indication that we have a METAR from a nearby airport.
    #
    # @return void
    #
    disableMetarFromNearestAirport: func() {
        me._isMetarFromNearestAirport = false;
    },

    #
    # Return true if downloaded METAR is from nearest airport.
    #
    # @return bool
    #
    isMetarFromNearestAirport: func() {
        return me._isMetarFromNearestAirport;
    },

    #
    # Get wind direction in true deg.
    #
    # @param  ghost  airport  Airport object.
    # @return double|nil
    #
    getWindDir: func(airport) {
        if (!me.canUseMETAR(airport) or me._isWindVariable(airport)) {
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
    # Get wind speed in knots.
    #
    # @return double
    #
    getWindGustSpeedKt: func() {
        var speed = getprop(me._pathToMyMetar ~ "/gust-wind-speed-kt");
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
    getMETAR: func(airport) {
        if (airport.has_metar or me._isMetarFromNearestAirport) {
            return getprop(me._pathToMyMetar ~ "/data");
        }

        return nil;
    },

    #
    # Return true if we can use the downloaded METAR.
    #
    # @return bool
    #
    canUseMETAR: func(airport) {
        return me.isRealWeatherEnabled() and (airport.has_metar or me._isMetarFromNearestAirport);
    },

    #
    # Get QNH with 3 values: mmHg, hPa and inHg.
    #
    # @param  ghost  airport  Airport object.
    # @return vector
    #
    getQnhValues: func(airport) {
        if (!me.canUseMETAR(airport)) {
            return "n/a";
        }

        var pressQNH = getprop(me._pathToMyMetar ~ "/pressure-sea-level-inhg");
        if (pressQNH == nil) {
            return "n/a";
        }

        return [
            math.round(me._inHgToMmHg(pressQNH)), # mmHg
            math.round(me._inHgToHPa(pressQNH)),  # hPa
            math.round(pressQNH, 0.01),           # inHg
        ];
    },

    #
    # Get QFE with 3 values: mmHg, hPa and inHg.
    #
    # @param  ghost  airport  Airport object.
    # @return vector
    #
    getQfeValues: func(airport) {
        if (!me.canUseMETAR(airport)) {
            return "n/a";
        }

        var pressQNH = getprop(me._pathToMyMetar ~ "/pressure-sea-level-inhg");
        if (pressQNH == nil) {
            return "n/a";
        }

        var pressQFE = pressQNH - airport.elevation * M2FT / 1000 * METAR.QNH_TO_QFE_FACTOR;

        return [
            math.round(me._inHgToMmHg(pressQFE)), # mmHg
            math.round(me._inHgToHPa(pressQFE)),  # hPa
            math.round(pressQFE, 0.01),           # inHg
        ];
    },

    #
    # Convert given inHg pressure to mmHg.
    #
    # @param  double  pressInHg
    # @return double
    #
    _inHgToMmHg: func(pressInHg) {
        return (pressInHg / 29.92) * 760;
    },

    #
    # Convert given inHg pressure to hPa.
    #
    # @param  double  pressInHg
    # @return double
    #
    _inHgToHPa: func(pressInHg) {
        return (pressInHg / 29.92) * 1013;
    },

    #
    # Return true if wind is variable in METAR.
    #
    # @return bool
    #
    _isWindVariable: func(airport) {
        var metar = me.getMETAR(airport);
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

        # Check gust
        var gust = substr(metar, pos + 6, 1);
        if (gust == "G") {
            return true;
        }

        # Check units (if no gust)
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

    #
    # Get ICAO code of downloaded METAR.
    #
    # @return string|nil
    #
    getICAO: func() {
        return getprop(me._pathToMyMetar ~ "/station-id");
    },

    #
    # Return distance in NM from given airport to METAR station.
    #
    # @param  ghost  airport  The airport from which we measure the distance.
    # @return double|nil  Distance in NM or nil if failed.
    #
    getDistanceToStation: func(airport) {
        var station = globals.airportinfo(me.getICAO());
        if (station == nil) {
            return nil;
        }

        var coordStation = geo.Coord.new().set_latlon(station.lat, station.lon);
        var coordAirport = geo.Coord.new().set_latlon(airport.lat, airport.lon);
        return coordAirport.distance_to(coordStation) * globals.M2NM;
    },
};
