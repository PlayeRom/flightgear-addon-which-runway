#
# Which Runway - Add-on for FlightGear
#
# Written and developer by Roman Ludwicki (PlayeRom, SP-ROM)
#
# Copyright (C) 2024 Roman Ludwicki
#
# RwyUseInfo widget is an Open Source project and it is licensed
# under the GNU Public License v3 (GPLv3)
#

#
# RwyUseInfo widget Model
#
gui.widgets.RwyUseInfo = {
    _CLASS: "RwyUseInfo",

    #
    # Constructor.
    #
    # @param  ghost  parent
    # @param  hash|nil  style
    # @param  hash|nil  cfg
    # @return ghost
    #
    new: func(parent, style = nil, cfg = nil) {
        style = style or canvas.style;
        cfg = Config.new(cfg);
        var me = gui.Widget.new(gui.widgets.RwyUseInfo, cfg);
        me._focus_policy = me.NoFocus;
        me._setView(style.createWidget(parent, "rwy-use-info-view", me._cfg));

        me._valueMarginX = 145;
        me._utcTime = "00:00";
        me._maxTail = nil;
        me._maxCross = nil;
        me._traffic = nil;
        me._schedule = nil;
        me._dailyOperatingHours = nil;

        return me;
    },

    #
    # Set margin between label and value.
    #
    # @param  int  margin
    # @return hash
    #
    setMarginForValue: func(margin) {
        me._valueMarginX = margin;
        me._view.resetContentHeight(me);
        return me;
    },

    #
    # Set UTC time value.
    #
    # @param  string  time
    # @return hash
    #
    setUtcTime: func(time) {
        me._utcTime = time;
        return me;
    },

    #
    # @param  double  maxTail
    # @param  double  maxCross
    # @return ghost
    #
    setWindCriteria: func(maxTail, maxCross) {
        me._maxTail = maxTail;
        me._maxCross = maxCross;
        return me;
    },

    #
    # @param  string  traffic
    # @return ghost
    #
    setTraffic: func(traffic) {
        me._traffic = traffic;
        return me;
    },

    #
    # @param  string  schedule
    # @return ghost
    #
    setSchedule: func(schedule) {
        me._schedule = schedule;
        return me;
    },

    #
    # Set operation time for given traffic/aircraft type.
    #
    # @param  string|nil  opTime
    # @return ghost
    #
    setDailyOperatingHours: func(opTime) {
        me._dailyOperatingHours = opTime;
        return me;
    },

    #
    # Redraw view.
    #
    # @return void
    #
    updateView: func() {
        me._view.reDrawContent(me);
    },
};
