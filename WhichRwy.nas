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
# @param  ghost  addon  The addons.Addon object.
# @return void
#
var init = func(addon) {
    g_Addon = addon;

    # Disable the menu as it loads with delay.
    gui.menuEnable("which-runway-addon-main", false);
    gui.menuEnable("which-runway-addon-about", false);

    # Delay loading of the whole addon so as not to break the MCDUs for aircraft like A320, A330. The point is that,
    # for example, the A320 hard-coded the texture index from /canvas/by-index/texture[15]. But this add-on creates its
    # canvas textures earlier than the airplane, which will cause that at index 15 there will be no MCDU texture but
    # the texture from the add-on. So thanks to this delay, the textures of the plane will be created first, and then
    # the textures of this add-on.
    var delayTimer = maketimer(3, func() {
        g_WhichRwyDialog = WhichRwyDialog.new();
        g_AboutDialog = AboutDialog.new();

        gui.menuEnable("which-runway-addon-main", true);
        gui.menuEnable("which-runway-addon-about", true);
    });
    delayTimer.singleShot = true;
    delayTimer.start();
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
