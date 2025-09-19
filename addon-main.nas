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
# @param  ghost  addon  The addons.Addon object
# @return void
#
var main = func(addon) {
    logprint(LOG_ALERT, addon.name, " Add-on initialized from path ", addon.basePath);

    loadExtraNasalFiles(addon);

    whichRunway.init(addon);
};

#
# Load extra Nasal files in main add-on directory
#
# @param  ghost  addon  The addons.Addon object
# @return void
#
var loadExtraNasalFiles = func(addon) {
    var modules = [
        "nasal/Utils/Callback",
        "nasal/Utils/Listeners",
        "nasal/Utils/Log",
        "nasal/Utils/Profiler",
        "nasal/Utils/Utils",

        "nasal/Colors",
        "nasal/Metar",
        "nasal/Fonts",
        "nasal/RunwaysData",

        "nasal/Canvas/DrawTabContent",
        "nasal/Canvas/BottomBar",
        "nasal/Canvas/Dialog",

        "nasal/Canvas/AboutDialog",
        "nasal/Canvas/WhichRwyDialog",
        "nasal/Canvas/ScrollAreaHelper",

        "WhichRwy",
    ];

    loadVectorOfModules(addon, modules, "whichRunway");

    # Add widgets to canvas namespace
    var widgets = [
        "nasal/Canvas/Widgets/AirportInfoView",
        "nasal/Canvas/Widgets/MessageView",
        "nasal/Canvas/Widgets/MetarInfoView",
        "nasal/Canvas/Widgets/PressureLabel",
        "nasal/Canvas/Widgets/RunwayInfoView",
        "nasal/Canvas/Widgets/WindLabel",
        "nasal/Canvas/Widgets/WindRoseView",
        "nasal/Canvas/Widgets/Styles/DefaultStyleAirportInfoView",
        "nasal/Canvas/Widgets/Styles/DefaultStyleMessageView",
        "nasal/Canvas/Widgets/Styles/DefaultStyleMetarInfoView",
        "nasal/Canvas/Widgets/Styles/DefaultStylePressureLabel",
        "nasal/Canvas/Widgets/Styles/DefaultStyleRunwayInfoView",
        "nasal/Canvas/Widgets/Styles/DefaultStyleWindLabel",
        "nasal/Canvas/Widgets/Styles/DefaultStyleWindRoseView",
        "nasal/Canvas/Widgets/Styles/Components/Draw",
    ];

    loadVectorOfModules(addon, widgets, "canvas");
};

#
# @param  ghost  addon  The addons.Addon object.
# @param  vector  modules
# @param  string  namespace
# @return void
#
var loadVectorOfModules = func(addon, modules, namespace) {
    foreach (var scriptName; modules) {
        var fileName = addon.basePath ~ "/" ~ scriptName ~ ".nas";

        if (!io.load_nasal(fileName, namespace)) {
            logprint(LOG_ALERT, addon.name, " Add-on module \"", scriptName, "\" loading failed");
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
# @param  ghost  addon  The addons.Addon object.
# @return void
#
var unload = func(addon) {
    whichRunway.uninit();
};
