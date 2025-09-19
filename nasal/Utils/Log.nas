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
# Log class with own log format.
#
var Log = {
    #
    # Print log.
    #
    # @param  vector  msg...  List of texts.
    # @return void
    #
    print: func(msg...) {
        logprint(MY_LOG_LEVEL, g_Addon.name, " ----- ", string.join("", msg));
    },
};
