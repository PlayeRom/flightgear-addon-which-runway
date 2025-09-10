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
# MY_LOG_LEVEL is using in logprint() to quickly change all logs visibility used in "whichRunway" namespace.
# The flags like LOG_ALERT, LOG_INFO etc. are available from FG 2020.1.
#
var MY_LOG_LEVEL = LOG_INFO;

#
# Global object of addons.Addon
#
var g_Addon = nil;

#
# Global object of dialog
#
var g_WhichRwyDialog = nil;

#
# Global object of about dialog
#
var g_AboutDialog = nil;

#
# Initialize Which Runway
#
# @param  ghost  addon  addons.Addon object
# @return void
#
var init = func(addon) {
    g_Addon = addon;
    g_WhichRwyDialog = WhichRwyDialog.new();
    g_AboutDialog = AboutDialog.new();
};

#
# Uninitialize Which Runway
#
# @return void
#
var uninit = func() {
    if (g_WhichRwyDialog != nil) {
        g_WhichRwyDialog.del();
    }

    if (g_AboutDialog != nil) {
        g_AboutDialog.del();
    }
};
