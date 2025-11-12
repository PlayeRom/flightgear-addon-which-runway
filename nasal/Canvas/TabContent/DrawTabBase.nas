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
# DrawTabBase class.
#
var DrawTabBase = {
    #
    # Constructor.
    #
    # @param  string  tabId
    # @return hash
    #
    new: func(tabId) {
        var obj = {
            parents: [DrawTabBase],
            _tabId: tabId,
        };

        obj._addonNodePath = g_Addon.node.getPath();

        return obj;
    },

    #
    # Destructor.
    #
    # @return void
    #
    del: func {
    },

    #
    # Return true if current tab it's "Nearest" tab.
    #
    # @return bool
    #
    _isTabNearest: func {
        return me._tabId == WhichRwyDialog.TAB_NEAREST;
    },

    #
    # Return true if current tab it's "Departure" tab.
    #
    # @return bool
    #
    _isTabDeparture: func {
        return me._tabId == WhichRwyDialog.TAB_DEPARTURE;
    },

    #
    # Return true if current tab it's "Arrival" tab.
    #
    # @return bool
    #
    _isTabArrival: func {
        return me._tabId == WhichRwyDialog.TAB_ARRIVAL;
    },

    #
    # Return true if current tab it's "Alternate" tab.
    #
    # @return bool
    #
    _isTabAlternate: func {
        return me._tabId == WhichRwyDialog.TAB_ALTERNATE;
    },
};
