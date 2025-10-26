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
# Helper class for TabWidgetHelper.
#
var TabWidgetHelper = {
    #
    # TODO: TabWidget does not have a method to get the currently selected tab,
    #       so I get it via the private member _currentTabId. Fix this when the method is added.
    #
    # @param  ghost  context  TabWidget object.
    # @return string
    #
    getCurrentTabId: func(context) {
        return Utils.tryCatch(func typeof(context.getCurrentTabId))
            ? context.getCurrentTabId() # dev version
            : context._currentTabId; # 2024.x
    },

    #
    # TODO: If version 2024.x receives the setLabelForTabId() method, simply always use it directly.
    #
    # @param  ghost  context  TabWidget object.
    # @param  string  tabId
    # @param  string  label
    # @return void
    #
    setLabelForTabId: func(context, tabId, label) {
        if (Utils.tryCatch(func typeof(context.setLabelForTabId))) {
            context.setLabelForTabId(tabId, label); # dev version
        } else {
            # 2024.x
            context._tabButtons[tabId].setText(label);
            context.update();
        }
    },
};
