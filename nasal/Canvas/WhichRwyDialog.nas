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

        me._tabs = canvas.gui.widgets.TabWidget.new(me.group, canvas.style, {"tabs-closeable": false});
        me._tabsContent = me._tabs.getContent();
        me.vbox.addItem(me._tabs);

        me._tabNearest   = canvas.VBoxLayout.new();
        me._tabDeparture = canvas.VBoxLayout.new();
        me._tabArrival   = canvas.VBoxLayout.new();
        me._tabAlternate = canvas.VBoxLayout.new();

        me._tabs.addTab(WhichRwyDialog.TAB_NEAREST, "Nearest", me._tabNearest);
        me._tabs.addTab(WhichRwyDialog.TAB_DEPARTURE, "Departure", me._tabDeparture);
        me._tabs.addTab(WhichRwyDialog.TAB_ARRIVAL, "Arrival", me._tabArrival);
        me._tabs.addTab(WhichRwyDialog.TAB_ALTERNATE, "Alternate", me._tabAlternate);

        me._drawTabContentNearest   = DrawTabContent.new(me._tabsContent, me._tabNearest, WhichRwyDialog.TAB_NEAREST);
        me._drawTabContentDeparture = DrawTabContent.new(me._tabsContent, me._tabDeparture, WhichRwyDialog.TAB_DEPARTURE);
        me._drawTabContentArrival   = DrawTabContent.new(me._tabsContent, me._tabArrival, WhichRwyDialog.TAB_ARRIVAL);
        me._drawTabContentAlternate = DrawTabContent.new(me._tabsContent, me._tabAlternate, WhichRwyDialog.TAB_ALTERNATE);

        me._tabs.setCurrentTab(WhichRwyDialog.TAB_NEAREST);

        return me;
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
