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
    # Constants:
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

        obj._runwayUse = RwyUse.new();
        obj._basicWeather = BasicWeather.new();

        obj._aircraftTypeFinder = AircraftTypeFinder.new();
        obj._aircraftType = obj._aircraftTypeFinder.getType();
        g_Settings.setRwyUseAircraftType(obj._aircraftType);

        obj._timer = Timer.make(3, obj, obj._updateDynamicData);
        obj._timer.simulatedTime = true;

        obj._tabs = canvas.gui.widgets.TabWidget.new(parent: obj._group, cfg: { "tabs-closeable": false });
        obj._tabsContent = obj._tabs.getContent();
        obj._vbox.addItem(obj._tabs);

        obj._tabContents = std.Hash.new();

        obj._createTab(me.TAB_NEAREST);
        obj._createTab(me.TAB_DEPARTURE);
        obj._createTab(me.TAB_ARRIVAL);
        obj._createTab(me.TAB_ALTERNATE);

        obj._tabs.setCurrentTab(me.TAB_NEAREST);

        obj._keyActions();

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
    # Show the dialog.
    #
    # @return void
    # @override PersistentDialog
    #
    show: func() {
        me._updateDynamicData();
        me._timer.start();

        call(PersistentDialog.show, [], me);
    },

    #
    # Hide the dialog.
    #
    # @return void
    # @override PersistentDialog
    #
    hide: func() {
        me._timer.stop();

        call(PersistentDialog.hide, [], me);
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

        var drawTabContent = DrawTabContent.new(
            me._tabsContent,
            layout,
            tabId,
            me._runwayUse,
            me._basicWeather,
            me._aircraftType,
            Callback.new(me._icaoUpdatedCallback, me),
        );

        me._tabContents.set(tabId, drawTabContent);
    },

    #
    # Reload all tabs.
    #
    # @return void
    #
    reloadAllTabs: func() {
        foreach (var tabId; me._tabContents.getKeys()) {
            me._tabContents.get(tabId).reload();
        }
    },

    #
    # @param  string  tabId
    # @return string
    #
    _getLabelByTagId: func(tabId) {
        if (tabId == me.TAB_NEAREST)   return "Nearest";
        if (tabId == me.TAB_DEPARTURE) return "Departure";
        if (tabId == me.TAB_ARRIVAL)   return "Arrival";
        if (tabId == me.TAB_ALTERNATE) return "Alternate";

        return "";
    },

    #
    # Timer callback function to update dynamic data on the selected tab.
    #
    # @return void
    #
    _updateDynamicData: func() {
        var currentTabId = TabWidgetHelper.getCurrentTabId(me._tabs);

        if (currentTabId != nil and me._tabContents.contains(currentTabId)) {
            me._tabContents.get(currentTabId).updateDynamicData();
        }
    },

    #
    # @param  string  tabId
    # @param  string  icao
    # @return void
    #
    _icaoUpdatedCallback: func(tabId, icao) {
        var label = me._getLabelByTagId(tabId) ~ " (" ~ icao ~ ")";

        TabWidgetHelper.setLabelForTabId(me._tabs, tabId, label);
    },

    #
    # Handle keydown listener for window.
    #
    # @return void
    #
    _keyActions: func() {
        me._window.addEventListener("keydown", func(event) {
               if (event.key == "Up"     or event.key == "Down")     me._handleScrollKey(true,  event.key == "Up");
            elsif (event.key == "PageUp" or event.key == "PageDown") me._handleScrollKey(false, event.key == "PageUp");
            elsif (event.key == "1") me._tabs.setCurrentTab(me.TAB_NEAREST);
            elsif (event.key == "2") me._tabs.setCurrentTab(me.TAB_DEPARTURE);
            elsif (event.key == "3") me._tabs.setCurrentTab(me.TAB_ARRIVAL);
            elsif (event.key == "4") me._tabs.setCurrentTab(me.TAB_ALTERNATE);
        });
    },

    #
    # @param  bool  isArrow  If true then arrow up/down keys, otherwise page up/down keys.
    # @param  bool  isUp  If true then dy must be converted to negative.
    # @return void
    #
    _handleScrollKey: func(isArrow, isUp) {
        var currentTabId = TabWidgetHelper.getCurrentTabId(me._tabs);
        var tab = me._tabContents.get(currentTabId);

        var dy = tab.getScrollPageHeight();

        if (isArrow) {
            # The arrows move the scroll by 1/20 of the visible screen.
            dy /= 20;
        }

        if (isUp) {
            dy = -dy;
        }

        tab.vertScrollBarBy(dy);
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
