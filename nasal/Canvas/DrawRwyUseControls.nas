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
    # Constructor.
    #
    # @param  string  tabId
    # @param  ghost  scrollContent
    # @param  hash  redrawCallback  Callback object.
    # @return hash
    #
    new: func(tabId, scrollContent, redrawCallback) {
        var me = {
            parents: [
                DrawRwyUseControls,
                DrawTabBase.new(tabId),
            ],
            _scrollContent: scrollContent,
            _redrawCallback: redrawCallback
        };

        me._isRwyUse = true;

        me._aircraftType = getprop(me._addonNodePath ~ "/settings/rwyuse/aircraft-type") or RwyUse.COMMERCIAL;
        me._aircraftOperation = me._getDefaultAircraftOperationByTabId();

        me._checkboxRwyUse = nil;
        me._comboBoxAircraftType = nil;
        me._labelAircraftType = nil;
        me._radioTakeoff = nil;
        me._radioLanding = nil;
        me._rwyUseInfoWidget = canvas.gui.widgets.RwyUseInfo.new(me._scrollContent, canvas.style, { colors: Colors })
            .setVisible(false);

        return me;
    },

    #
    # Destructor.
    #
    # @return void
    #
    del: func() {
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

        me._checkboxRwyUse = canvas.gui.widgets.CheckBox.new(me._scrollContent, canvas.style, {})
            .setText("Use preferred airport runways")
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

                me._redrawCallback.invoke();
            });

        var vBox = canvas.VBoxLayout.new();
        vBox.addItem(me._checkboxRwyUse);
        vBox.addItem(aircraftTypeLayout);
        vBox.addItem(takeOffLandingLayout);
        vBox.addStretch(1);

        return vBox;
    },

    #
    # Crate layout with combo box to select aircraft/traffic.
    #
    # #return ghost  Return canvas layout.
    #
    _creteRwyUseComboBoxAircraft: func() {
        me._labelAircraftType = canvas.gui.widgets.Label.new(me._scrollContent, canvas.style, {})
            .setText("Aircraft type:");

        me._comboBoxAircraftType = canvas.gui.widgets.ComboBox.new(me._scrollContent, canvas.style, {})
            .setFixedSize(160, 28);

        var items = [
            { label: "Commercial",       value: RwyUse.COMMERCIAL },
            { label: "General Aviation", value: RwyUse.GENERAL },
            { label: "Ultralight",       value: RwyUse.ULTRALIGHT },
            { label: "Military",         value: RwyUse.MILITARY },
        ];

        if (Utils.tryCatch(func { typeof(me._comboBoxAircraftType.createItem) == "func"; }, [])) {
            # For next addMenuItem is deprecated
            foreach (var item; items) {
                me._comboBoxAircraftType.createItem(item.label, item.value);
            }
        }
        else { # for 2024.1
            foreach (var item; items) {
                me._comboBoxAircraftType.addMenuItem(item.label, item.value);
            }
        }

        me._comboBoxAircraftType.setSelectedByValue(me._aircraftType);
        me._comboBoxAircraftType.listen("selected-item-changed", func(e) {
            # This setprop will trigger listener for every tab to change aircraft type and redraw:
            setprop(me._addonNodePath ~ "/settings/rwyuse/aircraft-type", e.detail.value);
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
    # #return string
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
            var checkedRadio = Utils.tryCatch(func { typeof(radioGroup.getCheckedRadioButton) == "func"; }, [])
                ? radioGroup.getCheckedRadioButton()
                : radioGroup.getCheckedRadio();

            var getRadioValueByLabel = func(item) {
                if (item != nil) {
                       if (item._text == "Takeoff") return RwyUse.TAKEOFF;
                    elsif (item._text == "Landing") return RwyUse.LANDING;
                }

                return me._getDefaultAircraftOperationByTabId();
            };

            me._aircraftOperation = getRadioValueByLabel(checkedRadio);
            me._redrawCallback.invoke();
        });

        var hBox = canvas.HBoxLayout.new();
        hBox.addItem(me._radioTakeoff);
        hBox.addItem(me._radioLanding);
        hBox.addStretch(1);

        return hBox;
    },

    #
    # Get widgets.RadioButton
    #
    # @param  string  text  Label text
    # @param  hash|nil  cfg  Config hash or nil
    # @return ghost  widgets.RadioButton
    #
    _getRadioButton: func(text, cfg = nil) {
        return canvas.gui.widgets.RadioButton.new(me._scrollContent, canvas.style, cfg)
            .setText(text);
    },
};
