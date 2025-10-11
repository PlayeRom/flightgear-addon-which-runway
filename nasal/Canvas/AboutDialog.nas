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
# AboutDialog class to display about info.
#
var AboutDialog = {
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
        var me = {
            parents: [
                AboutDialog,
                PersistentDialog.new(
                    width: 280,
                    height: 400,
                    title: "About Which Runway",
                ),
            ],
        };

        me._parentDialog = me.parents[1];
        me._parentDialog.setChild(me); # Let the parent know who their child is.
        me._parentDialog.setPositionOnCenter();

        me._createLayout();

        g_VersionChecker.registerCallback(Callback.new(me.newVersionAvailable, me));

        return me;
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
    # Create layout.
    #
    # @return void
    #
    _createLayout: func() {
        me._vbox.addSpacing(AboutDialog.PADDING);

        me._vbox.addItem(me._getLabel(g_Addon.name));
        me._vbox.addItem(me._getLabel(sprintf("version %s", g_Addon.version.str())));
        me._vbox.addItem(me._getLabel("October 4, 2025"));

        me._vbox.addStretch(1);
        me._vbox.addItem(me._getLabel("Written by:"));

        foreach (var author; g_Addon.authors) {
            me._vbox.addItem(me._getLabel(author.name));
        }

        me._vbox.addStretch(1);

        me._vbox.addItem(me._getButton("FlightGear Wiki", func {
            Utils.openBrowser({ url: g_Addon.homePage });
        }));

        me._vbox.addItem(me._getButton("GitHub Website", func {
            Utils.openBrowser({ url: g_Addon.codeRepositoryUrl });
        }));

        me._vbox.addStretch(1);

        me._createLayoutNewVersionInfo();

        me._vbox.addStretch(1);

        var buttonBoxClose = me._drawBottomBar("Close", func { me.hide(); });
        me._vbox.addSpacing(AboutDialog.PADDING);
        me._vbox.addItem(buttonBoxClose);
        me._vbox.addSpacing(AboutDialog.PADDING);
    },

    #
    # Create hidden layout for new version info.
    #
    # @return void
    #
    _createLayoutNewVersionInfo: func {
        me._newVersionAvailLabel = me._getLabel("New version is available").setVisible(false);
        me._newVersionAvailLabel.setColor([0.9, 0.0, 0.0]);

        me._newVersionAvailBtn = me._getButton("Download new version", func {
            Utils.openBrowser({ url: g_Addon.downloadUrl });
        }).setVisible(false);

        me._vbox.addItem(me._newVersionAvailLabel);
        me._vbox.addItem(me._newVersionAvailBtn);
    },

    #
    # @param  string  text  Label text.
    # @param  bool  wordWrap  If true then text will be wrapped.
    # @return ghost  Label widget.
    #
    _getLabel: func(text, wordWrap = false) {
        var label = canvas.gui.widgets.Label.new(parent: me._group, cfg: {wordWrap: wordWrap})
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
        return canvas.gui.widgets.Button.new(me._group)
            .setText(text)
            .setFixedSize(200, 26)
            .listen("clicked", callback);
    },

    #
    # @param  string  label  Label of button.
    # @param  func  callback  function which will be executed after click the button.
    # @return ghost  Canvas layout with buttons.
    #
    _drawBottomBar: func(label, callback) {
        var buttonBox = canvas.HBoxLayout.new();

        var btnClose = canvas.gui.widgets.Button.new(me._group)
            .setText(label)
            .setFixedSize(75, 26)
            .listen("clicked", callback);

        buttonBox.addStretch(1);
        buttonBox.addItem(btnClose);
        buttonBox.addStretch(1);

        return buttonBox;
    },

    #
    # Callback called when a new version of add-on is detected.
    #
    # @param  string  newVersion
    # @return void
    #
    newVersionAvailable: func(newVersion) {
        me._newVersionAvailLabel
            .setText(sprintf("New version %s is available", newVersion))
            .setVisible(true);

        me._newVersionAvailBtn
            .setVisible(true);
    },
};
