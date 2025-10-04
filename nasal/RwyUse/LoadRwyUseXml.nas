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
    # Constructor.
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
    # Destructor.
    #
    # @return void
    #
    del: func() {
    },

    #
    # @param  string  icao
    # @return hash|nil
    #
    load: func(icao) {
        var path = me._findPathToAirportFile(icao, "rwyuse");
        if (path == nil) {
            Log.print(icao, ", path to rwyuse.xml not found");
            return nil;
        }

        # This function doesn't work because "rwyuse" is not PropertyList
        # var mainNode = io.read_airport_properties(icao, "rwyuse");
        # So we use io.readxml() to read raw XML.

        var node = io.readxml(path);
        if (node == nil) {
            Log.print(icao, ", loading rwyuse.xml file failed from ", path);
            return nil;
        }

        return me._parseXml(icao, node);
    },

    #
    # Parse the XML data by given node.
    #
    # @param  string  icao  ICAO code of the airport.
    # @param  ghost  node  The props.Node of the whole XML file.
    # @return hash  The data structure is described in the constructor of RwyUse class.
    #
    _parseXml: func(icao, node) {
        var data = {
            aircraft: {},
            schedules: {},
        };

        var rwyUseNode = node.getChild("rwyuse");

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
            if (schedule == nil) {
                continue;
            }

            var scheduleName = schedule.getValue("___name"); # inbound, outbound, offpeak, night, general
            if (scheduleName == nil) {
                continue;
            }

            if (globals.contains(data.schedules, scheduleName)) {
                Log.alert(icao, ".rwyuse.xml has duplicate schedule name \"", scheduleName, "\"");
                continue;
            }

            data.schedules[scheduleName] = me._getRunways(icao, schedule);
        }

        # Logs only
        if (g_isDevMode) {
            foreach (var schedule; keys(data.schedules)) {
                foreach (var takeoffs; data.schedules[schedule].takeoff) {
                    Log.print(icao, ".rwyuse.xml, schedule = ", schedule, ", takeoff = ", string.join(", ", takeoffs));
                }

                foreach (var landings; data.schedules[schedule].landing) {
                    Log.print(icao, ".rwyuse.xml, schedule = ", schedule, ", landing = ", string.join(", ", landings));
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
    # @return string|nil  Get full path to airport XML file, or nil if not found.
    #
    _findPathToAirportFile: func(icao, file) {
        var pathToRwyUse = me._getPathToAirportFile(icao, file);
        if (pathToRwyUse == nil) {
            return nil;
        }

        foreach (var scenery; props.globals.getNode("/sim").getChildren("fg-scenery")) {
            if (scenery == nil) {
                continue;
            }

            var sceneryPath = scenery.getValue();
            if (sceneryPath == nil) {
                continue;
            }

            var fullPath = sceneryPath ~ "/" ~ pathToRwyUse;

            if (io.exists(fullPath)) {
                return fullPath;
            }
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
    # @param  string  icao  ICAO code of the airport.
    # @param  ghost  node  The props.Node of the <rwyuse> XML node.
    # @param  string  type  Aircraft type, it can be "com", "gen", "mil", "ul".
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
            Log.print(icao, ".rwyuse.xml, traffic = ", type, ", wind tail = ", data.wind.tail, ", wind cross = ", data.wind.cross);
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
                schedule: time.getValue("___schedule"),
            };

            if (g_isDevMode) {
                Log.print(sprintf(
                    "%s.rwyuse.xml, traffic = %s, time start = %02d:%02d, end = %02d:%02d, schedule = %s",
                    icao, type, item.start.hour, item.start.minute, item.end.hour, item.end.minute, item.schedule,
                ));
            }

            globals.append(data.time, item);
        }

        return data;
    },

    #
    # @param  string  icao  ICAO code of the airport.
    # @param  ghost  node  The props.Node of the <schedule> XML node.
    # @return hahs  The takeoff and landing hash with vector of vectors with runway IDs.
    #
    _getRunways: func(icao, node) {
        var takeoffs = [];
        var landings = [];

        var minSize = nil;
        var maxSize = nil;

        foreach (var operation; ["takeoff", "landing"]) {
            foreach (var runways; node.getChildren(operation)) {
                if (runways == nil) {
                    continue;
                }

                var ids = me._readRunwayIds(runways.getValue());

                globals.append(operation == "takeoff" ? takeoffs : landings, ids);

                var size = globals.size(ids);

                if (minSize == nil or minSize > size) minSize = size;
                if (maxSize == nil or maxSize < size) maxSize = size;
            }
        }

        # We make sure that each array has the same number of elements
        if (minSize != nil and minSize != maxSize) {
            Log.alert(icao, ".rwyuse.xml - the schedule \"", node.getValue("___name"),
                "\" has a different number of runways in columns. ",
                "Trimming runways to size ", minSize, ".",
            );

            forindex (var index; takeoffs) {
                globals.setsize(takeoffs[index], minSize);
            }

            forindex (var index; landings) {
                globals.setsize(landings[index], minSize);
            }
        }

        return {
            takeoff: takeoffs,
            landing: landings,
        };
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
