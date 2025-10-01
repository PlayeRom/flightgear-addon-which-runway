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
# AircraftTypeFinder class.
#
var AircraftTypeFinder = {
    #
    # Constructor.
    #
    # @return hash
    #
    new: func() {
        var me = { parents: [AircraftTypeFinder] };

        me._tagsNode = props.globals.getNode("/sim/tags");

        me._tags = std.Vector.new();

        if (me._tagsNode != nil) {
            foreach (var tagNode; me._tagsNode.getChildren("tag")) {
                var tag = tagNode == nil ? nil : tagNode.getValue();
                if (tag != nil) {
                    me._tags.append(tag);
                }
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
        me._tags.clear();
    },

    #
    # Get aircraft type according to tags.
    #
    # @return string  RwyUse traffic type, it can be "com", "gen", "mil", "ul".
    #
    getType: func() {
        var type = me._getTypeByTags();
        if (type != nil) {
            return type;
        }

        type = me._getTypeByAcId();
        if (type != nil) {
            return type;
        }

        return g_Settings.getRwyUseAircraftType();
    },

    #
    # Get aircraft type according to tags
    #
    # @return string|nil
    #
    _getTypeByTags: func() {
        if (me._tagsNode == nil) {
            # No tags, nothing to check
            return nil;
        }

        if (me._hasTag("fighter", "interceptor", "combat", "bomber", "tanker", "carrier")) { # cargo, transport?
            return RwyUse.MILITARY;
        }

        if (me._hasTag("glider", "ultralight")) {
            return RwyUse.ULTRALIGHT;
        }

        if (me._hasTag("ga", "piston", "propeller", "balloon", "seaplane", "amphibious", "helicopter")) {
            return RwyUse.GENERAL;
        }

        return nil;
    },

    #
    # Check is aircraft has given tags.
    #
    # @param  string  tags  List of strings.
    # @return bool  Return true if found.
    #
    _hasTag: func(tags...) {
        foreach (var tag; tags) {
            if (me._tags.contains(tag)) {
                Log.print("found aircraft tag: \"", tag, "\"");
                return true;
            }
        }

        return false;
    },

    #
    # Type assignment based on aircraft name.
    #
    # @return string|nil
    #
    _getTypeByAcId: func() {
        var aircraftId = me._getAircraftId();

        if (substr(aircraftId, 0, 5) == "ask21" # ask21, ask21mi, ask21-jsb, ask21mi-jsb
            or aircraftId == "Perlan2"
            or aircraftId == "horsa"
            or aircraftId == "bocian"
            or aircraftId == "sportster"
        ) {
            return RwyUse.ULTRALIGHT;
        }

        if (aircraftId == "alphaelectro") {
            return RwyUse.GENERAL;
        }

        # TODO: add more here...

        return nil;
    },

    #
    # Get the exact aircraft name as its unique ID (variant).
    #
    # @return string
    #
    _getAircraftId: func() {
        # When "/sim/aircraft" exists, this property contains the correct ID.
        # This is a case that can occur when an aircraft has multiple variants.
        var aircraft = me._removeHangarName(getprop("/sim/aircraft"));
        return aircraft == nil
            ? me._removeHangarName(getprop("/sim/aircraft-id"))
            : aircraft;
    },

    #
    # Remove hangar name from aircraft ID.
    #
    # @param  string|nil  aircraft  Aircraft ID probably with hangar name.
    # @return string|nil  Aircraft ID without hangar name.
    #
    _removeHangarName: func(aircraft) {
        if (aircraft == nil) {
            return nil;
        }

        var aircraftLength = size(aircraft);

        # Known hangars
        var hangarPatterns = [
            "org.flightgear.fgaddon.stable_????.*",
            "org.flightgear.fgaddon.trunk.*",
            "de.djgummikuh.hangar.octal450.*",
            "de.djgummikuh.hangar.fgmembers.*",
            "de.djgummikuh.hangar.oprf.*",
            "de.djgummikuh.hangar.*",
            "com.gitlab.fg_shfsn.hangar.*",
            "www.daveshangar.org.*",
            "www.seahorsecorral.org.*",
        ];

        foreach (var pattern; hangarPatterns) {
            if (string.match(aircraft, pattern)) {
                var urlLength = size(pattern) - 1; # minus 1 for not count `*` char
                return substr(aircraft, urlLength, aircraftLength - urlLength);
            }
        }

        # We're still not trim, so try to trim to the last dot (assumed that aircraft ID cannot has dot char)
        for (var i = aircraftLength - 1; i >= 0; i -= 1) {
            if (aircraft[i] == `.`) {
                return substr(aircraft, i + 1, aircraftLength - i);
            }
        }

        return aircraft;
    },
};
