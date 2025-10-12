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
# Bottom Bar for tab.
#
var BottomBar = {
    #
    # Constructor.
    #
    # @param  ghost  tabsContent  Tabs canvas content.
    # @param  string  tabId
    # @param  hash  downloadMetarCallback  Callback object to run download METAR function.
    # @return hash
    #
    new: func(tabsContent, tabId, downloadMetarCallback) {
        var obj = {
            parents: [
                BottomBar,
                DrawTabBase.new(tabId),
            ],
            _tabsContent: tabsContent,
            _downloadMetarCallback: downloadMetarCallback,
        };

        obj._icaoEdit = nil;
        obj._icao = "";
        obj._loadIcaoBtns = std.Vector.new();
        obj._isHoldUpdateNearest = false;

        if (obj._isTabNearest() or obj._isTabAlternate()) {
            for (var i = 0; i < 5; i += 1) {
                var btn = canvas.gui.widgets.Button.new(obj._tabsContent)
                    .setText("----");

                obj._loadIcaoBtns.append(btn);
            }
        }

        return obj;
    },

    #
    # Destructor.
    #
    # @return void
    #
    del: func() {
        me._loadIcaoBtns.clear();

        call(DrawTabBase.del, [], me);
    },

    #
    # @param  string  icao
    # @return  void
    #
    setIcao: func(icao) {
        me._icao = icao;

        if (me._icaoEdit != nil) {
            me._icaoEdit.setText(icao);
        }
    },

    #
    # Return true ich checkbox "Hold update" is checked.
    #
    # @return bool
    #
    isHoldUpdateNearest: func() {
        return me._isHoldUpdateNearest;
    },

    #
    # Update buttons with nearest airports.
    #
    # @return void
    #
    updateNearestAirportButtons: func() {
        var airports = findAirportsWithinRange(50); # range in NM
        var airportSize = size(airports);

        forindex (var index; me._loadIcaoBtns.vector) {
            var airport = index < airportSize ? airports[index] : nil;

            if (airport == nil) {
                me._loadIcaoBtns.vector[index]
                    .setText("----")
                    .setVisible(false)
                    .listen("clicked", nil);
                continue;
            }

            func() {
                var icao = airport.id;

                me._loadIcaoBtns.vector[index]
                    .setText(icao)
                    .setVisible(true)
                    .listen("clicked", func() {
                        me._downloadMetarCallback.invoke(icao);
                    });
            }();
        }
    },

    #
    # @return ghost  Canvas layout object with controls.
    #
    drawBottomBarForNearest: func() {
        var buttonBox = canvas.HBoxLayout.new();

        buttonBox.addStretch(1);
        foreach (var btn; me._loadIcaoBtns.vector) {
            buttonBox.addItem(btn);
        }

        var label = canvas.gui.widgets.Label.new(me._tabsContent)
            .setText("ICAO:");

        me._icaoEdit = canvas.gui.widgets.LineEdit.new(me._tabsContent)
            .setText(me._icao)
            .setFixedSize(80, 26)
            .listen("editingFinished", func(e) {
                me._downloadMetarCallback.invoke(e.detail.text);
            });

        var btnLoad = me._getButton("Load", func() {
            me._downloadMetarCallback.invoke(me._icaoEdit.text());
        });

        var holdUpdateCheckbox = canvas.gui.widgets.CheckBox.new(parent: me._tabsContent, cfg: { wordWrap: false })
            .setText("Hold update")
            .setChecked(false)
            .listen("toggled", func(e) {
                me._isHoldUpdateNearest = e.detail.checked;

                if (!me._isHoldUpdateNearest) {
                    # If the option is unchecked, immediately update the airport
                    # with the nearest one if it has changed from the current one.
                    var newIcao = getprop("/sim/airport/closest-airport-id");
                    if (newIcao != me._icao) {
                        me._downloadMetarCallback.invoke(newIcao);
                    }
                }
            });

        buttonBox.addStretch(1);
        buttonBox.addItem(label);
        buttonBox.addItem(me._icaoEdit);
        buttonBox.addItem(btnLoad);
        buttonBox.addStretch(1);
        buttonBox.addItem(holdUpdateCheckbox);
        buttonBox.addStretch(1);

        return buttonBox;
    },

    #
    # @return ghost  Canvas layout object with controls.
    #
    drawBottomBarForScheduledTab: func() {
        var buttonBox = canvas.HBoxLayout.new();

        var btnLoad = me._getButton("Update METAR", func() {
            me._downloadMetarCallback.invoke(me._icao);
        });

        buttonBox.addStretch(1);
        buttonBox.addItem(btnLoad);
        buttonBox.addStretch(1);

        return buttonBox;
    },

    #
    # @return ghost  Canvas layout object with controls.
    #
    drawBottomBarForAlternate: func() {
        var buttonBox = canvas.HBoxLayout.new();

        buttonBox.addStretch(1);
        foreach (var btn; me._loadIcaoBtns.vector) {
            buttonBox.addItem(btn);
        }

        var label = canvas.gui.widgets.Label.new(me._tabsContent)
            .setText("ICAO:");

        me._icaoEdit = canvas.gui.widgets.LineEdit.new(me._tabsContent)
            .setText(me._icao)
            .setFixedSize(80, 26)
            .listen("editingFinished", func(e) {
                me._downloadMetarCallback.invoke(e.detail.text);
            });

        var btnLoad = me._getButton("Load", func() {
            me._downloadMetarCallback.invoke(me._icaoEdit.text());
        });

        buttonBox.addStretch(1);
        buttonBox.addItem(label);
        buttonBox.addItem(me._icaoEdit);
        buttonBox.addItem(btnLoad);
        buttonBox.addStretch(1);

        return buttonBox;
    },

    #
    # @param  string  text  Label of button.
    # @param  func  callback  Function which will be executed after click the button.
    # @return ghost  Button widget.
    #
    _getButton: func(text, callback) {
        return canvas.gui.widgets.Button.new(me._tabsContent)
            .setText(text)
            .listen("clicked", callback);
    },
};
