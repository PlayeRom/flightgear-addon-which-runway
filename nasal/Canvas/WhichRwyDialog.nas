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
    CLASS: "WhichRwyDialog",

    #
    # Constants:
    #
    WINDOW_WIDTH : 800,
    WINDOW_HEIGHT: 700,

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
                    width : WhichRwyDialog.WINDOW_WIDTH,
                    height: WhichRwyDialog.WINDOW_HEIGHT,
                    title : sprintf("Which Runway %s", g_Addon.version.str()),
                    resize: true,
                ),
            ],
        };

        var dialogParent = me.parents[1];
        dialogParent.setChild(me, WhichRwyDialog); # Let the parent know who their child is.
        dialogParent.setPositionOnCenter();

        me._runwaysUse = RwyUse.new();

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
        return DrawTabContent.new(me._tabsContent, layout, tabId, me._runwaysUse);
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

        me.parents[1].del();
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

        me.parents[1].show();
    },

    #
    # Hide the dialog.
    #
    # @return void
    # @override PersistentDialog
    #
    hide: func() {
        me._timer.stop();

        me.parents[1].hide();
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
            # Possible fields of event:
            #   event.key - key as name
            #   event.keyCode - key as code
            # Modifiers:
            #   event.shiftKey
            #   event.ctrlKey
            #   event.altKey
            #   event.metaKey

            if (event.key == "Up") {
                me._tabContents[me._tabs._currentTabId].vertScrollBarBy(-g_Settings.getKeyArrowMoveSize());
            } elsif (event.key == "Down") {
                me._tabContents[me._tabs._currentTabId].vertScrollBarBy(g_Settings.getKeyArrowMoveSize());
            } elsif (event.key == "PageUp") {
                me._tabContents[me._tabs._currentTabId].vertScrollBarBy(-g_Settings.getKeyPageMoveSize());
            } elsif (event.key == "PageDown") {
                me._tabContents[me._tabs._currentTabId].vertScrollBarBy(g_Settings.getKeyPageMoveSize());
            } elsif (event.key == "1") {
                me._tabs.setCurrentTab(WhichRwyDialog.TAB_NEAREST);
            } elsif (event.key == "2") {
                me._tabs.setCurrentTab(WhichRwyDialog.TAB_DEPARTURE);
            } elsif (event.key == "3") {
                me._tabs.setCurrentTab(WhichRwyDialog.TAB_ARRIVAL);
            } elsif (event.key == "4") {
                me._tabs.setCurrentTab(WhichRwyDialog.TAB_ALTERNATE);
            }
        });
    },
};
