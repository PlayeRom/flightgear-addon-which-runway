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
    # @param  ghost  metar  METAR object.
    # @return me
    #
    new: func(metar) {
        var me = { parents: [RunwaysData] };

        me._metar = metar;

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
        # var windDir = me._metar.getWindDir(airport) - magVariation;
        var windDir   = me._metar.getWindDir(airport); # it can be nil
        var windSpeed = me._metar.getWindSpeedKt();

        var runwaysData = [];

        foreach (var name; keys(airport.runways)) {
            var runway = airport.runways[name];

            var (normDiffDeg, headwind, crosswind) = me._calculateWinds(windDir, windSpeed, runway.heading);

            append(runwaysData, {
                type: "Runway",
                normDiffDeg: normDiffDeg == nil ? nil : math.abs(normDiffDeg),
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
                surface: runway.surface,
            });
        }

        foreach (var name; keys(airport.helipads)) {
            var helipad = airport.helipads[name];

            var (normDiffDeg, headwind, crosswind) = me._calculateWinds(windDir, windSpeed, helipad.heading);

            append(runwaysData, {
                type: "Helipad",
                normDiffDeg: normDiffDeg == nil ? nil : math.abs(normDiffDeg),
                headwind: headwind,
                crosswind: crosswind,
                rwyId: helipad.id,
                heading: helipad.heading,
                length: helipad.length,
                width: helipad.width,
                reciprocalId: "n/a",
                ils: nil,
                lat: helipad.lat,
                lon: helipad.lon,
                surface: helipad.surface,
            });
        }

        return windDir == nil
            ? runwaysData
            : me._sortRunwaysByHeadwind(runwaysData);
    },

    #
    # @param  double|nil  windDir
    # @param  double  windSpeed
    # @param  double  heading
    # @return vector
    #
    _calculateWinds: func(windDir, windSpeed, heading) {
        if (windDir == nil) {
            return [nil, nil, nil];
        }

        var diff        = windDir - heading;
        var normDiffDeg = Utils.normalizeCourse(diff, -180, 180); # normalize to [-180, 180]
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

        return [normDiffDeg, headwind, crosswind];
    },

    #
    # Sort runways data by smaller normDiffDeg first, i.e. larger headwind first.
    #
    # @param  vector  runwaysData  Array of runways data.
    # @return vector  Sorted array of runways data.
    #
    _sortRunwaysByHeadwind: func(runwaysData) {
        return sort(runwaysData, func(a, b) {
                if (a.normDiffDeg > b.normDiffDeg) return  1;
           else if (a.normDiffDeg < b.normDiffDeg) return -1;

           return 0;
        });
    },
};
