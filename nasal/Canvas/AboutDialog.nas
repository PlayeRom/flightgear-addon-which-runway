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
# AboutDialog class to display about info
#
var AboutDialog = {
    #
    # Constants
    #
    WINDOW_WIDTH  : 280,
    WINDOW_HEIGHT : 400,
    PADDING       : 10,

    #
    # Constructor
    #
    # @return me
    #
    new: func() {
        var me = { parents: [
            AboutDialog,
            Dialog.new(AboutDialog.WINDOW_WIDTH, AboutDialog.WINDOW_HEIGHT, "About Which Runway"),
        ] };

        me.setPositionOnCenter();

        me.vbox.addSpacing(AboutDialog.PADDING);
        me._drawContent();

        var buttonBoxClose = me._drawBottomBar("Close", func { me.window.hide(); });
        me.vbox.addSpacing(AboutDialog.PADDING);
        me.vbox.addItem(buttonBoxClose);
        me.vbox.addSpacing(AboutDialog.PADDING);

        return me;
    },

    #
    # Destructor
    #
    # @return void
    #
    del: func() {
        call(Dialog.del, [], me);
    },

    #
    # Draw content.
    #
    # @return void
    #
    _drawContent: func() {
        me.vbox.addItem(me._getLabel(g_Addon.name));
        me.vbox.addItem(me._getLabel(sprintf("version %s", g_Addon.version.str())));
        me.vbox.addItem(me._getLabel("September 12, 2025"));

        me.vbox.addStretch(1);
        me.vbox.addItem(me._getLabel("Written by:"));

        foreach (var author; g_Addon.authors) {
            me.vbox.addItem(me._getLabel(Utils.toString(author.name)));
        }

        me.vbox.addStretch(1);

        me.vbox.addItem(me._getButton("FlightGear wiki...", func {
            Utils.openBrowser({ "url": g_Addon.homePage });
        }));

        me.vbox.addItem(me._getButton("GitHub website...", func {
            Utils.openBrowser({ "url": g_Addon.codeRepositoryUrl });
        }));

        me.vbox.addStretch(1);
    },

    #
    # @param  string  text  Label text.
    # @param  bool  wordWrap  If true then text will be wrapped.
    # @return ghost  Label widget.
    #
    _getLabel: func(text, wordWrap = 0) {
        var label = canvas.gui.widgets.Label.new(me.group, canvas.style, {wordWrap: wordWrap})
            .setText(text);

        label.setTextAlign("center");

        return label;
    },

    #
    # @param  string  text  Label of button.
    # @param  func  callback  Function which will be executed after click the button.
    # @return ghost  Button widget.
    #
    _getButton: func(text, callback) {
        return canvas.gui.widgets.Button.new(me.group, canvas.style, {})
            .setText(text)
            .setFixedSize(200, 26)
            .listen("clicked", callback);
    },

    #
    # @param  string  label  Label of button
    # @param  func  callback  function which will be executed after click the button
    # @return ghost  HBoxLayout object with button
    #
    _drawBottomBar: func(label, callback) {
        var buttonBox = canvas.HBoxLayout.new();

        var btnClose = canvas.gui.widgets.Button.new(me.group, canvas.style, {})
            .setText(label)
            .setFixedSize(75, 26)
            .listen("clicked", callback);

        buttonBox.addStretch(1);
        buttonBox.addItem(btnClose);
        buttonBox.addStretch(1);

        return buttonBox;
    },
};
