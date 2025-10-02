#
# Which Runway - Add-on for FlightGear
#
# Written and developer by Roman Ludwicki (PlayeRom, SP-ROM)
#
# Copyright (C) 2025 Roman Ludwicki
#
# Which Runway is an Open Source project and it is licensed
# under the GNU Public License v3 (GPLv3)
#

#
# SettingsDialog class to display about info
#
var SettingsDialog = {
    CLASS: "SettingsDialog",

    #
    # Constants
    #
    WINDOW_WIDTH  : 400,
    WINDOW_HEIGHT : 150,
    PADDING       : 10,

    #
    # Constructor
    #
    # @return hash
    #
    new: func() {
        var me = {
            parents: [
                SettingsDialog,
                PersistentDialog.new(
                    SettingsDialog.WINDOW_WIDTH,
                    SettingsDialog.WINDOW_HEIGHT,
                    "Settings Which Runway",
                ),
            ],
        };

        me._parentDialog = me.parents[1];
        me._parentDialog.setChild(me, SettingsDialog); # Let the parent know who their child is.
        me._parentDialog.setPositionOnCenter();

        me._maxMetarRangeNm = g_Settings.getMaxMetarRangeNm();
        me._rwyUseEnable = g_Settings.getRwyUseEnabled();

        me._rangeComboBox = nil;
        me._checkboxRwyUse = nil;

        me._vbox.addSpacing(SettingsDialog.PADDING);
        me._drawContent();

        var buttonBoxClose = me._drawBottomBar();
        me._vbox.addSpacing(SettingsDialog.PADDING);
        me._vbox.addItem(buttonBoxClose);
        me._vbox.addSpacing(SettingsDialog.PADDING);

        return me;
    },

    #
    # Destructor
    #
    # @return void
    # @override PersistentDialog
    #
    del: func() {
        me._parentDialog.del();
    },

    #
    # @return void
    # @override PersistentDialog
    #
    show: func() {
        me._maxMetarRangeNm = g_Settings.getMaxMetarRangeNm();
        me._rwyUseEnable = g_Settings.getRwyUseEnabled();

        me._rangeComboBox.setSelectedByValue(me._maxMetarRangeNm);
        me._checkboxRwyUse.setChecked(me._rwyUseEnable);

        me._parentDialog.show();
    },

    #
    # Draw content.
    #
    # @return void
    #
    _drawContent: func() {
        me._vbox.addItem(me._drawNearestMetarRange());
        me._vbox.addItem(me._drawEnableRwyUse());
        me._vbox.addStretch(1);
    },

    #
    # @return ghost  Canvas box layout.
    #
    _drawNearestMetarRange: func() {
        var label = me._getLabel("Max range for nearest METAR in NM:");

        var items = [
            { label: "20",  value:  20 },
            { label: "30",  value:  30 }, # default
            { label: "50",  value:  50 },
            { label: "80",  value:  80 },
            { label: "120", value: 120 },
            { label: "200", value: 200 },
        ];

        me._rangeComboBox = ComboBoxHelper.create(me._group, items, 100, 28);
        me._rangeComboBox.setSelectedByValue(me._maxMetarRangeNm);
        me._rangeComboBox.listen("selected-item-changed", func(e) {
            me._maxMetarRangeNm = e.detail.value;
        });

        var hBox = canvas.HBoxLayout.new();

        hBox.addSpacing(SettingsDialog.PADDING);
        hBox.addItem(label);
        hBox.addItem(me._rangeComboBox);
        hBox.addSpacing(SettingsDialog.PADDING);
        hBox.addStretch(1);

        return hBox;
    },

    #
    # @return ghost  Canvas box layout.
    #
    _drawEnableRwyUse: func() {
        me._checkboxRwyUse = canvas.gui.widgets.CheckBox.new(me._group)
            .setText("Preferred runways at the airport")
            .setChecked(me._rwyUseEnable)
            .listen("toggled", func(e) {
                me._rwyUseEnable = e.detail.checked ? true : false; # conversion on true/false is needed ¯\_(ツ)_/¯
            });

        var hBox = canvas.HBoxLayout.new();

        hBox.addSpacing(SettingsDialog.PADDING);
        hBox.addItem(me._checkboxRwyUse);
        hBox.addSpacing(SettingsDialog.PADDING);
        hBox.addStretch(1);

        return hBox;
    },

    #
    # @param  string  text  Label text.
    # @param  bool  wordWrap  If true then text will be wrapped.
    # @return ghost  Label widget.
    #
    _getLabel: func(text, wordWrap = false) {
        var label = canvas.gui.widgets.Label.new(parent: me._group, cfg: { wordWrap: wordWrap })
            .setText(text);

        return label;
    },

    #
    # @param  string  text  Label of button.
    # @param  func  callback  Function which will be executed after click the button.
    # @return ghost  Button widget.
    #
    _getButton: func(text, callback) {
        return canvas.gui.widgets.Button.new(me._group)
            .setText(text)
            .setFixedSize(75, 26)
            .listen("clicked", callback);
    },

    #
    # @return ghost  HBoxLayout object with button
    #
    _drawBottomBar: func() {
        var hBox = canvas.HBoxLayout.new();

        var saveButton = me._getButton("Save", func me._save());

        var closeButton =  me._getButton("Cancel", func me.hide());

        hBox.addStretch(1);
        hBox.addItem(saveButton);
        hBox.addItem(closeButton);
        hBox.addStretch(1);

        return hBox;
    },

    #
    # Save values to properties and hide dialog.
    #
    # @return void
    #
    _save: func() {
        g_Settings.setMaxMetarRangeNm(me._maxMetarRangeNm);
        g_Settings.setRwyUseEnabled(me._rwyUseEnable);

        me.hide();
    },
};
