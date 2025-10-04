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
# A class that handles data from the rwyuse.xml file.
# See: https://wiki.flightgear.org/AI_Traffic#Runway_Usage_Configuration
#
var RwyUse = {
    #
    # Constants:
    #
    COMMERCIAL: "com",
    GENERAL   : "gen",
    MILITARY  : "mil",
    ULTRALIGHT: "ul",

    TAKEOFF   : 1,
    LANDING   : 2,

    ERR_NO_SCHEDULE: "err code no scheduler", # The airport does not operate at the specified time for the given aircraft type

    #
    # Constructor
    #
    # @return hash
    #
    new: func() {
        var me = {
            parents: [
                RwyUse,
            ],
        };

        #
        # Data structure:
        #
        # me._data = {
        #     EHAM: {
        #         aircraft: {
        #             com: {
        #                 wind: { <------ max allowed wind
        #                     tail: 7,
        #                     cross: 20,
        #                 },
        #                 time: [ <------ UTC time
        #                     {
        #                          start: {
        #                              hour: 0,
        #                              minute: 0,
        #                          },
        #                          end: {
        #                              hour: 5,
        #                              minute: 0,
        #                          },
        #                          schedule: "night",
        #                     },
        #                     {
        #                          start: {
        #                              hour: 5,
        #                              minute: 0,
        #                          },
        #                          end: {
        #                              hour: 6,
        #                              minute: 20,
        #                          },
        #                          schedule: "offpeak",
        #                     },
        #                     { etc... },
        #                 ],
        #             },
        #             gen: {
        #                 wind: {
        #                     tail: 7,
        #                     cross: 20,
        #                 },
        #                 time: [
        #                     {
        #                          start: {
        #                              hour: 7,
        #                              minute: 0,
        #                          },
        #                          end: {
        #                              hour: 19,
        #                              minute: 0,
        #                          },
        #                          schedule: "general",
        #                     },
        #                     { etc... },
        #                 ],
        #             },
        #             mil: { ... },
        #             ul: { ... },
        #         },
        #         schedules: {
        #             inbound: {
        #                 takeoff: [
        #                     [36L,  24, 18L, 36L,  24,  24, 18L, 09],
        #                 ],
        #                 landing: [
        #                     [ 06, 18R, 18R, 36R,  27, 18R, 18R, 06],
        #                     [36R, 18C, 18C, 36C, 18R,  22,  22, 09],
        #                 ],
        #             },
        #             general: {
        #                 takeoff: [
        #                     [04, 22],
        #                 ],
        #                 landing: [
        #                     [04, 22],
        #                 ],
        #             },
        #             outbound: { ... },
        #             offpeak: { ... },
        #             night: { ... },
        #         },
        #     },
        #     KSFO: {
        #         etc...
        #     },
        # };
        #
        #
        me._data = {};

        me._loadRwyUseXml = LoadRwyUseXml.new();

        return me;
    },

    #
    # Destructor
    #
    # @return void
    #
    del: func() {
        me._loadRwyUseXml.del();
    },

    #
    # @param  string  icao  Airport ICAO code.
    # @param  string  acType  Aircraft type: "com", "gen", "mil", "ul".
    # @param  int  utcHour
    # @param  int  utcMinute
    # @return hash
    #
    getAllPreferredRunways: func(icao, acType, utcHour, utcMinute) {
        # Find schedule by time
        var schedule = me.getScheduleByTime(icao, acType, utcHour, utcMinute);
        if (schedule == nil) {
            return nil; # error, no icao or traffic
        } else if (schedule == RwyUse.ERR_NO_SCHEDULE) {
            return RwyUse.ERR_NO_SCHEDULE; # the indicated traffic does not operate at the specified time
        }

        if (!globals.contains(me._data[icao].schedules, schedule)) {
            return nil; # error, no such schedule in data structure
        }

        return me._data[icao].schedules[schedule];
    },

    #
    # @param  string  icao  Airport ICAO code.
    # @param  string  acType  Aircraft type: "com", "gen", "mil", "ul".
    # @param  hash|nil  Hash with wind or nil if not found.
    #
    getWind: func(icao, acType) {
        if (!me._isIcaoLoaded(icao)) {
            return nil;
        }

        acType = me._checkAircraftType(icao, acType);
        if (acType == nil) {
            return nil; # no data for aircraft type
        }

        return me._data[icao].aircraft[acType].wind;
    },

    #
    # @param  string  icao  Airport ICAO code.
    # @param  string  acType  Aircraft type: "com", "gen", "mil", "ul".
    # @return string
    #
    getUsedTrafficFullName: func(icao, acType) {
        if (!me._isIcaoLoaded(icao)) {
            return nil;
        }

        acType = me._checkAircraftType(icao, acType);

           if (acType == RwyUse.COMMERCIAL) return "commercial";
        elsif (acType == RwyUse.GENERAL)    return "general";
        elsif (acType == RwyUse.MILITARY)   return "military";
        elsif (acType == RwyUse.ULTRALIGHT) return "ultralight";

        return "n/a";
    },

    #
    # Get daily operation time for given traffic/aircraft type.
    #
    # @param  string  icao  Airport ICAO code.
    # @param  string  acType  Aircraft type: "com", "gen", "mil", "ul".
    # @return string|nil  Time range or nil if not found.
    #
    getDailyOperatingHours: func(icao, acType) {
        if (!me._isIcaoLoaded(icao)) {
            return nil;
        }

        acType = me._checkAircraftType(icao, acType);
        if (acType == nil) {
            return nil; # no data for aircraft type
        }

        var times = me._data[icao].aircraft[acType].time;
        if (size(times) == 0) {
            return nil; # no time data
        }

        return sprintf("%02d:%02d – %02d:%02d",
            times[0].start.hour,
            times[0].start.minute,
            times[-1].end.hour,
            times[-1].end.minute,
        );
    },

    #
    # Check is ICAO.rwyuse.xml is loaded, if not load it.
    #
    # @param  string  icao  Airport ICAO code.
    # @return bool  ICAO is loaded.
    #
    _isIcaoLoaded: func(icao) {
        if (!globals.contains(me._data, icao)) {
            var data = me._loadRwyUseXml.load(icao);
            if (data == nil) {
                return false;
            }

            me._data[icao] = data;
        }

        return true;
    },

    #
    # @param  string  icao  Airport ICAO code.
    # @param  string  acType  Aircraft type: "com", "gen", "mil", "ul".
    # @return string|nil  Aircraft type found, or nil if none found.
    #
    _checkAircraftType: func(icao, acType) {
        if (globals.contains(me._data[icao].aircraft, acType)) {
            return acType;
        }

        # There is no aircraft type we want, so we will change it to something more likely to be there.

        if (acType == RwyUse.MILITARY)   return me._checkAircraftType(icao, RwyUse.COMMERCIAL);
        if (acType == RwyUse.ULTRALIGHT) return me._checkAircraftType(icao, RwyUse.GENERAL);
        if (acType == RwyUse.GENERAL)    return me._checkAircraftType(icao, RwyUse.COMMERCIAL);

        return nil; # no data for aircraft type
    },

    #
    # @param  string  icao  Airport ICAO code.
    # @param  string  acType  Aircraft type: "com", "gen", "mil", "ul".
    # @param  int  utcHour
    # @param  int  utcMinute
    # @param  string|nil  Schedule name or nil if not found.
    #
    getScheduleByTime: func(icao, acType, utcHour, utcMinute) {
        if (!me._isIcaoLoaded(icao)) {
            return nil;
        }

        acType = me._checkAircraftType(icao, acType);
        if (acType == nil) {
            return nil; # no data for aircraft type
        }

        var times = me._data[icao].aircraft[acType].time;

        foreach (var time; times) {
            if (me._isTimeInRange(utcHour, utcMinute, time.start, time.end)) {
                return time.schedule;
            }
        }

        return RwyUse.ERR_NO_SCHEDULE;
    },

    #
    # @param  int  hour  Current UTC time hour
    # @param  int  minute  Current UTC time minute
    # @param  hash  start  Schedule start time.
    # @param  hash  end  Schedule end time.
    # @return bool  True if current UTC time is in start-end range.
    #
    _isTimeInRange: func(hour, minute, start, end) {
        var currentInMin = hour * 60 + minute;
        var startInMin   = start.hour * 60 + start.minute;
        var endInMin     = end.hour * 60 + end.minute;

        if (startInMin <= endInMin) {
            # normal range in day, e.g. 05:00–06:20
            return currentInMin >= startInMin and currentInMin <= endInMin;
        }

        # range passing through the midnight, e.g. 22:00–03:00
        return currentInMin >= startInMin or currentInMin <= endInMin;
    },
};
