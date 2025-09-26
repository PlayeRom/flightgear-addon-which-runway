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
# A class that loads the rwyuse.xml file for a given airport.
#
var LoadRwyUseXml = {
    #
    # Constructor
    #
    # @return hash
    #
    new: func() {
        return {
            parents: [
                LoadRwyUseXml,
            ],
        };
    },

    #
    # Destructor
    #
    # @return void
    #
    del: func() {
    },

    #
    # @param  string  icao
    # @return hash|nill
    #
    load: func(icao) {
        var path = me._findPathToAirportFile(icao, "rwyuse");
        if (path == nil) {
            Log.print(icao, " path to rwyuse not found");
            return nil;
        }

        # This function doesn't work because "rwyuse" is not PropertyList
        # var mainNode = io.read_airport_properties(icao, "rwyuse");
        # So we use io.readxml() to read raw XML.

        var mainNode = io.readxml(path);
        if (mainNode == nil) {
            Log.print(icao, " loading rwyuse path failed from ", path);
            return nil;
        }

        var data = {
            aircraft: {},
            schedules: {},
        };

        var rwyUseNode = mainNode.getChild("rwyuse");

        var loopTypes = [
            RwyUse.COMMERCIAL,
            RwyUse.GENERAL,
            RwyUse.MILITARY,
            RwyUse.ULTRALIGHT,
        ];

        foreach (var type; loopTypes) {
            var acData = me._getAircraft(icao, rwyUseNode, type);
            if (acData != nil) {
                data.aircraft[type] = acData;
            }
        }

        foreach (var schedule; rwyUseNode.getChildren("schedule")) {
            var scheduleName = schedule.getValue("___name"); # inbound, outbound, offpeak, night, general

            data.schedules[scheduleName] = {
                takeoff: me._getRunways(schedule, "takeoff"), # vector of vectors with runways IDs.
                landing: me._getRunways(schedule, "landing"),
            };
        }

        # Logs only
        if (g_isDevMode) {
            foreach (var schedule; keys(data.schedules)) {
                foreach (var takeoffs; data.schedules[schedule].takeoff) {
                    Log.print(icao, ", schedule = ", schedule, ", takeoff = ", string.join(", ", takeoffs));
                }

                foreach (var landings; data.schedules[schedule].landing) {
                    Log.print(icao, ", schedule = ", schedule, ", landing = ", string.join(", ", landings));
                }
            }
        }

        return data;
    },

    #
    # Look for the file in all included sceneries.
    #
    # @param  string  icao
    # @param  string  file
    # @return string|nil  Get full path to airport XML file, or nil if not found
    #
    _findPathToAirportFile: func(icao, file) {
        var pathToRwyUse = me._getPathToAirportFile(icao, file);
        if (pathToRwyUse == nil) {
            return nil;
        }

        foreach (var scenery; props.globals.getNode("/sim").getChildren("fg-scenery")) {
            var sceneryPath = scenery.getValue();
            if (sceneryPath == nil) {
                continue;
            }

            var fullPath = sceneryPath ~ "/" ~ pathToRwyUse;

            if (!io.exists(fullPath)) {
                continue;
            }

            return fullPath;
        }

        return nil;
    },

    #
    # Get path to airport XML file.
    #
    # @param  string  icao
    # @param  string  file
    # @return string|nil
    #
    _getPathToAirportFile: func(icao, file) {
        if (size(icao) != 4) {
            return nil;
        }

        return sprintf("Airports/%s/%s/%s/%s.%s.xml", chr(icao[0]), chr(icao[1]), chr(icao[2]), icao, file);
    },

    #
    # @param  string  icao
    # @param  ghost  rwyUseNode
    # @param  string  type  Type can be "com", "gen", "mil", "ul".
    # @return hash|nil
    #
    _getAircraft: func(icao, node, type) {
        var typeNode = node.getChild(type);
        if (typeNode == nil) {
            return nil;
        }

        var windNode = typeNode.getChild("wind");

        var data = {
            wind: {
                tail : windNode.getValue("___tail"),
                cross: windNode.getValue("___cross"),
            },
            time: [],
        };

        if (g_isDevMode) {
            Log.print(type, " wind tail = ", data.wind.tail, ", wind cross = ", data.wind.cross);
        }

        foreach (var time; typeNode.getChildren("time")) {
            if (time == nil) {
                continue;
            }

            var startTime = globals.split(":", time.getValue("___start"));
            var endTime   = globals.split(":", time.getValue("___end"));

            var item = {
                start: {
                    hour  : num(startTime[0]),
                    minute: num(startTime[1]),
                },
                end: {
                    hour  : num(endTime[0]),
                    minute: num(endTime[1]),
                },
                schedule   : time.getValue("___schedule"),
            };

            if (g_isDevMode) {
                Log.print(sprintf(
                    "%s time start = %02d:%02d, end = %02d:%02d, schedule = %s",
                    type, item.start.hour, item.start.minute, item.end.hour, item.end.minute, item.schedule,
                ));
            }

            globals.append(data.time, item);
        }

        return data;
    },

    #
    # @param  ghost  node
    # @param  string  childName  It can be "takeoff" or "landing".
    # @return vector
    #
    _getRunways: func(node, childName) {
        var array = [];

        var minSize = nil;
        var isTrimNeeded = false;

        foreach (var runways; node.getChildren(childName)) {
            if (runways != nil) {
                var ids = me._readRunwayIds(runways.getValue());

                globals.append(array, ids);

                var size = globals.size(ids);
                if (minSize == nil or minSize > size) {
                    if (minSize != nil) {
                        isTrimNeeded = true;
                    }

                    minSize = size;
                }
            }
        }

        # We make sure that each array has the same number of elements
        if (isTrimNeeded) {
            forindex (var index; array) {
                globals.setsize(array[index], trimSize);
            }
        }

        return array;
    },

    #
    # @param  string  runwaysString  For example: "06,  18R,18R, 36R, 27, 18R,18R, 06".
    # @return vector  Vector of single runway IDs, e.g. ["06", "18R", "18R", "36R", "27", "18R", "18R", "06"].
    #
    _readRunwayIds: func(runwaysString) {
        var array = globals.split(",", runwaysString);
        forindex (var index; array) {
            array[index] = string.trim(array[index]);
        }

        return array;
    },
};
