#
# Which runway Add-on for FlightGear
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

        obj._widget = WidgetHelper.new(obj._tabsContent);

        obj._icaoEdit = nil;
        obj._icao = "";
        obj._loadIcaoBtns = nil;
        obj._isHoldUpdateNearest = false;

        if (obj._isTabNearest() or obj._isTabAlternate()) {
            obj._loadIcaoBtns = std.Vector.new();

            for (var i = 0; i < 5; i += 1) {
                var btn = obj._widget.getButton("----");

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
    del: func {
        if (me._loadIcaoBtns != nil) {
            me._loadIcaoBtns.clear();
        }

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
    isHoldUpdateNearest: func {
        return me._isHoldUpdateNearest;
    },

    #
    # Update buttons with nearest airports.
    #
    # @return void
    #
    updateNearestAirportButtons: func {
        if (!me._isTabNearest() and !me._isTabAlternate()) {
            return;
        }

        var airports = findAirportsWithinRange(50, g_Settings.getNearestType()); # range in NM
        var airportSize = size(airports);

        forindex (var index; me._loadIcaoBtns.vector) {
            var airport = index < airportSize ? airports[index] : nil;
            var button = me._loadIcaoBtns.vector[index];

            if (airport == nil) {
                button.setText("----")
                    .setVisible(false)
                    .listen("clicked", nil);

                continue;
            }

            button.setText(airport.id)
                .setVisible(true)
                .listen("clicked", me._clickedCallback(airport.id));
        }
    },

    #
    # @param  string  icao
    # @return func
    #
    _clickedCallback: func(icao) {
        return func me._downloadMetarCallback.invoke(icao);
    },

    #
    # @return ghost  Canvas layout object with controls.
    #
    drawBottomBarForNearest: func {
        var buttonBox = canvas.HBoxLayout.new();

        buttonBox.addStretch(1);
        foreach (var btn; me._loadIcaoBtns.vector) {
            buttonBox.addItem(btn);
        }

        var label = me._widget.getLabel("ICAO:");

        me._icaoEdit = me._widget.getLineEdit(me._icao, 80, func(e) {
            me._downloadMetarCallback.invoke(e.detail.text);
        });

        var btnLoad = me._widget.getButton("Load", func {
            me._downloadMetarCallback.invoke(me._icaoEdit.text());
        });

        var holdUpdateCheckbox = me._widget.getCheckBox("Hold update", false, func(e) {
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
    drawBottomBarForScheduledTab: func {
        var buttonBox = canvas.HBoxLayout.new();

        var btnLoad = me._widget.getButton("Update METAR", func {
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
    drawBottomBarForAlternate: func {
        var buttonBox = canvas.HBoxLayout.new();

        buttonBox.addStretch(1);
        foreach (var btn; me._loadIcaoBtns.vector) {
            buttonBox.addItem(btn);
        }

        var label = me._widget.getLabel("ICAO:");

        me._icaoEdit = me._widget.getLineEdit(me._icao, 80, func(e) {
            me._downloadMetarCallback.invoke(e.detail.text);
        });

        var btnLoad = me._widget.getButton("Load", func {
            me._downloadMetarCallback.invoke(me._icaoEdit.text());
        });

        buttonBox.addStretch(1);
        buttonBox.addItem(label);
        buttonBox.addItem(me._icaoEdit);
        buttonBox.addItem(btnLoad);
        buttonBox.addStretch(1);

        return buttonBox;
    },
};
