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
# Main Nasal function
#
# @param  ghost  addon  addons.Addon object
# @return void
#
var main = func(addon) {
    logprint(LOG_ALERT, "Which Runway addon initialized from path ", addon.basePath);

    loadExtraNasalFiles(addon);

    whichRunway.init(addon);
};

#
# Load extra Nasal files in main add-on directory
#
# @param  ghost  addon  addons.Addon object
# @return void
#
var loadExtraNasalFiles = func(addon) {
    var modules = [
        "nasal/Colors",
        "nasal/Listeners",
        "nasal/METAR",
        "nasal/Utils",
        "nasal/Fonts",
        "nasal/Canvas/DrawTabContent",
        "nasal/Canvas/DrawWindRose",
        "nasal/Canvas/DrawRunways",
        "nasal/Canvas/Dialog",
        "nasal/Canvas/AboutDialog",
        "nasal/Canvas/WhichRwyDialog",
        "nasal/RunwaysData",
        "WhichRwy",
    ];

    loadVectorOfModules(addon, modules, "whichRunway");
};

#
# @param  ghost  addon  addons.Addon object
# @param  vector  modules
# @param  string  namespace
# @return void
#
var loadVectorOfModules = func(addon, modules, namespace) {
    foreach (var scriptName; modules) {
        var fileName = addon.basePath ~ "/" ~ scriptName ~ ".nas";

        if (!io.load_nasal(fileName, namespace)) {
            logprint(LOG_ALERT, "Which Runway Add-on module \"", scriptName, "\" loading failed");
        }
    }
};

#
# This function is for addon development only. It is called on addon reload.
# The addons system will replace setlistener() and maketimer() to track this
# resources automatically for you.
#
# Listeners created with setlistener() will be removed automatically for you.
# Timers created with maketimer() will have their stop() method called
# automatically for you. You should NOT use settimer anymore, see wiki at
# http://wiki.flightgear.org/Nasal_library#maketimer.28.29
#
# Other resources should be freed by adding the corresponding code here,
# e.g. myCanvas.del();
#
# @param  ghost  addon  addons.Addon object
# @return void
#
var unload = func(addon) {
    whichRunway.uninit();
};
