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
                    height: 630,
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
        obj._nearestType = g_Settings.getNearestType();

        obj._rangeComboBox = nil;
        obj._checkboxRwyUse = nil;
        obj._windSettingsWidget = canvas.gui.widgets.WindSettings.new(parent: obj._group, cfg: { colors: Colors })
            .setRadius(120);

        obj._hwLabel = obj._widget.getLabel(obj._printAngle(obj._hwThreshold));
        obj._xwLabel = obj._widget.getLabel(obj._printAngle(obj._xwThreshold));

        obj._radioNearTypeAirport = nil;
        obj._radioNearTypeHeliport = nil;
        obj._radioNearTypeSeaport = nil;

        obj._drawContent();

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
        me._nearestType = g_Settings.getNearestType();

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
        me._vbox.setContentsMargins(me.PADDING, me.PADDING, me.PADDING, me.PADDING);
        me._vbox.addItem(me._drawNearestMetarRange());
        me._vbox.addItem(me._widget.getHorizontalRule());
        me._vbox.addItem(me._drawEnableRwyUse());
        me._vbox.addItem(me._widget.getHorizontalRule());
        me._vbox.addItem(me._drawWindSettings());
        me._vbox.addItem(me._widget.getHorizontalRule());
        me._vbox.addItem(me._drawNearestType());
        me._vbox.addItem(me._widget.getHorizontalRule());
        me._vbox.addStretch(1);
        me._vbox.addItem(me._drawBottomBar());
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

        hBox.addItem(label);
        hBox.addItem(me._rangeComboBox);
        hBox.addStretch(1);

        return hBox;
    },

    #
    # @return ghost  Canvas checkbox widget.
    #
    _drawEnableRwyUse: func() {
        me._checkboxRwyUse = me._widget.getCheckBox("Preferred runways at the airport", me._rwyUseEnable, func(e) {
            me._rwyUseEnable = e.detail.checked ? true : false; # conversion on true/false is needed ¯\_(ツ)_/¯
        });

        return me._checkboxRwyUse;
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
    # Crate layout with radio buttons to select type of nearest landing sites.
    #
    # @return ghost  Return canvas layout.
    #
    _drawNearestType: func() {
        me._radioNearTypeAirport = me._widget.getRadioButton('Airport')
            .setChecked(me._nearestType == 'airport');

        me._radioNearTypeHeliport = me._widget.getRadioButton('Heliport', me._radioNearTypeAirport)
            .setChecked(me._nearestType == 'heliport');

        me._radioNearTypeSeaport = me._widget.getRadioButton('Seaport', me._radioNearTypeAirport)
            .setChecked(me._nearestType == 'seaport');

        me._radioNearTypeAirport.listen('group-checked-radio-changed', func(e) {
            var radioGroup = me._radioNearTypeAirport.getRadioButtonsGroup();

            # In the dev version of the FG, the getCheckedRadio() method has been changed to getCheckedRadioButton().
            # TODO: Remove the check and only use getCheckedRadioButton when version 2024 becomes obsolete.
            var checkedRadio = Utils.tryCatch(func typeof(radioGroup.getCheckedRadioButton))
                ? radioGroup.getCheckedRadioButton()
                : radioGroup.getCheckedRadio();

            #
            # @param  ghost  item
            # @return string
            #
            var getRadioValueByLabel = func(item) {
                if (item != nil) {
                    if (item._text == 'Heliport') return 'heliport';
                    if (item._text == 'Seaport')  return 'seaport';
                }

                return 'airport';
            };

            me._nearestType = getRadioValueByLabel(checkedRadio);
        });

        var vBox = canvas.VBoxLayout.new();
        vBox.addItem(me._widget.getLabel('Types of nearest landing sites'));
        vBox.addItem(me._radioNearTypeAirport);
        vBox.addItem(me._radioNearTypeHeliport);
        vBox.addItem(me._radioNearTypeSeaport);
        vBox.addStretch(1);

        return vBox;
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
        var isUpdateNearestAirportButtons = me._isUpdateNearestAirportButtons();

        g_Settings.setMaxMetarRangeNm(me._maxMetarRangeNm);
        g_Settings.setRwyUseEnabled(me._rwyUseEnable);
        g_Settings.setHwThreshold(me._hwThreshold);
        g_Settings.setXwThreshold(me._xwThreshold);
        g_Settings.setNearestType(me._nearestType);

        if (isNeedReload) {
            g_WhichRwyDialog.reloadAllTabs();
        }

        if (isUpdateNearestAirportButtons) {
            g_WhichRwyDialog.updateNearestAirportButtons();
        }

        me.hide();
    },

    #
    # Return true if WhichRwyDialog needs reload all tabs.
    #
    # @return bool
    #
    _isChangesNeedReload: func() {
        return me._maxMetarRangeNm != g_Settings.getMaxMetarRangeNm()
            or me._rwyUseEnable != g_Settings.getRwyUseEnabled()
            or me._hwThreshold != g_Settings.getHwThreshold()
            or me._xwThreshold != g_Settings.getXwThreshold();
    },

    #
    # Return true if WhichRwyDialog needs update nearest airport buttons.
    #
    # @return bool
    #
    _isUpdateNearestAirportButtons: func {
        return me._nearestType != g_Settings.getNearestType();
    },
};
