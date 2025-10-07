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
# A class to check if there is a new version of an add-on based on releases and
# tags when the add-on is hosted on GitHub.
# See description of VersionChecker class.
#
var GitHubVersionChecker = {
    #
    # Constructor.
    #
    # @return hash
    #
    new: func() {
        var me =  {
            parents: [
                GitHubVersionChecker,
                JsonVersionChecker.new(),
            ],
        };

        me.setUrl(me._getUrl());
        me.setDownloadCallback(Callback.new(me._downloadCallback, me));

        return me;
    },

    #
    # Get URL to latest release of the project.
    #
    # @return string
    #
    _getUrl: func() {
        var (user, repo) = me.getUserAndRepoNames();
        return sprintf("https://api.github.com/repos/%s/%s/releases/latest", user, repo);
    },

    #
    # @param  string  downloadedResource  Downloaded text from HTTP request.
    # @return void
    #
    _downloadCallback: func(downloadedResource) {
        var json = me.parseJson(downloadedResource);
        if (json == nil or !ishash(json)) {
            return;
        }

        # GitHub returns a single object with the latest release, where we find the `tag_name` field.
        if (!contains(json, "tag_name")) {
            Log.print("GitHubVersionChecker failed, the JSON doesn't contain `tag_name` key.");
            return;
        }

        var strLatestVersion = json["tag_name"];
        if (strLatestVersion == nil) {
            return;
        }

        me.checkVersion(strLatestVersion);
    },
};
