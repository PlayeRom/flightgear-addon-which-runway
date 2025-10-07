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
        var me = {
            parents: [
                WhichRwyDialog,
                PersistentDialog.new(
                    width : 800,
                    height: 700,
                    title : sprintf("Which Runway %s", g_Addon.version.str()),
                    resize: true,
                ),
            ],
        };

        me._parentDialog = me.parents[1];
        me._parentDialog.setChild(me, WhichRwyDialog); # Let the parent know who their child is.
        me._parentDialog.setPositionOnCenter();

        me._runwayUse = RwyUse.new();
        me._basicWeather = BasicWeather.new();

        me._aircraftTypeFinder = AircraftTypeFinder.new();
        me._aircraftType = me._aircraftTypeFinder.getType();
        g_Settings.setRwyUseAircraftType(me._aircraftType);

        me._timer = Timer.make(3, me, me._updateDynamicData);
        me._timer.simulatedTime = true;

        me._tabs = canvas.gui.widgets.TabWidget.new(parent: me._group, cfg: { "tabs-closeable": false });
        me._tabsContent = me._tabs.getContent();
        me._vbox.addItem(me._tabs);

        me._tabContents = {};

        me._tabContents[WhichRwyDialog.TAB_NEAREST]   = me._createTab(WhichRwyDialog.TAB_NEAREST, "Nearest");
        me._tabContents[WhichRwyDialog.TAB_DEPARTURE] = me._createTab(WhichRwyDialog.TAB_DEPARTURE, "Departure");
        me._tabContents[WhichRwyDialog.TAB_ARRIVAL]   = me._createTab(WhichRwyDialog.TAB_ARRIVAL, "Arrival");
        me._tabContents[WhichRwyDialog.TAB_ALTERNATE] = me._createTab(WhichRwyDialog.TAB_ALTERNATE, "Alternate");

        me._tabs.setCurrentTab(WhichRwyDialog.TAB_NEAREST);

        me._keyActions();

        g_VersionChecker.registerCallback(Callback.new(me.newVersionAvailable, me));

        return me;
    },

    #
    # Create single tab.
    #
    # @param  string  tabId  Unique tab ID.
    # @param  string  label  Text displayed on the tba.
    # @return hash  DrawTabContent object.
    #
    _createTab: func(tabId, label) {
        var layout = canvas.VBoxLayout.new();
        me._tabs.addTab(tabId, label, layout);
        return DrawTabContent.new(me._tabsContent, layout, tabId, me._runwayUse, me._basicWeather, me._aircraftType);
    },

    #
    # Destructor.
    #
    # @return void
    # @override PersistentDialog
    #
    del: func() {
        me._timer.stop();

        foreach (var tabId; keys(me._tabContents)) {
            me._tabContents[tabId].del();
        }

        me._basicWeather.del();
        me._runwayUse.del();
        me._aircraftTypeFinder.del();

        me._parentDialog.del();
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

        me._parentDialog.show();
    },

    #
    # Hide the dialog.
    #
    # @return void
    # @override PersistentDialog
    #
    hide: func() {
        me._timer.stop();

        me._parentDialog.hide();
    },

    #
    # Reload all tabs.
    #
    # @return void
    #
    reloadAllTabs: func() {
        foreach (var tabId; keys(me._tabContents)) {
            me._tabContents[tabId].reload();
        }
    },

    #
    # Timer callback function to update dynamic data on the selected tab.
    #
    # @return void
    #
    _updateDynamicData: func() {
        # TODO: TabWidget does not have a method to get the currently selected tab,
        # so I get it via the private member _currentTabId. Fix this when the method is added.
        var currentTabId = me._tabs._currentTabId;
        if (currentTabId != nil and globals.contains(me._tabContents, currentTabId)) {
            me._tabContents[currentTabId].updateDynamicData();
        }
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
            elsif (event.key == "1") me._tabs.setCurrentTab(WhichRwyDialog.TAB_NEAREST);
            elsif (event.key == "2") me._tabs.setCurrentTab(WhichRwyDialog.TAB_DEPARTURE);
            elsif (event.key == "3") me._tabs.setCurrentTab(WhichRwyDialog.TAB_ARRIVAL);
            elsif (event.key == "4") me._tabs.setCurrentTab(WhichRwyDialog.TAB_ALTERNATE);
        });
    },

    #
    # @param  bool  isArrow  If true then arrow up/down keys, otherwise page up/down keys.
    # @param  bool  isUp  If true then dy must be converted to negative.
    # @return void
    #
    _handleScrollKey: func(isArrow, isUp) {
        var tab = me._tabContents[me._tabs._currentTabId];

        var dy = isArrow
            ? g_Settings.getKeyArrowMoveSize()
            : tab.getScrollPageHeight();

        if (isUp) {
            dy = -dy;
        }

        tab.vertScrollBarBy(dy);
    },

    #
    # Callback called when a new version of add-on is detected.
    #
    # @param  string  newVersion
    # @return void
    #
    newVersionAvailable: func(newVersion) {
        var title = sprintf("Which Runway %s (new version %s is available)", g_Addon.version.str(), newVersion);

        me._window.set("title", title);
    },
};
