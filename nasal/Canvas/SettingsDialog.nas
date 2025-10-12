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
# SettingsDialog class.
#
var SettingsDialog = {
    #
    # Constants:
    #
    PADDING: 10,

    #
    # Constructor.
    #
    # @return hash
    #
    new: func() {
        var obj = {
            parents: [
                SettingsDialog,
                PersistentDialog.new(
                    width: 400,
                    height: 150,
                    title: "Settings Which Runway",
                ),
            ],
        };

        call(PersistentDialog.setChild, [obj, SettingsDialog], obj.parents[1]); # Let the parent know who their child is.
        call(PersistentDialog.setPositionOnCenter, [], obj.parents[1]);

        obj._maxMetarRangeNm = g_Settings.getMaxMetarRangeNm();
        obj._rwyUseEnable = g_Settings.getRwyUseEnabled();

        obj._rangeComboBox = nil;
        obj._checkboxRwyUse = nil;

        obj._vbox.addSpacing(SettingsDialog.PADDING);
        obj._drawContent();

        var buttonBoxClose = obj._drawBottomBar();
        obj._vbox.addSpacing(SettingsDialog.PADDING);
        obj._vbox.addItem(buttonBoxClose);
        obj._vbox.addSpacing(SettingsDialog.PADDING);

        return obj;
    },

    #
    # Destructor.
    #
    # @return void
    # @override PersistentDialog
    #
    del: func() {
        call(PersistentDialog.del, [], me);
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

        call(PersistentDialog.show, [], me);
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
    # @return ghost  Canvas layout with buttons.
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
        var isNeedReload = me._isChangesNeedReload();

        g_Settings.setMaxMetarRangeNm(me._maxMetarRangeNm);
        g_Settings.setRwyUseEnabled(me._rwyUseEnable);

        if (isNeedReload) {
            g_WhichRwyDialog.reloadAllTabs();
        }

        me.hide();
    },

    #
    # Return true if WhichRwyDialog needs reload all tabs.
    #
    # @return bool
    #
    _isChangesNeedReload: func() {
        var maxMetarRangeNm = g_Settings.getMaxMetarRangeNm();
        var rwyUseEnable    = g_Settings.getRwyUseEnabled();

        return me._maxMetarRangeNm != maxMetarRangeNm
            or me._rwyUseEnable != rwyUseEnable;
    },
};
