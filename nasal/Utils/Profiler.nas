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
# Profiler class.
#
var Profiler = {
    #
    # Constructor.
    #
    # @return hash
    #
    new: func() {
        var me = { parents: [Profiler] };

        me._startTime = nil;

        return me;
    },

    #
    # Start profiler.
    #
    # @return void
    #
    start: func() {
        me._startTime = systime();
    },

    #
    # Stop profiler and log result.
    #
    # @param  string  message  Extra context message.
    # @return double  Measurement time in seconds.
    #
    stop: func(message = nil) {
        message = message == nil ? "" : "Context: " ~ message;

        if (me._startTime == nil) {
            logprint(MY_LOG_LEVEL, g_Addon.name, " ----- profiler time = ? seconds. FIRST RUN start() method. ", message);
        }

        var time = systime() - me._startTime;

        logprint(MY_LOG_LEVEL, g_Addon.name, " ----- profiler time = ", time, " seconds. ", message);

        return time;
    },
};
