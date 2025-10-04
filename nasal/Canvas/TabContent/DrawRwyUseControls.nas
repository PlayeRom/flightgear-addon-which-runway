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
# Draw controls for rwyuse for DrawTabContent.
#
var DrawRwyUseControls = {
    #
    # Constants:
    #
    MIN_INTERVAL: 10,

    #
    # Constructor.
    #
    # @param  string  tabId
    # @param  ghost  scrollContent
    # @param  hash  redrawCallback  Callback object.
    # @param  string  aircraftType  As "com", "gen", "mil, "ul".
    # @return hash
    #
    new: func(tabId, scrollContent, redrawCallback, aircraftType) {
        var me = {
            parents: [
                DrawRwyUseControls,
                DrawTabBase.new(tabId),
            ],
            _scrollContent: scrollContent,
            _redrawCallback: redrawCallback,
            _aircraftType: aircraftType,
        };

        me._isRwyUse = true;

        me._aircraftOperation = me._getDefaultAircraftOperationByTabId();

        me._checkboxRwyUse = nil;
        me._comboBoxAircraftType = nil;
        me._labelAircraftType = nil;
        me._radioTakeoff = nil;
        me._radioLanding = nil;
        me._labelCurrentUtcTime = nil;
        me._labelCurrentUtcTimeValue = nil;
        me._labelUtcTimeCtrl = nil;
        me._labelUtcHour = nil;
        me._labelUtcMinute = nil;
        me._btnUtcHourMinus = nil;
        me._btnUtcHourPlus = nil;
        me._btnUtcMinuteMinus = nil;
        me._btnUtcMinutePlus = nil;

        me._currentUtcTime = "00:00";
        me._utcHourNode   = props.globals.getNode("/sim/time/utc/hour");
        me._utcMinuteNode = props.globals.getNode("/sim/time/utc/minute");

        me._utcHourValue   = 0;
        me._utcMinuteValue = 0;
        me._setUtcTimeToCurrentValue();

        me._rwyUseInfoWidget = canvas.gui.widgets.RwyUseInfo.new(parent: me._scrollContent, cfg: { colors: Colors })
            .setVisible(false);

        me._listeners = Listeners.new();

        me._listeners.add(
            node: "/sim/time/utc/minute",
            code: func() { me._updateCurrentUtcTime(); },
            init: false,
            type: Listeners.ON_CHANGE_ONLY,
        );

        return me;
    },

    #
    # Destructor.
    #
    # @return void
    #
    del: func() {
        me._listeners.del();

        call(DrawTabBase.del, [], me);
    },

    #
    # Return true if checkbox is selected.
    #
    # @return bool
    #
    isRwyUse: func() {
        return me._isRwyUse;
    },

    #
    # @return void
    #
    setUtcTimeToCurrent: func() {
        me._setUtcTimeToCurrentValue();

        me._labelUtcHour.setText(me._getPrintTimeFormat(me._utcHourValue));
        me._labelUtcMinute.setText(me._getPrintTimeFormat(me._utcMinuteValue));
    },

    #
    # Get aircraft/traffic type by rwyuse.xml code.
    #
    # @return string
    #
    getAircraftType: func()  {
        return me._aircraftType;
    },

    #
    # Get aircraft/traffic type by rwyuse.xml code.
    #
    # @param  string  acType  Aircraft/traffic type by rwyuse.xml code.
    # @return void
    #
    setAircraftType: func(acType)  {
        me._aircraftType = acType;
        me._comboBoxAircraftType.setSelectedByValue(me._aircraftType);
    },

    #
    # Return true if "Takeoff" is selected in radio buttons.
    #
    # @return bool
    #
    isTakeoff: func() {
        return me._aircraftOperation == RwyUse.TAKEOFF;
    },

    #
    # Return canvas widget to select aircraft/traffic type.
    #
    # @return ghost
    #
    getComboBoxAircraftType: func() {
        return me._comboBoxAircraftType;
    },

    #
    # Return canvas widget with information from rwyuse.xml.
    #
    # @return ghost
    #
    getRwyUseInfoWidget: func() {
        return me._rwyUseInfoWidget;
    },

    #
    # @return int  Set hour in UTC time.
    #
    getScheduleUtcHour: func() {
        return me._utcHourValue;
    },

    #
    # @return int  Set minute in UTC time.
    #
    getScheduleUtcMinute: func() {
        return me._utcMinuteValue;
    },

    #
    # Crate whole layout to control rwyuse.
    #
    # #return ghost  Return canvas layout.
    #
    createRwyUseLayout: func() {
        var vBox = canvas.VBoxLayout.new();
        vBox.addItem(me._rwyUseInfoWidget);
        vBox.addStretch(1);

        var hBox = canvas.HBoxLayout.new();
        hBox.addItem(me._createRwyUseLayoutCtrl());
        hBox.addSpacing(50);
        hBox.addItem(vBox);
        hBox.addStretch(1);

        return hBox;
    },

    #
    # Crate layout with control of rwyuse.
    #
    # #return ghost  Return canvas layout.
    #
    _createRwyUseLayoutCtrl: func() {
        var aircraftTypeLayout = me._creteRwyUseComboBoxAircraft();
        var takeOffLandingLayout = me._creteRwyUseRadioBtnsTakeoffLanding();

        me._checkboxRwyUse = canvas.gui.widgets.CheckBox.new(me._scrollContent)
            .setText("Use the preferred runways at the airport")
            .setChecked(me._isRwyUse)
            .listen("toggled", func(e) {
                # I don't why but convert to true/false is important for me._rwyUseInfoWidget.setVisible()
                me._isRwyUse = e.detail.checked ? true : false;

                me._labelAircraftType.setEnabled(me._isRwyUse);
                me._comboBoxAircraftType.setEnabled(me._isRwyUse);

                if (me._isTabNearest() or me._isTabAlternate()) {
                    me._radioTakeoff.setEnabled(me._isRwyUse);
                    me._radioLanding.setEnabled(me._isRwyUse);
                } else {
                    me._radioTakeoff.setEnabled(false);
                    me._radioLanding.setEnabled(false);
                }

                me._labelCurrentUtcTime.setEnabled(me._isRwyUse);
                me._labelCurrentUtcTimeValue.setEnabled(me._isRwyUse);

                me._labelUtcTimeCtrl.setEnabled(me._isRwyUse);
                me._labelUtcHour.setEnabled(me._isRwyUse);
                me._labelUtcMinute.setEnabled(me._isRwyUse);
                me._btnUtcHourMinus.setEnabled(me._isRwyUse);
                me._btnUtcHourPlus.setEnabled(me._isRwyUse);
                me._btnUtcMinuteMinus.setEnabled(me._isRwyUse);
                me._btnUtcMinutePlus.setEnabled(me._isRwyUse);

                me._redrawCallback.invoke(false);
            });

        var vBox = canvas.VBoxLayout.new();
        vBox.addItem(me._checkboxRwyUse);
        vBox.addItem(aircraftTypeLayout);
        vBox.addItem(takeOffLandingLayout);
        vBox.addItem(me._createCurrentUtcTimeLayout());
        vBox.addItem(me._createUtcTimeControlLayout());
        vBox.addStretch(1);

        return vBox;
    },

    #
    # Crate layout with combo box to select aircraft/traffic.
    #
    # #return ghost  Return canvas layout.
    #
    _creteRwyUseComboBoxAircraft: func() {
        me._labelAircraftType = me._getLabel("Aircraft type:");

        var items = [
            { label: "Commercial",       value: RwyUse.COMMERCIAL },
            { label: "General Aviation", value: RwyUse.GENERAL },
            { label: "Ultralight",       value: RwyUse.ULTRALIGHT },
            { label: "Military",         value: RwyUse.MILITARY },
        ];

        me._comboBoxAircraftType = ComboBoxHelper.create(me._scrollContent, items, 160, 28);
        me._comboBoxAircraftType.setSelectedByValue(me._aircraftType);
        me._comboBoxAircraftType.listen("selected-item-changed", func(e) {
            # This setprop will trigger listener for every tab to change aircraft type and redraw:
            g_Settings.setRwyUseAircraftType(e.detail.value);
        });

        var hBox = canvas.HBoxLayout.new();
        hBox.addItem(me._labelAircraftType);
        hBox.addItem(me._comboBoxAircraftType);
        hBox.addStretch(1);

        return hBox;
    },

    #
    # Get default aircraft operation (takeoff or landing) according do tab ID.
    #
    # #return int
    #
    _getDefaultAircraftOperationByTabId: func() {
           if (me._isTabNearest())   return RwyUse.LANDING;
        elsif (me._isTabDeparture()) return RwyUse.TAKEOFF;
        elsif (me._isTabArrival())   return RwyUse.LANDING;
        elsif (me._isTabAlternate()) return RwyUse.LANDING;

        return RwyUse.TAKEOFF;
    },

    #
    # Crate layout with with radio buttons to select takeoff or landing.
    #
    # #return ghost  Return canvas layout.
    #
    _creteRwyUseRadioBtnsTakeoffLanding: func() {
        me._radioTakeoff = me._getRadioButton("Takeoff")
            .setChecked(me._aircraftOperation == RwyUse.TAKEOFF);

        me._radioLanding = me._getRadioButton("Landing", { "parent-radio": me._radioTakeoff })
            .setChecked(me._aircraftOperation == RwyUse.LANDING);

        if (me._isTabDeparture() or me._isTabArrival()) {
            me._radioTakeoff.setEnabled(false);
            me._radioLanding.setEnabled(false);
        }

        me._radioTakeoff.listen("group-checked-radio-changed", func(e) {
            var radioGroup = me._radioTakeoff.getRadioButtonsGroup();

            # In the dev version of the FG, the getCheckedRadio() method has been changed to getCheckedRadioButton().
            # TODO: Remove the check and only use getCheckedRadioButton when version 2024 becomes obsolete.
            var checkedRadio = Utils.tryCatch(func typeof(radioGroup.getCheckedRadioButton), [])
                ? radioGroup.getCheckedRadioButton()
                : radioGroup.getCheckedRadio();

            #
            # @param  ghost  item
            # @return int
            #
            var getRadioValueByLabel = func(item) {
                if (item != nil) {
                       if (item._text == "Takeoff") return RwyUse.TAKEOFF;
                    elsif (item._text == "Landing") return RwyUse.LANDING;
                }

                return me._getDefaultAircraftOperationByTabId();
            };

            me._aircraftOperation = getRadioValueByLabel(checkedRadio);
            me._redrawCallback.invoke(false);
        });

        var hBox = canvas.HBoxLayout.new();
        hBox.addItem(me._radioTakeoff);
        hBox.addItem(me._radioLanding);
        hBox.addStretch(1);

        return hBox;
    },

    #
    # Get RadioButton widget.
    #
    # @param  string  text  Label text.
    # @param  hash|nil  cfg  Config hash or nil.
    # @return ghost  RadioButton widget.
    #
    _getRadioButton: func(text, cfg = nil) {
        return canvas.gui.widgets.RadioButton.new(parent: me._scrollContent, cfg: cfg)
            .setText(text);
    },

    #
    # Get Label widget.
    #
    # @param  string  text
    # @return ghost  Label widget.
    #
    _getLabel: func(text) {
        return canvas.gui.widgets.Label.new(me._scrollContent)
            .setText(text);
    },

    #
    # Get Button widget.
    #
    # @param  string  text  Label of button.
    # @param  func  callback  Function which will be executed after click the button.
    # @return ghost  Button widget.
    #
    _getButton: func(text, callback, height = 28) {
        return canvas.gui.widgets.Button.new(me._scrollContent)
            .setText(text)
            .setFixedSize(height, 28)
            .listen("clicked", callback);
    },

    #
    # @return ghost  Canvas layout.
    #
    _createCurrentUtcTimeLayout: func() {
        me._labelCurrentUtcTime = me._getLabel("Current UTC time:");

        me._labelCurrentUtcTimeValue = me._getLabel(me._currentUtcTime);
        me._updateCurrentUtcTime();

        var hBox = canvas.HBoxLayout.new();
        hBox.addItem(me._labelCurrentUtcTime);
        hBox.addItem(me._labelCurrentUtcTimeValue);
        hBox.addStretch(1);

        return hBox;
    },

    #
    # @return ghost  Canvas layout.
    #
    _createUtcTimeControlLayout: func() {
        me._labelUtcTimeCtrl = me._getLabel("Schedule UTC time:");

        me._labelUtcHour = me._getLabel(me._getPrintTimeFormat(me._utcHourValue));
        me._labelUtcMinute = me._getLabel(me._getPrintTimeFormat(me._utcMinuteValue));

        me._btnUtcHourMinus = me._getButton("-", func() {
            me._minuHour();
            me._redrawCallback.invoke(false);
        });

        me._btnUtcHourPlus = me._getButton("+", func() {
            me._plusHour();
            me._redrawCallback.invoke(false);
        });

        me._btnUtcMinuteMinus = me._getButton("-", func() {
            me._utcMinuteValue -= DrawRwyUseControls.MIN_INTERVAL;
            if (me._utcMinuteValue < 0) {
                me._utcMinuteValue = 60 - DrawRwyUseControls.MIN_INTERVAL;

                me._minuHour();
            }

            me._labelUtcMinute.setText(me._getPrintTimeFormat(me._utcMinuteValue));
            me._redrawCallback.invoke(false);
        });

        me._btnUtcMinutePlus = me._getButton("+", func() {
            me._utcMinuteValue += DrawRwyUseControls.MIN_INTERVAL;
            if (me._utcMinuteValue >= 60) {
                me._utcMinuteValue = 0;

                me._plusHour();
            }

            me._labelUtcMinute.setText(me._getPrintTimeFormat(me._utcMinuteValue));
            me._redrawCallback.invoke(false);
        });

        var hBox = canvas.HBoxLayout.new();
        hBox.addItem(me._labelUtcTimeCtrl);
        hBox.addItem(me._btnUtcHourMinus);
        hBox.addItem(me._labelUtcHour);
        hBox.addItem(me._btnUtcHourPlus);
        hBox.addItem(me._btnUtcMinuteMinus);
        hBox.addItem(me._labelUtcMinute);
        hBox.addItem(me._btnUtcMinutePlus);
        hBox.addStretch(1);

        return hBox;
    },

    #
    # @return void
    #
    _minuHour: func() {
        me._utcHourValue -= 1;
        if (me._utcHourValue <= -1) {
            me._utcHourValue = 23;
        }

        me._labelUtcHour.setText(me._getPrintTimeFormat(me._utcHourValue));
    },

    #
    # @return void
    #
    _plusHour: func() {
        me._utcHourValue += 1;
        if (me._utcHourValue >= 24) {
            me._utcHourValue = 0;
        }

        me._labelUtcHour.setText(me._getPrintTimeFormat(me._utcHourValue));
    },

    #
    # @return void
    #
    _updateCurrentUtcTime: func() {
        if (me._labelCurrentUtcTimeValue == nil) {
            return;
        }

        var hour   = me._utcHourNode.getValue();
        var minute = me._utcMinuteNode.getValue();
        me._labelCurrentUtcTimeValue.setText(sprintf("%02d:%02d", hour, minute));
    },

    #
    # @param  int  value
    # @return string
    #
    _getPrintTimeFormat: func(value) {
        return sprintf("%02d", value);
    },

    #
    # @return value
    #
    _setUtcTimeToCurrentValue: func() {
        me._utcHourValue = me._utcHourNode.getValue();

        var minute = math.ceil(me._utcMinuteNode.getValue() / DrawRwyUseControls.MIN_INTERVAL) * DrawRwyUseControls.MIN_INTERVAL;
        if (minute == 60) {
            minute = 0;

            me._utcHourValue += 1;
            if (me._utcHourValue >= 24) {
                me._utcHourValue = 0;
            }
        }

        me._utcMinuteValue = minute;
    },
};
