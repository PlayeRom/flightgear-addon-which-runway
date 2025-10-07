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
# Base class to check latest version from repository.
#
var VersionChecker = {
    #
    # Constructor.
    #
    # @return hash
    #
    new: func() {
        var me = {
            parents: [
                VersionChecker,
            ],
        };

        # Variables that must be set by the child's class by `setUrl` and `setDownloadCallback` methods:
        me._url = nil;
        me._downloadCallback = nil;

        # Variable that the child class must set in the `checkLastVersion` method when it retrieves the resource:
        me._downloadResource = nil;

        me._callbacks = std.Vector.new();
        me._newVersion = nil;

        return me;
    },

    #
    # Destructor.
    #
    # @return void
    #
    del: func() {
        me._callbacks.clear();
    },

    #
    # Set URL for download resource.
    #
    # @param  string  url
    # @return void
    #
    setUrl: func(url) {
        me._url = url;
    },

    #
    # Set download callback. This callback will be called after download resource.
    # The resource will be pass as parameter.
    #
    # @param  hash  callback  The Callback object.
    # @return void
    #
    setDownloadCallback: func(callback) {
        me._downloadCallback = callback;
    },

    #
    # Register callback, called when a new version is available.
    # The callback will receive a string with the new version as a parameter.
    #
    # @param  hash  callback  The Callback object.
    # @return void
    #
    registerCallback: func(callback) {
        me._callbacks.append(callback);
    },

    #
    # This is main method to download resource and should be override by child class,
    # which will implement a specific way of downloading a resource.
    #
    # @return void
    #
    checkLastVersion: func {
        Log.print("VersionChecker.checkLastVersion - override this method by child");
    },

    #
    # Return new version as string or nil id new version is not available.
    #
    # @return string|nil
    #
    getNewVersion: func {
        return me._newVersion;
    },

    #
    # Return true if new version is available.
    #
    # @return bool
    #
    isNewVersion: func {
        return me.getNewVersion() == nil ? false : true;
    },

    #
    # Get user and repository name from repository URL.
    # For it to work correctly, the URL must end with /user-name/repo-name, e.g.:
    # https://gitlab.com/user-name/repo-name
    #
    # @param  string  repositoryUrl  If not provided then addons.Addon.codeRepositoryUrl will be used.
    # @return vector  User and repository names or empty strings when failed.
    #
    getUserAndRepoNames: func(repositoryUrl = nil) {
        # remove "/" on the end if exists
        var repoUrl = string.trim(repositoryUrl or g_Addon.codeRepositoryUrl, 1, func(c) c == `/`);

        # remove "https://" on the front
        if (string.imatch(repoUrl, "https://*")) {
            repoUrl = substr(repoUrl, 8, size(repoUrl) - 8);
        }

        var parts = split("/", repoUrl);
        if (size(parts) < 3) {
            return ["", ""];
        }

        var user = parts[1]; # 0 is a domain, so 1 is a user name
        var repo = string.join("/", parts[1:]); # Repo can have subdirectories

        return [user, repo];
    },

    #
    # Invoke a callback function with the downloaded resource.
    #
    # @return void
    #
    _invokeDownloadCallback: func() {
        if (me._downloadCallback != nil) {
            me._downloadCallback.invoke(me._downloadResource);
        }
    },

    #
    # Compare the local version of the add-on with the one passed in the parameter.
    # If the passed version is greater than the local version, then invoke all
    # registered callbacks, passing them a string with the new version.
    #
    # @param  string  strLatestVersion
    # @return bool  Return true if new version is available.
    #
    checkVersion: func(strLatestVersion) {
        Log.print("The latest version found in the repository = ", strLatestVersion);

        var latestVersion = me._getLatestVersion(strLatestVersion);
        if (latestVersion == nil) {
            return false;
        }

        if (latestVersion.lowerThanOrEqual(g_Addon.version)) {
            return false;
        }

        me._newVersion = latestVersion.str();
        Log.alert("New version ", me._newVersion, " is available");

        # Inform registered callbacks about the new version:
        foreach (var callback; me._callbacks.vector) {
            callback.invoke(me._newVersion);
        }

        return true;
    },

    #
    # Convert string with version to the addons.AddonVersion object.
    #
    # @param  string  strVersion
    # @return ghost|nil  The addons.AddonVersion object or nil if failed.
    #
    _getLatestVersion: func(strVersion) {
        var strVersion = me._removeVPrefix(strVersion);

        var errors = [];
        var version = call(func addons.AddonVersion.new(strVersion), [], nil, nil, errors);

        if (size(errors)) {
            foreach (var error; errors) {
                Log.print(error);
            }

            return nil;
        }

        return version;
    },

    #
    # If string starts with "v", or "v.", remove this prefix.
    #
    # @param  string  strVersion
    # @return string  Version without "v." prefix.
    #
    _removeVPrefix: func(strVersion) {
        strVersion = string.trim(strVersion, -1, func(c) c == `v` or c == `V`);
        return string.trim(strVersion, -1, func(c) c == `.`);
    },
};
