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

            var diff = windDir - runway.heading;
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
                heading: runway.heading,
                length: runway.length,
                width: runway.width,
                reciprocalId: runway.reciprocal.id,
                ils: runway.ils,
                lat: runway.lat,
                lon: runway.lon,
            });
        }

        return me._sortRunwysByHeadwind(runwaysData);
    },

    #
    # Sort runways data by smaller normDiffDeg first, i.e. larger headwind first.
    #
    # @param  vector  runwaysData  Array of runways data.
    # @return vector  Sorted array of runways data.
    #
    _sortRunwysByHeadwind: func(runwaysData) {
        return sort(runwaysData, func(a, b) {
                if (a.normDiffDeg > b.normDiffDeg) return  1;
           else if (a.normDiffDeg < b.normDiffDeg) return -1;

           return 0;
        });
    },
};
