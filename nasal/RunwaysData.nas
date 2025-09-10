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
# RunwaysData class
#
var RunwaysData = {
    #
    # Constructor
    #
    # @param  ghost  wind  Wind object.
    # @return me
    #
    new: func(wind) {
        var me = { parents: [RunwaysData] };

        me._wind = wind;

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
    # Get runways data for given airport.
    #
    # @param  ghost  airport  Airport info object.
    # @return vector  Array of runways data.
    #
    getRunways: func(airport) {
        # TODO: it seems that the runway headings are "true", so there is no need to use magnetic variation?
        # var magVariation = magvar(airport);
        # var windDir = me._wind.getDirection() - magVariation;
        var windDir   = me._wind.getDirection();
        var windSpeed = me._wind.getSpeedKt();

        var runwaysData = [];

        foreach (var runwayName; keys(airport.runways)) {
            var runway = airport.runways[runwayName];

            var rwyHdg = runway.heading;

            var diff = windDir - rwyHdg;
            var normDiffDeg = math.round(math.mod((diff + 180), 360) - 180); # normalize to [-180, 180]
            var normDiffRad = normDiffDeg * globals.D2R;

            var headwind  = windSpeed * math.cos(normDiffRad);
            var crosswind = windSpeed * math.sin(normDiffRad);

            # The values ​​headwind and crosswind can be -0, so here we reduce -0 to 0
            if (headwind == 0) {
                headwind = 0;
            }

            if (crosswind == 0) {
                crosswind = 0;
            }

            append(runwaysData, {
                normDiffDeg: math.abs(normDiffDeg),
                headwind: headwind,
                crosswind: crosswind,
                rwyId: runway.id,
                rwyHdg: rwyHdg,
                rwyLength: runway.length,
                rwyWidth: runway.width,
                inverted: me._getInvertedRwyId(runway.id),
                ils: runway.ils,
            });
        }

        return me._sortRunwysByHeadwind(runwaysData);
    },

    #
    # Sort runways data by headwind (the biggest headwind first).
    #
    # @param  vector  runwaysData  Array of runways data.
    # @return vector  Sorted array of runways data.
    #
    _sortRunwysByHeadwind: func(runwaysData) {
        return sort(runwaysData, func(a, b) {
                if (a.normDiffDeg > b.normDiffDeg) return  1;  # mniejszy normDiffDeg pierwszy
           else if (a.normDiffDeg < b.normDiffDeg) return -1;

           return 0;
        });
    },

    #
    # Get inverted runway id.
    #
    # @param  string  rwyId  Original runway id.
    # @return string  Inverted runway id.
    #
    _getInvertedRwyId: func(rwyId) {
        var side = substr(rwyId, size(rwyId) - 1, 1);  # last char, can be "L", "R", "C" or digit

        var invertedSide = me._getInvertedSide(side);
        var number = me._getNumberWithoutSide(rwyId, side);

        var innvertedNumber = math.round(math.mod(math.round(number * 10) + 180, 360) / 10);

        return sprintf("%02d%s", innvertedNumber, invertedSide);
    },

    #
    # Get inverted side of runway.
    #
    # @param  string  side  Side of runway: "L", "R", "C" or digit.
    # @return string  Inverted side of runway: "R", "L", "C" or "".
    #
    _getInvertedSide: func(side) {
             if (side == "L") return "R";
        else if (side == "R") return "L";
        else if (side == "C") return "C";

        return ""; # no side if side = digit
    },

    #
    # Get runway number without side.
    #
    # @param  string  rwyId  Full runway id, eg. "09L" or "09".
    # @param  string  side   Side of runway: "L", "R", "C" or digit.
    # @return string  Runway number without side.
    #
    _getNumberWithoutSide: func(rwyId, side) {
        if (side == "L" or side == "R" or side == "C") {
            return substr(rwyId, 0, size(rwyId) - 1); # return number only without last char
        }

        return rwyId;
    },
};
