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
# FlightGear will save them to the autosave.xml file automatically by using userarchive="y" in addon-config.xml file.
#
var Settings = {
    #
    # Constructor.
    #
    # @return hash
    #
    new: func() {
        var obj = {
            parents: [Settings],
        };

        obj._addonNodePath = g_Addon.node.getPath();

        obj._maxMetarRangeNm    = props.globals.getNode(obj._addonNodePath ~ "/settings/max-metar-range-nm");
        obj._hwThreshold        = props.globals.getNode(obj._addonNodePath ~ "/settings/wind/threshold/hw");
        obj._xwThreshold        = props.globals.getNode(obj._addonNodePath ~ "/settings/wind/threshold/xw");
        obj._keyPageMoveSize    = props.globals.getNode(obj._addonNodePath ~ "/settings/keys/page-move-size");
        obj._rwyUseEnabled      = props.globals.getNode(obj._addonNodePath ~ "/settings/rwyuse/enabled");
        obj._rwyUseAircraftType = props.globals.getNode(obj._addonNodePath ~ "/settings/rwyuse/aircraft-type");

        return obj;
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
    # @return int  Range in NM.
    #
    getMaxMetarRangeNm: func() {
        return me._maxMetarRangeNm.getValue() or 30;
    },

    #
    # Set maximum search range of the nearest airport with METAR.
    #
    # @param  int  value  Range in NM.
    # @return void
    #
    setMaxMetarRangeNm: func(value) {
        me._maxMetarRangeNm.setIntValue(value);
    },

    #
    # Get headwind threshold angle.
    #
    # @return int  Headwind threshold angle.
    #
    getHwThreshold: func() {
        return me._hwThreshold.getValue() or Metar.HEADWIND_THRESHOLD;
    },

    #
    # Set headwind threshold angle.
    #
    # @param  int  value  Headwind threshold angle.
    # @return void
    #
    setHwThreshold: func(value) {
        me._hwThreshold.setIntValue(value);
    },

    #
    # Get crosswind threshold angle.
    #
    # @return int  Crosswind threshold angle.
    #
    getXwThreshold: func() {
        return me._xwThreshold.getValue() or Metar.CROSSWIND_THRESHOLD;
    },

    #
    # Set crosswind threshold angle.
    #
    # @param  int  value  Crosswind threshold angle.
    # @return void
    #
    setXwThreshold: func(value) {
        me._xwThreshold.setIntValue(value);
    },

    #
    # Check if rwyuse is enabled.
    #
    # @return bool
    #
    getRwyUseEnabled: func() {
        return me._rwyUseEnabled.getBoolValue();
    },

    #
    # Set rwyuse enable/disable.
    #
    # @param  bool
    # @return void
    #
    setRwyUseEnabled: func(value) {
        return me._rwyUseEnabled.setBoolValue(value);
    },

    #
    # Get default aircraft type for runway use.
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
