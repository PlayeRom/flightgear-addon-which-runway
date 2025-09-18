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
# BottomBar class
#
var BottomBar = {
    #
    # Constructor
    #
    # @param  ghost  tabsContent  Tabs canvas content.
    # @param  bool  withIcaoBtns  If true then buttons with nearest ICOAs will be added.
    # @param  func  downloadMetarCallback  Function to run download METAR.
    # @param  hash  downloadMetarSelf  Owner class of downloadMetarCallback.
    # @return hash
    #
    new: func(tabsContent, withIcaoBtns, downloadMetarCallback, downloadMetarOwner) {
        var me = { parents: [BottomBar] };

        me._tabsContent = tabsContent;
        me._icaoEdit = nil;
        me._downloadMetarCallback = downloadMetarCallback;
        me._downloadMetarOwner = downloadMetarOwner;
        me._icao = "";

        if (withIcaoBtns) {
            me._btnLoadIcaos = std.Vector.new();
            for (var i = 0; i < 5; i += 1) {
                var btn = canvas.gui.widgets.Button.new(me._tabsContent, canvas.style, {})
                    .setText("----");

                me._btnLoadIcaos.append(btn);
            }
        }

        return me;
    },

    #
    # Destructor.
    #
    # @return void
    #
    del: func() {
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
    # Update buttons with nearest airports.
    #
    # @return void
    #
    updateNearestAirportButtons: func() {
        var airports = globals.findAirportsWithinRange(50); # range in NM
        var airportSize = size(airports);

        forindex (var index; me._btnLoadIcaos.vector) {
            var airport = index < airportSize ? airports[index] : nil;

            if (airport == nil) {
                me._btnLoadIcaos.vector[index]
                    .setText("----")
                    .setVisible(false)
                    .listen("clicked", nil);
            } else {
                func() {
                    var icao = airport.id;

                    me._btnLoadIcaos.vector[index]
                        .setText(icao)
                        .setVisible(true)
                        .listen("clicked", func() {
                            call(me._downloadMetarCallback, [icao], me._downloadMetarOwner);
                        });
                }();
            }
        }
    },

    #
    # @return ghost  Canvas layout object with controls.
    #
    drawBottomBarForNearest: func() {
        var buttonBox = canvas.HBoxLayout.new();

        buttonBox.addStretch(1);
        foreach (var btn; me._btnLoadIcaos.vector) {
            buttonBox.addItem(btn);
        }

        var label = canvas.gui.widgets.Label.new(me._tabsContent, canvas.style, {})
            .setText("ICAO:");

        me._icaoEdit = canvas.gui.widgets.LineEdit.new(me._tabsContent, canvas.style, {})
            .setText(me._icao)
            .setFixedSize(80, 26)
            .listen("editingFinished", func(e) {
                call(me._downloadMetarCallback, [e.detail.text], me._downloadMetarOwner);
            });

        var btnLoad = me._getButton("Load", func() {
            call(me._downloadMetarCallback, [me._icaoEdit.text()], me._downloadMetarOwner);
        });

        var holdUpdateCheckbox = canvas.gui.widgets.CheckBox.new(me._tabsContent, canvas.style, { wordWrap: false })
            .setText("Hold update")
            .setChecked(false)
            .listen("toggled", func(e) {
                me._isHoldUpdateNearest = e.detail.checked;

                if (!me._isHoldUpdateNearest) {
                    # If the option is unchecked, immediately update the airport
                    # with the nearest one if it has changed from the current one.
                    var newIcao = getprop("/sim/airport/closest-airport-id");
                    if (newIcao != me._icao) {
                        call(me._downloadMetarCallback, [newIcao], me._downloadMetarOwner);
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
            call(me._downloadMetarCallback, [me._icao], me._downloadMetarOwner);
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
        foreach (var btn; me._btnLoadIcaos.vector) {
            buttonBox.addItem(btn);
        }

        var label = canvas.gui.widgets.Label.new(me._tabsContent, canvas.style, {})
            .setText("ICAO:");

        me._icaoEdit = canvas.gui.widgets.LineEdit.new(me._tabsContent, canvas.style, {})
            .setText(me._icao)
            .setFixedSize(80, 26)
            .listen("editingFinished", func(e) {
                call(me._downloadMetarCallback, [e.detail.text], me._downloadMetarOwner);
            });

        var btnLoad = me._getButton("Load", func() {
            call(me._downloadMetarCallback, [me._icaoEdit.text()], me._downloadMetarOwner);
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
        return canvas.gui.widgets.Button.new(me._tabsContent, canvas.style, {})
            .setText(text)
            .listen("clicked", callback);
    },
};
