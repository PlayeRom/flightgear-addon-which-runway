#
# Which Runway - Add-on for FlightGear
#
# Written and developer by Roman Ludwicki (PlayeRom, SP-ROM)
#
# Copyright (C) 2025 Roman Ludwicki
#
# Which Runway is an Open Source project and it is licensed
# under the GNU Public License v3 (GPLv3)
#

#
# Utils static methods
#
var Utils = {
    #
    # Convert value to string
    #
    # @param  string|int|double  value
    # @return string
    #
    toString: func(value) {
        return sprintf("%s", value);
    },

    #
    # Open URL or path in the system browser or file explorer.
    #
    # @param  hash  params  Parameters for open-browser command, can be "path" or "url".
    # @return void
    #
    openBrowser: func(params) {
        fgcommand("open-browser", props.Node.new(params));
    },

    #
    # @param  func  function
    # @param  vector  params
    # @return bool  Return true if given function was called without errors (die)
    #
    tryCatch: func(function, params, obj = nil) {
        var errors = [];
        call(function, params, obj, nil, errors);

        return !size(errors);
    },

    #
    # @param  int|double  course
    # @param  int  min  Min value of result, default 0.
    # @param  int  max  Max value of result, default 360.
    # @return int
    #
    normalizeCourse: func(course, min = 0, max = 360) {
        var range = max - min;
        var result = math.round(math.mod(course - max, range) + min);

        #  if the result is at the upper limit (eg. 360), we move back to the lower limit (0).
        if (result == max) {
            result = min;
        }

        return result;
    },
};
