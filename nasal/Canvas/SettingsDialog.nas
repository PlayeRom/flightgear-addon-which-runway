#
# Which Runway Add-on for FlightGear
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
                    height: 500,
                    title: "Settings Which Runway",
                ),
            ],
        };

        call(PersistentDialog.setChild, [obj, SettingsDialog], obj.parents[1]); # Let the parent know who their child is.
        call(PersistentDialog.setPositionOnCenter, [], obj.parents[1]);

        obj._widget = WidgetHelper.new(obj._group);

        obj._maxMetarRangeNm = g_Settings.getMaxMetarRangeNm();
        obj._rwyUseEnable = g_Settings.getRwyUseEnabled();
        obj._hwThreshold = g_Settings.getHwThreshold();
        obj._xwThreshold = g_Settings.getXwThreshold();

        obj._rangeComboBox = nil;
        obj._checkboxRwyUse = nil;
        obj._windSettingsWidget = canvas.gui.widgets.WindSettings.new(parent: obj._group, cfg: { colors: Colors })
            .setRadius(120);

        obj._hwLabel = obj._widget.getLabel(obj._printAngle(obj._hwThreshold));
        obj._xwLabel = obj._widget.getLabel(obj._printAngle(obj._xwThreshold));

        obj._vbox.addSpacing(me.PADDING);
        obj._drawContent();

        obj._vbox.addSpacing(me.PADDING);
        obj._vbox.addItem(obj._drawBottomBar());
        obj._vbox.addSpacing(me.PADDING);

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
        me._hwThreshold = g_Settings.getHwThreshold();
        me._xwThreshold = g_Settings.getXwThreshold();

        me._rangeComboBox.setSelectedByValue(me._maxMetarRangeNm);
        me._checkboxRwyUse.setChecked(me._rwyUseEnable);
        me._hwLabel.setText(me._printAngle(me._hwThreshold));
        me._xwLabel.setText(me._printAngle(me._xwThreshold));

        me._windSettingsWidget
            .setHwAngle(me._hwThreshold)
            .setXwAngle(me._xwThreshold)
            .updateView();

        call(PersistentDialog.show, [], me);
    },

    #
    # Draw content.
    #
    # @return void
    #
    _drawContent: func() {
        me._vbox.addItem(me._drawNearestMetarRange());
        me._vbox.addItem(me._widget.getHorizontalRule());
        me._vbox.addItem(me._drawEnableRwyUse());
        me._vbox.addItem(me._widget.getHorizontalRule());
        me._vbox.addItem(me._drawWindSettings());
        me._vbox.addItem(me._widget.getHorizontalRule());
        me._vbox.addStretch(1);
    },

    #
    # @return ghost  Canvas box layout.
    #
    _drawNearestMetarRange: func() {
        var label = me._widget.getLabel("Max range for nearest METAR in NM:");

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

        hBox.addSpacing(me.PADDING);
        hBox.addItem(label);
        hBox.addItem(me._rangeComboBox);
        hBox.addSpacing(me.PADDING);
        hBox.addStretch(1);

        return hBox;
    },

    #
    # @return ghost  Canvas box layout.
    #
    _drawEnableRwyUse: func() {
        me._checkboxRwyUse = me._widget.getCheckBox("Preferred runways at the airport", me._rwyUseEnable, func(e) {
            me._rwyUseEnable = e.detail.checked ? true : false; # conversion on true/false is needed ¯\_(ツ)_/¯
        });

        var hBox = canvas.HBoxLayout.new();

        hBox.addSpacing(me.PADDING);
        hBox.addItem(me._checkboxRwyUse);
        hBox.addSpacing(me.PADDING);
        hBox.addStretch(1);

        return hBox;
    },

    #
    # @return ghost  Canvas box layout.
    #
    _drawWindSettings: func() {
        var vBox = canvas.VBoxLayout.new();
        vBox.addSpacing(me.PADDING);
        vBox.addItem(me._widget.getLabel("Set thresholds for HW, XW and TW"));
        vBox.addItem(me._windSettingsWidget);
        vBox.addSpacing(me.PADDING);
        vBox.addItem(me._drawHwControls());
        vBox.addItem(me._drawXwControls());
        vBox.addSpacing(me.PADDING);
        vBox.addStretch(1);

        var hBox = canvas.HBoxLayout.new();
        hBox.addStretch(1);
        hBox.addItem(vBox);
        hBox.addStretch(1);

        return hBox;
    },

    #
    # @return ghost  Canvas box layout.
    #
    _drawHwControls: func() {
        var btnMinusBig   = me._getButtonSmall("<<", func me._setHwAngle(-5));
        var btnMinusSmall = me._getButtonSmall("<",  func me._setHwAngle(-1));
        var btnPlusSmall  = me._getButtonSmall(">",  func me._setHwAngle( 1));
        var btnPlusBig    = me._getButtonSmall(">>", func me._setHwAngle( 5));

        var btnDefault    = me._getButton("Default", func {
            me._hwThreshold = Metar.HEADWIND_THRESHOLD;
            me._xwThreshold = Metar.CROSSWIND_THRESHOLD;

            me._hwLabel.setText(me._printAngle(me._hwThreshold));
            me._xwLabel.setText(me._printAngle(me._xwThreshold));
            me._windSettingsWidget
                .setHwAngle(me._hwThreshold)
                .setXwAngle(me._xwThreshold)
                .updateView();
        });

        var hBox = canvas.HBoxLayout.new();

        hBox.addSpacing(me.PADDING);
        hBox.addItem(me._widget.getLabel("HW: "));
        hBox.addItem(btnMinusBig);
        hBox.addItem(btnMinusSmall);
        hBox.addItem(me._hwLabel);
        hBox.addItem(btnPlusSmall);
        hBox.addItem(btnPlusBig);
        hBox.addSpacing(me.PADDING);
        hBox.addItem(btnDefault);
        hBox.addStretch(1);

        return hBox;
    },

    #
    # @return ghost  Canvas box layout.
    #
    _drawXwControls: func() {
        var btnMinusBig   = me._getButtonSmall("<<", func me._setXwAngle(-5));
        var btnMinusSmall = me._getButtonSmall("<",  func me._setXwAngle(-1));
        var btnPlusSmall  = me._getButtonSmall(">",  func me._setXwAngle( 1));
        var btnPlusBig    = me._getButtonSmall(">>", func me._setXwAngle( 5));

        var hBox = canvas.HBoxLayout.new();

        hBox.addSpacing(me.PADDING);
        hBox.addItem(me._widget.getLabel("XW: "));
        hBox.addItem(btnMinusBig);
        hBox.addItem(btnMinusSmall);
        hBox.addItem(me._xwLabel);
        hBox.addItem(btnPlusSmall);
        hBox.addItem(btnPlusBig);
        hBox.addSpacing(me.PADDING);
        hBox.addStretch(1);

        return hBox;
    },

    #
    # @param  int  offset
    # @return void
    #
    _setHwAngle: func(offset) {
        me._hwThreshold += offset;

        if (me._hwThreshold < 1) {
            me._hwThreshold = 1;
        }

        if (me._hwThreshold >= me._xwThreshold - 1) {
            me._hwThreshold = me._xwThreshold - 1;
        }

        me._hwLabel.setText(me._printAngle(me._hwThreshold));
        me._windSettingsWidget.setHwAngle(me._hwThreshold).updateView();
    },

    #
    # @param  int  offset
    # @return void
    #
    _setXwAngle: func(offset) {
        me._xwThreshold += offset;

        if (me._xwThreshold <= me._hwThreshold + 1) {
            me._xwThreshold = me._hwThreshold + 1;
        }

        if (me._xwThreshold >= 179) {
            me._xwThreshold = 179
        }

        me._xwLabel.setText(me._printAngle(me._xwThreshold));
        me._windSettingsWidget.setXwAngle(me._xwThreshold).updateView();
    },

    #
    # @param  string  label  Label of button.
    # @param  func  callback  Function which will be executed after click the button.
    # @return ghost  Button widget.
    #
    _getButton: func(label, callback) {
        return me._widget.getButton(label, callback, 75);
    },

    #
    # @param  string  label  Label of button.
    # @param  func  callback  Function which will be executed after click the button.
    # @return ghost  Button widget.
    #
    _getButtonSmall: func(label, callback) {
        return me._widget.getButton(label, callback, 26);
    },

    #
    # @param  int  angle
    # @return string
    #
    _printAngle: func(angle) {
        return sprintf("%03d°", angle);
    },

    #
    # @return ghost  Canvas layout with buttons.
    #
    _drawBottomBar: func() {
        var hBox = canvas.HBoxLayout.new();

        var saveButton = me._getButton("Save", func me._save());
        var closeButton = me._getButton("Cancel", func me.hide());

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
        g_Settings.setHwThreshold(me._hwThreshold);
        g_Settings.setXwThreshold(me._xwThreshold);

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
        var hwThreshold = g_Settings.getHwThreshold();
        var xwThreshold = g_Settings.getXwThreshold();

        return me._maxMetarRangeNm != maxMetarRangeNm
            or me._rwyUseEnable != rwyUseEnable
            or me._hwThreshold != hwThreshold
            or me._xwThreshold != xwThreshold;
    },
};
