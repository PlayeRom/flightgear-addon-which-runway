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
# WhichRwyDialog dialog class
#
var WhichRwyDialog = {
    #
    # Constants
    #
    WINDOW_WIDTH : 800,
    WINDOW_HEIGHT: 700,

    TAB_NEAREST  : "tab-nearest",
    TAB_DEPARTURE: "tab-departure",
    TAB_ARRIVAL  : "tab-arrival",
    TAB_ALTERNATE: "tab-alternate",

    #
    # Constructor
    #
    # @return hash
    #
    new: func() {
        var me = { parents: [
            WhichRwyDialog,
            Dialog.new(
                width : WhichRwyDialog.WINDOW_WIDTH,
                height: WhichRwyDialog.WINDOW_HEIGHT,
                title : "Which Runway",
                resize: true,
            ),
        ] };

        me.setPositionOnCenter();

        me._tabs = canvas.gui.widgets.TabWidget.new(me._group, canvas.style, {"tabs-closeable": false});
        me._tabsContent = me._tabs.getContent();
        me._vbox.addItem(me._tabs);

        me._drawTabContentNearest   = me._createTab(WhichRwyDialog.TAB_NEAREST, "Nearest");
        me._drawTabContentDeparture = me._createTab(WhichRwyDialog.TAB_DEPARTURE, "Departure");
        me._drawTabContentArrival   = me._createTab(WhichRwyDialog.TAB_ARRIVAL, "Arrival");
        me._drawTabContentAlternate = me._createTab(WhichRwyDialog.TAB_ALTERNATE, "Alternate");

        me._tabs.setCurrentTab(WhichRwyDialog.TAB_NEAREST);

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
        return DrawTabContent.new(me._tabsContent, layout, tabId);
    },

    #
    # Destructor
    #
    # @return void
    #
    del: func() {
        me._drawTabContentNearest.del();
        me._drawTabContentDeparture.del();
        me._drawTabContentArrival.del();
        me._drawTabContentAlternate.del();

        call(Dialog.del, [], me);
    },
};
