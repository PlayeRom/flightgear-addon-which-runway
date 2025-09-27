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
var Metar = {
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
    # @param  hash  updateMetarCallback  Callback object invoked for update Metar.
    # @param  hash  updateRealWxCallback  Callback object invoked for update real weather.
    # @return hash
    #
    new: func(tabId, updateMetarCallback, updateRealWxCallback) {
        var me = {
            parents: [Metar],
            _tabId: tabId,
            _updateMetarCallback: updateMetarCallback,
            _updateRealWxCallback: updateRealWxCallback,
        };

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
                Log.print("METAR for ", me._tabId, " has been updated");
                me._updateMetarCallback.invoke();
            },
        );

        # Redraw canvas if Live Data is enabled/disabled.
        me._listeners.add(
            node: "/environment/realwx/enabled",
            code: func(node) {
                me._updateRealWxCallback.invoke();
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
    # @param  ghost|nil  airport  Airport object.
    # @return double|nil
    #
    getWindDir: func(airport) {
        if (!me.canUseMetar(airport) or me._isWindVariable(airport)) {
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
    # @param  ghost  airport  Airport object.
    # @return string|nil
    #
    getMetar: func(airport) {
        if (airport != nil and (airport.has_metar or me._isMetarFromNearestAirport)) {
            return getprop(me._pathToMyMetar ~ "/data");
        }

        return nil;
    },

    #
    # Return true if we can use the downloaded METAR.
    #
    # @param  ghost|nill  airport  Airport object.
    # @return bool
    #
    canUseMetar: func(airport) {
        if (airport == nil) {
            return false;
        }

        return me.isRealWeatherEnabled() and (airport.has_metar or me._isMetarFromNearestAirport);
    },

    #
    # Get QNH with 3 values: inHg, hPa and mmHg.
    #
    # @param  ghost|nil  airport  Airport object.
    # @return hash|nil
    #
    getQnhValues: func(airport) {
        if (!me.canUseMetar(airport)) {
            return nil;
        }

        var pressQnh = getprop(me._pathToMyMetar ~ "/pressure-inhg");
        if (pressQnh == nil) {
            return nil;
        }

        return {
            inHg: math.round(pressQnh, 0.01),
            hPa : math.round(me._inHgToHPa(pressQnh)),
            mmHg: math.round(me._inHgToMmHg(pressQnh)),
        };
    },

    #
    # Get QFE with 3 values: inHg, hPa and mmHg.
    #
    # @param  ghost|nil  airport  Airport object.
    # @return hash|nil
    #
    getQfeValues: func(airport) {
        if (!me.canUseMetar(airport)) {
            return nil;
        }

        var pressQnh = getprop(me._pathToMyMetar ~ "/pressure-inhg");
        if (pressQnh == nil) {
            return nil;
        }

        var pressQfe = pressQnh - airport.elevation * M2FT / 1000 * Metar.QNH_TO_QFE_FACTOR;

        return {
            inHg: math.round(pressQfe, 0.01),
            hPa : math.round(me._inHgToHPa(pressQfe)),
            mmHg: math.round(me._inHgToMmHg(pressQfe)),
        };
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
        var metar = me.getMetar(airport);
        if (metar == nil) {
            return false;
        }

        var pos = globals.find(" VRB", metar);
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
    getIcao: func() {
        return getprop(me._pathToMyMetar ~ "/station-id");
    },

    #
    # Return distance in NM from given airport to METAR station.
    #
    # @param  ghost  airport  The airport from which we measure the distance.
    # @return double|nil  Distance in meters or nil if failed.
    #
    getDistanceToStation: func(airport) {
        if (!me._isMetarFromNearestAirport) {
            return nil;
        }

        var icao = me.getIcao();
        if (icao == nil) {
            return nil;
        }

        var station = globals.airportinfo(icao);
        if (station == nil) {
            return nil;
        }

        var coordStation = geo.Coord.new().set_latlon(station.lat, station.lon);
        var coordAirport = geo.Coord.new().set_latlon(airport.lat, airport.lon);
        return coordAirport.distance_to(coordStation);
    },
};
