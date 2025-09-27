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
# Settings class to set/get settings from property list.
#
var Settings = {
    #
    # Constructor.
    #
    # @return hash
    #
    new: func() {
        var me = {
            parents: [Settings],
        };

        me._addonNodePath = g_Addon.node.getPath();

        me._maxMetarRangeNm    = props.globals.getNode(me._addonNodePath ~ "/settings/max-metar-range-nm");
        me._keyArrowMoveSize   = props.globals.getNode(me._addonNodePath ~ "/settings/keys/arrow-move-size");
        me._keyPageMoveSize    = props.globals.getNode(me._addonNodePath ~ "/settings/keys/page-move-size");
        me._rwyUseEnabled      = props.globals.getNode(me._addonNodePath ~ "/settings/rwyuse/enabled");
        me._rwyUseAircraftType = props.globals.getNode(me._addonNodePath ~ "/settings/rwyuse/aircraft-type");

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
    # Get maximum search range of the nearest airport with METAR.
    #
    # @return int
    #
    getMaxMetarRangeNm: func() {
        return me._maxMetarRangeNm.getValue() or 30;
    },

    #
    # Get key arrow up/down move size.
    #
    # @return int
    #
    getKeyArrowMoveSize: func() {
        return me._keyArrowMoveSize.getValue() or 20;
    },

    #
    # Get key page up/down move size.
    #
    # @return int
    #
    getKeyPageMoveSize: func() {
        return me._keyPageMoveSize.getValue() or 110;
    },

    #
    # Check if runway use is enabled.
    #
    # @return bool
    #
    getRwyUseEnabled: func() {
        return me._rwyUseEnabled.getBoolValue();
    },

    #
    # Get aircraft type for runway use.
    #
    # @return string
    #
    getRwyUseAircraftType: func() {
        return me._rwyUseAircraftType.getValue() or RwyUse.COMMERCIAL;
    },

    #
    # Set aircraft type for runway use.
    #
    # @param  string  aircraftType  Aircraft type code.
    # @return void
    #
    setRwyUseAircraftType: func(aircraftType) {
        setprop(me._addonNodePath ~ "/settings/rwyuse/aircraft-type", aircraftType);
    },
};
