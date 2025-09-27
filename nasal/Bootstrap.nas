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
# MY_LOG_LEVEL is using in Log.print() to quickly change all logs visibility used in addon's namespace.
# Possible values: LOG_ALERT, LOG_WARN, LOG_INFO, LOG_DEBUG, LOG_BULK.
#
var MY_LOG_LEVEL = LOG_WARN;

#
# Global flag to enable dev mode.
# You can use this flag to condition on heavier logging that shouldn't be
# executed for the end user, but you want to keep it in your code for development
# purposes. This flag will be set to true automatically when you use an .env
# file with DEV_MODE=true.
#
var g_isDevMode = false;

#
# Global object of addons.Addon.
#
var g_Addon = nil;

#
# Global object of dialog.
#
var g_WhichRwyDialog = nil;

#
# Global object of about dialog.
#
var g_AboutDialog = nil;

#
# Create objects from add-on namespace.
#
var Bootstrap = {
    #
    # Initialize objects from add-on namespace.
    #
    # @param  ghost  addon  The addons.Addon object.
    # @return void
    #
    init: func(addon) {
        g_Addon = addon;

        Bootstrap._initDevMode();

        # Disable the menu as it loads with delay.
        gui.menuEnable("which-runway-addon-main", false);
        gui.menuEnable("which-runway-addon-about", false);

        # Delay loading of the whole addon so as not to break the MCDUs for aircraft like A320, A330. The point is that,
        # for example, the A320 hard-coded the texture index from /canvas/by-index/texture[15]. But this add-on creates
        # its canvas textures earlier than the airplane, which will cause that at index 15 there will be no MCDU texture
        # but the texture from the add-on. So thanks to this delay, the textures of the plane will be created first, and
        # then the textures of this add-on.
        Timer.singleShot(3, func() {
            g_WhichRwyDialog = WhichRwyDialog.new();
            g_AboutDialog = AboutDialog.new();

            gui.menuEnable("which-runway-addon-main", true);
            gui.menuEnable("which-runway-addon-about", true);
        });
    },

    #
    # Uninitialize Which Runway
    #
    # @return void
    #
    uninit: func() {
        Profiler.clear();

        if (g_WhichRwyDialog != nil) {
            g_WhichRwyDialog.del();
        }

        if (g_AboutDialog != nil) {
            g_AboutDialog.del();
        }
    },

    #
    # Handle development mode (.env file).
    #
    # @return void
    #
    _initDevMode: func() {
        var reloadMenu = DevReloadMenu.new();
        var env = DevEnv.new();

        g_isDevMode = env.getValue("DEV_MODE");
        if (g_isDevMode == nil) {
            g_isDevMode = false;
        }

        g_isDevMode
            ? reloadMenu.addMenu()
            : reloadMenu.removeMenu();

        var logLevel = env.getValue("MY_LOG_LEVEL");
        if (logLevel != nil) {
            MY_LOG_LEVEL = logLevel;
        }
    },
};
