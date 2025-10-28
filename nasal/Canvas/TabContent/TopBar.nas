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
# Top Bar for tag.
#
var TopBar = {
    #
    # Constructor.
    #
    # @param  ghost  tabsContent  Tabs canvas content.
    # @param  hash  clickAptCallback  Callback object to click airport button.
    # @param  hash  clickRwyCallback  Callback object to click runway button.
    # @return hash
    #
    new: func(tabsContent, clickAptCallback, clickRwyCallback) {
        var obj = {
            parents: [
                TopBar,
            ],
            _tabsContent: tabsContent,
            _clickAptCallback: clickAptCallback,
            _clickRwyCallback: clickRwyCallback,
        };

        obj._airportBtn = canvas.gui.widgets.Button.new(obj._tabsContent)
            .setText("----")
            .setFixedSize(58, 28)
            .setVisible(false)
            .listen("clicked", func() {
                obj._clickAptCallback.invoke();
            });

        obj._runwayBtns = std.Vector.new();

        for (var i = 0; i < DrawTabContent.MAX_RUNWAY_SLOTS; i += 1) {
            var btn = canvas.gui.widgets.Button.new(obj._tabsContent)
                .setText("---")
                .setFixedSize(38, 28)
                .setVisible(false);

            obj._runwayBtns.append(btn);
        }

        return obj;
    },

    #
    # Destructor.
    #
    # @return void
    #
    del: func() {
        me._runwayBtns.clear();
    },

    #
    # Update buttons runways.
    #
    # @param  string  icao
    # @param  array  runwaysData
    # @return void
    #
    updateRunwayButtons: func(icao, runwaysData) {
        me._airportBtn
            .setText(icao)
            .setVisible(true);

        var rwySize = size(runwaysData);
        forindex (var index; me._runwayBtns.vector) {
            var rwy = index < rwySize ? runwaysData[index] : nil;
            var button = me._runwayBtns.vector[index];

            if (rwy == nil) {
                button.setText("---")
                    .setVisible(false)
                    .listen("clicked", func);

                continue;
            }

            button.setText(rwy.rwyId)
                .setVisible(true)
                .listen("clicked", me._clickCallback(index));
        }
    },

    #
    # @return  int  index
    # @return func
    #
    _clickCallback: func(index) {
        return func me._clickRwyCallback.invoke(index);
    },

    #
    # @return ghost  Canvas layout object with controls.
    #
    drawTopBar: func() {
        var buttonBox = canvas.HBoxLayout.new();

        buttonBox.addStretch(1);
        buttonBox.addItem(me._airportBtn);

        foreach (var btn; me._runwayBtns.vector) {
            buttonBox.addItem(btn);
        }

        buttonBox.addStretch(1);

        return buttonBox;
    },
};
