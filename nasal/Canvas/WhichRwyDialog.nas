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
# WhichRwyDialog dialog class.
#
var WhichRwyDialog = {
    #
    # Constants
    #
    TAB_NEAREST  : "tab-nearest",
    TAB_DEPARTURE: "tab-departure",
    TAB_ARRIVAL  : "tab-arrival",
    TAB_ALTERNATE: "tab-alternate",

    #
    # Constructor.
    #
    # @return hash
    #
    new: func() {
        var obj = {
            parents: [
                WhichRwyDialog,
                PersistentDialog.new(
                    width : 800,
                    height: 700,
                    title : me._getStandardTitle(),
                    resize: true,
                ),
            ],
        };

        call(PersistentDialog.setChild, [obj, WhichRwyDialog], obj.parents[1]); # Let the parent know who their child is.
        call(PersistentDialog.setPositionOnCenter, [], obj.parents[1]);

        obj._tabs = canvas.gui.widgets.TabWidget.new(obj._group, canvas.style, { "tabs-closeable": false });
        obj._tabsContent = obj._tabs.getContent();
        obj._vbox.addItem(obj._tabs);

        obj._tabContents = std.Hash.new();

        obj._createTab(me.TAB_NEAREST);
        obj._createTab(me.TAB_DEPARTURE);
        obj._createTab(me.TAB_ARRIVAL);
        obj._createTab(me.TAB_ALTERNATE);

        obj._tabs.setCurrentTab(WhichRwyDialog.TAB_NEAREST);

        g_VersionChecker.registerCallback(Callback.new(obj._newVersionAvailable, obj));

        return obj;
    },

    #
    # Destructor.
    #
    # @return void
    # @override PersistentDialog
    #
    del: func() {
        me._timer.stop();

        foreach (var tabId; me._tabContents.getKeys()) {
            me._tabContents.get(tabId).del();
        }

        me._basicWeather.del();
        me._runwayUse.del();
        me._aircraftTypeFinder.del();

        call(PersistentDialog.del, [], me);
    },

    #
    # Create single tab.
    #
    # @param  string  tabId  Unique tab ID.
    # @return void
    #
    _createTab: func(tabId) {
        var layout = canvas.VBoxLayout.new();
        me._tabs.addTab(tabId, me._getLabelByTagId(tabId), layout);

        var drawTabContent = DrawTabContent.new(me._tabsContent, layout, tabId);

        me._tabContents.set(tabId, drawTabContent);
    },

    #
    # @param  string  tabId
    # @return string
    #
    _getLabelByTagId: func(tabId) {
           if (tabId == me.TAB_NEAREST)   return "Nearest";
        elsif (tabId == me.TAB_DEPARTURE) return "Departure";
        elsif (tabId == me.TAB_ARRIVAL)   return "Arrival";
        elsif (tabId == me.TAB_ALTERNATE) return "Alternate";

        return "";
    },

    #
    # Get window title.
    #
    # @return string
    #
    _getStandardTitle: func() {
        return g_Addon.name ~ " " ~ g_Addon.version.str();
    },

    #
    # Callback called when a new version of add-on is detected.
    #
    # @param  string  newVersion
    # @return void
    #
    _newVersionAvailable: func(newVersion) {
        var title = sprintf("%s (new version %s is available)", me._getStandardTitle(), newVersion);

        me._window.set("title", title);
    },
};
