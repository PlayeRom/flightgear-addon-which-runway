#
# CanvasSkeleton Add-on for FlightGear
#
# Written and developer by Roman Ludwicki (PlayeRom, SP-ROM)
#
# Copyright (C) 2025 Roman Ludwicki
#
# This is an Open Source project and it is licensed
# under the GNU Public License v3 (GPLv3)
#

#
# MY_LOG_LEVEL is using in Log.print() to quickly change all logs visibility used in addon's namespace.
# Possible values: LOG_ALERT, LOG_WARN, LOG_INFO, LOG_DEBUG, LOG_BULK.
#
var MY_LOG_LEVEL = LOG_WARN;

#
# Global object of addons.Addon
#
var g_Addon = nil;

#
# Global object of VersionChecker.
#
var g_VersionChecker = nil;

#
# Global object of dialog
#
var g_WhichRwyDialog = nil;

#
# Global object of about dialog
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

        me._initDevMode();

        g_VersionChecker = VersionChecker.make();

        me._delayCanvasLoading(func {
            g_WhichRwyDialog = WhichRwyDialog.new();
            g_AboutDialog = AboutDialog.new();

            # Check the version at the end, because dialogs must first register
            # their callbacks to VersionChecker in their constructors.
            g_VersionChecker.checkLastVersion();
        });
    },

    #
    # Uninitialize object from add-on namespace.
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
    # Delay loading the entire Canvas add-on to avoid damaging aircraft displays such as A320, A330. The point is that,
    # for example, the A320 hard-coded the texture index from /canvas/by-index/texture[15]. But this add-on may creates
    # its canvas textures earlier than the airplane, which will cause that at index 15 there will be no texture of some
    # display but the texture from the add-on. So thanks to this delay, the textures of the plane will be created first,
    # and then the textures of this add-on.
    #
    # @param  func  callback
    # @return void
    #
    _delayCanvasLoading: func(callback) {
        # Disable menu items responsible for launching persistent dialogs.
        var menu = MenuStateHandler.new();
        menu.toggleItems(false);

        Timer.singleShot(3, func() {
            callback();

            # Enable menu items responsible for launching persistent dialogs.
            menu.toggleItems(true);
        });
    },

    #
    # Handle development mode (.env file).
    #
    # @return void
    #
    _initDevMode: func() {
        if (!Config.dev.useEnvFile) {
            return;
        }

        var env = DevEnv.new();

        var logLevel = env.getValue("MY_LOG_LEVEL");
        if (logLevel != nil) {
            MY_LOG_LEVEL = logLevel;
        }

        g_isDevMode = env.getBoolValue("DEV_MODE");

        if (g_isDevMode) {
            var reloadMenu = DevReloadMenu.new();

            env.getBoolValue("RELOAD_MENU")
                ? reloadMenu.addMenu()
                : reloadMenu.removeMenu();

            DevMultiKeyCmd.new()
                .addReloadAddon(env.getValue("RELOAD_MULTIKEY_CMD"))
                .addRunTests(env.getValue("TEST_MULTIKEY_CMD"))
                .finish();
        }
    },
};
