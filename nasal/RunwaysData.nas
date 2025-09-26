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
# RunwaysData class.
#
var RunwaysData = {
    #
    # Constants:
    #
    CODE_IGNORE : 0, # User not used preferred runways.
    CODE_OK     : 1, # Data from rwyuse.xml was found and returned successfully.
    CODE_NO_XML : 2, # Airport has not rwyuse.xml file.
    CODE_NO_DATA: 3, # File rwyuse.xml exist but no data for given time.

    #
    # Constructor.
    #
    # @param  hash  metar  Metar object.
    # @param  hash  runwaysUse  RwyUse object.
    # @return hash
    #
    new: func(metar, runwaysUse) {
        var me = {
            parents: [RunwaysData],
            _metar: metar,
            _runwaysUse: runwaysUse,
        };

        me._rwyUseStatus = RunwaysData.CODE_IGNORE;

        return me;
    },

    #
    # Destructor.
    #
    # @return void
    #
    del: func() {
    },

    #
    # Get runways data for given airport.
    #
    # @param  ghost  airport  Airport info object.
    # @param  bool  isRwyUse  If true then preferred runways will be used (rwyuse.xml),
    #                         if false then it based on best headwind.
    # @param  string  aircraftType  Aircraft type: "com", "gen", "mil", "ul".
    # @param  bool  isTakeoff  True for takeoff, false for landing.
    # @param  int  utcHour
    # @param  int  utcMinute
    # @return vector  Array of runways data.
    #
    getRunways: func(airport, isRwyUse, aircraftType, isTakeoff, utcHour, utcMinute) {
        me._rwyUseStatus = RunwaysData.CODE_IGNORE;

        if (isRwyUse) {
            var preferredRunways = me._runwaysUse.getAllPreferredRunways(
                airport.id,
                aircraftType,
                utcHour,
                utcMinute,
            );

            if (preferredRunways == RwyUse.ERR_NO_SCHEDULE) {
                me._rwyUseStatus = RunwaysData.CODE_NO_DATA;
            } else {
                if (preferredRunways != nil) {
                    # Log.print("preferredRunways = ", string.join(", ", preferredRunways));
                    var result = me._getRunwaysByPreferred(airport, aircraftType, isTakeoff, preferredRunways);
                    if (result != nil) {
                        me._rwyUseStatus = RunwaysData.CODE_OK;
                        return result;
                    }
                }

                me._rwyUseStatus = RunwaysData.CODE_NO_XML;
            }
        }

        return me._getRunwaysByBestHeadwind(airport);
    },

    #
    # @return int
    #
    getRwyUseStatus: func() {
        return me._rwyUseStatus;
    },

    #
    # @param  ghost  airport
    # @param  string  aircraftType  Aircraft type can be "com", "gen", "mil", "ul".
    # @param  bool  isTakeoff  True for takeoff, false for landing.
    # @param  hash  preferredRunways
    # @return vector|nil  Array of runways data or nil if false.
    #
    _getRunwaysByPreferred: func(airport, aircraftType, isTakeoff, preferredRunways) {
        var wind = me._runwaysUse.getWind(airport.id, aircraftType);
        if (wind == nil) {
            return nil;
        }

        var runwaysDataActive = [];
        var runwaysDataInactive = [];

        var takeoffs = preferredRunways.takeoff;
        var landings = preferredRunways.landing;

        var takeoffRowSize = size(takeoffs);
        var landingRowSize = size(landings);

        var rowsSize = math.max(takeoffRowSize, landingRowSize);
        var colSize = math.max(size(takeoffs[0]), size(landings[0])); # In case one of the arrays has size 0

        var isPreferredColSet = false;
        for (var c = 0; c < colSize; c += 1) {
            var isColActive = true;
            var columnRunwayData = [];
            for (var r = 0; r < rowsSize; r += 1) {
                if (r < takeoffRowSize and c < size(takeoffs[r])) {
                    var rwyId = takeoffs[r][c];
                    var runwayData = me._checkWindCriteria(airport, rwyId, wind);
                    if (runwayData != nil) {
                        if (!runwayData.isWindCriteriaMet) {
                            isColActive = false;
                        }

                        if (isTakeoff) {
                            append(columnRunwayData, runwayData);
                        }
                    }
                }

                if (r < landingRowSize and c < size(landings[r])) {
                    var rwyId = landings[r][c];
                    var runwayData = me._checkWindCriteria(airport, rwyId, wind);
                    if (runwayData != nil) {
                        if (!runwayData.isWindCriteriaMet) {
                            isColActive = false;
                        }

                        if (!isTakeoff) {
                            append(columnRunwayData, runwayData);
                        }
                    }
                }
            }

            # This is our preferred column of runways (can be only 1 column)
            var isPreferred = (isColActive and !isPreferredColSet);
            if (isPreferred) {
                # Prevents subsequent runway columns from being set as preferred
                isPreferredColSet = true;
            }

            foreach (var columnRunway; columnRunwayData) {
                if (!isColActive) {
                    # Mark all runways in column as not preferred
                    columnRunway.isWindCriteriaMet = false;
                }

                # Runways from rwyuse.xml may be repeated in subsequent columns,
                # so we do not want to add a runway that we have already added earlier.
                if (!me._isRwyIdAlreadyAdded(columnRunway.rwyId, runwaysDataActive ~ runwaysDataInactive)) {
                    if (columnRunway.isWindCriteriaMet and isPreferred) {
                        columnRunway.isPreferred = true; # mark runway as preferred
                    }

                    globals.append(
                        columnRunway.isWindCriteriaMet ? runwaysDataActive : runwaysDataInactive,
                        columnRunway
                    );
                } elsif (isPreferred) {
                    # find the runway that was added earlier to mark it as preferred
                    forindex (var index; runwaysDataActive) {
                        if (runwaysDataActive[index].rwyId == columnRunway.rwyId) {
                            runwaysDataActive[index].isPreferred = true;
                            break;
                        }
                    }
                }
            }
        }

        # Active first:
        return runwaysDataActive ~ runwaysDataInactive;
    },

    #
    # @param  ghost  airport
    # @param  string  rwyId
    # @param  hash  wind
    # @return hash
    #
    _checkWindCriteria: func(airport, rwyId, wind) {
        if (!globals.contains(airport.runways, rwyId)) {
            # The airport does not have such a runway
            return nil;
        }

        var windDir   = me._metar.getWindDir(airport); # it can be nil
        var windSpeed = me._metar.getWindSpeedKt();
        var windGust  = me._metar.getWindGustSpeedKt();

        var runway = airport.runways[rwyId];
        var (normDiffDeg, hw, hwGust, xw, xwGust) = me._calculateWinds(windDir, windSpeed, windGust, runway.heading);

        var isPassedWindCriteria = true;
        if (hw != nil and xw != nil) {
            isPassedWindCriteria = (hw >= -wind.tail and xw <= wind.cross);
        }

        return me._getRunwayData("Runway", normDiffDeg, hw, hwGust, xw, xwGust, runway, isPassedWindCriteria);
    },

    #
    # @param  string  rwyId
    # @param  vector  array
    # @return bool
    #
    _isRwyIdAlreadyAdded: func(rwyId, array) {
        foreach (var item; array) {
            if (item.rwyId == rwyId) {
                return true;
            }
        }

        return false;
    },

    #
    # @param  ghost  airport
    # @return vector  Array of runways data.
    #
    _getRunwaysByBestHeadwind: func(airport) {
        var windDir   = me._metar.getWindDir(airport); # it can be nil
        var windSpeed = me._metar.getWindSpeedKt();
        var windGust  = me._metar.getWindGustSpeedKt();

        var runwaysData = [];

        foreach (var name; keys(airport.runways)) {
            var runway = airport.runways[name];

            var (normDiffDeg, hw, hwGust, xw, xwGust) = me._calculateWinds(windDir, windSpeed, windGust, runway.heading);

            append(runwaysData, me._getRunwayData("Runway", normDiffDeg, hw, hwGust, xw, xwGust, runway));
        }

        foreach (var name; keys(airport.helipads)) {
            var helipad = airport.helipads[name];

            var (normDiffDeg, hw, hwGust, xw, xwGust) = me._calculateWinds(windDir, windSpeed, windGust, helipad.heading);

            append(runwaysData, me._getRunwayData("Helipad", normDiffDeg, hw, hwGust, xw, xwGust, helipad));
        }

        return windDir == nil
            ? runwaysData
            : me._sortRunwaysByHeadwind(runwaysData);
    },

    #
    # @param  double|nil  windDir
    # @param  double  windSpeedKt
    # @param  double  windGustKt
    # @param  double  trueHdg
    # @return vector
    #
    _calculateWinds: func(windDir, windSpeedKt, windGustKt, trueHdg) {
        var normDiffDeg = nil;
        var headwind = nil;
        var headwindGust = nil;
        var crosswind = nil;
        var crosswindGust = nil;

        if (windDir != nil) {
            var diff = windDir - trueHdg;
            normDiffDeg = Utils.normalizeCourse(diff, -180, 180); # normalize to [-180, 180]
            var normDiffRad = normDiffDeg * globals.D2R;

            var cosNormDiffRad = math.cos(normDiffRad);
            var sinNormDiffRad = math.sin(normDiffRad);

            # The values ​​headwind and crosswind can be -0, so here we reduce -0 to 0 by +0.0
            headwind      = windSpeedKt * cosNormDiffRad + 0.0;
            headwindGust  = windGustKt  * cosNormDiffRad + 0.0;
            crosswind     = windSpeedKt * sinNormDiffRad + 0.0;
            crosswindGust = windGustKt  * sinNormDiffRad + 0.0;

            normDiffDeg = math.abs(normDiffDeg);
        }

        return [normDiffDeg, headwind, headwindGust, crosswind, crosswindGust];
    },

    #
    # Get hash object with runway or helipad data.
    #
    # @param  string  type  "Runway" or "Helipad".
    # @param  int|nil  normDiffDeg  Angle between wind and runway heading from 0 do 180 deg or nil if no METAR/wind.
    # @param  double|nil  hw  Headwind in knots or nil if no METAR/wind.
    # @param  double|nil  hwGust  Headwind for gust in knots or nil if no METAR/wind.
    # @param  double|nil  xw  Crosswind in knots or nil if no METAR/wind.
    # @param  double|nil  xwGust  Crosswind for gust in knots or nil if no METAR/wind.
    # @param  ghost  runway  Runway or Helipad data from FlightGear.
    # @param  bool|nil  isWindCriteriaMet  If nil then rwyuse.xml is not using.
    #                                      If false then the runway is not preferred because
    #                                      it does not meet the guidelines for maximum tail and cross winds.
    # @return hash
    #
    _getRunwayData: func(type, normDiffDeg, hw, hwGust, xw, xwGust, runway, isWindCriteriaMet = nil) {
        var isTypeRunway = type == "Runway";

        return {
            type         : type,
            normDiffDeg  : normDiffDeg,
            headwind     : hw,
            headwindGust : hwGust,
            crosswind    : xw,
            crosswindGust: xwGust,
            rwyId        : runway.id,
            heading      : runway.heading,
            length       : runway.length,
            width        : runway.width,
            surface      : runway.surface,
            reciprocal   : isTypeRunway ? runway.reciprocal : nil,
            ils          : isTypeRunway ? runway.ils : nil,
            lat          : runway.lat,
            lon          : runway.lon,
            isPreferred  : nil, # = true if rwyuse.xml is using and this is preferred runway
            isWindCriteriaMet: isWindCriteriaMet,
        };
    },

    #
    # Sort runways data by smaller normDiffDeg first, i.e. larger headwind first.
    #
    # @param  vector  runwaysData  Array of runways data.
    # @return vector  Sorted array of runways data.
    #
    _sortRunwaysByHeadwind: func(runwaysData) {
        return globals.sort(runwaysData, func(a, b) {
              if (a.normDiffDeg > b.normDiffDeg) return  1;
           elsif (a.normDiffDeg < b.normDiffDeg) return -1;

           return 0;
        });
    },
};
