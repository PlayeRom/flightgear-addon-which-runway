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
# The class provides QNH pressure and wind data when using Basic Weather with Manual Configuration.
# In this case, weather data is not retrieved from the METAR but from "Manual Configuration" dialog.
#
var BasicWeather = {
    #
    # Constructor.
    #
    # @return hash
    #
    new: func() {
        var me = { parents: [BasicWeather] };

        me._localWeatherEnabledNode = props.globals.getNode("/nasal/local_weather/enabled");

        # False means enabled "Manual Configuration" for Basic Weather:
        me._metarUpdatesEnvNode = props.globals.getNode("/environment/params/metar-updates-environment");

        me._boundaryCfgNode = props.globals.getNode("/environment/config/boundary");
        me._qnhCfgNode      = props.globals.getNode("/environment/config/boundary/entry[0]/pressure-sea-level-inhg");

        me._windDir = nil;
        me._windKt  = 0;

        # Timers to reduce calls to several listeners to the same action.
        me._wxChangeTimer = Timer.make(1, me, me._wxChangeTimerCallback);
        me._manCfgListenersTimer = Timer.make(1, me, me._manCfgListenersTimerCallback);

        me._engineWxChangeCallback = std.Vector.new();
        me._wxChangeCallback = std.Vector.new();

        me._manCfgListeners = Listeners.new();
        me._listeners = Listeners.new();
        me._setListeners();

        if (me.isBasicWxManCfgEnabled()) {
            me._calculateWindAt0Agl();
        }

        return me;
    },

    #
    # Destructor.
    #
    # @return void
    #
    del: func() {
        me._wxChangeTimer.stop();
        me._manCfgListenersTimer.stop();

        me._listeners.del();
        me._manCfgListeners.del();

        me._engineWxChangeCallback.clear();
        me._wxChangeCallback.clear();
    },

    #
    # Return true if Basic Weather is enabled with Manual Configuration, which means that METAR is not used.
    #
    # @return bool
    #
    isBasicWxManCfgEnabled: func() {
        return !me._localWeatherEnabledNode.getBoolValue() and !me._metarUpdatesEnvNode.getBoolValue();
    },

    #
    # Get wind direction at airport elevation.
    #
    # @return double
    #
    getWindDir: func() {
        return me._windDir;
    },

    #
    # Get wind speed at airport elevation.
    #
    # @return double
    #
    getWindKt: func() {
        return me._windKt;
    },

    #
    # Get QNH entered in manual configuration.
    #
    # @return double
    #
    getQnh: func() {
        return me._qnhCfgNode.getValue();
    },

    #
    # @param  hash  callback  Callback object.
    # @return void
    #
    registerEngineWxChangeCallback: func(callback) {
        me._engineWxChangeCallback.append(callback);
    },

    #
    # @param  hash  callback  Callback object.
    # @return void
    #
    registerWxChangeCallback: func(callback) {
        me._wxChangeCallback.append(callback);
    },

    #
    # Invoice all registered callback for weather change.
    #
    # @return void
    #
    _invokeWxChangeCallbacks: func() {
        foreach (var callback; me._wxChangeCallback.vector) {
            callback.invoke();
        }
    },

    #
    # Set listeners.
    #
    # @return void
    #
    _setListeners: func() {
        # Redraw canvas if weather engine has been changed.
        me._listeners.add(
            node: me._localWeatherEnabledNode,
            code: func(node) {
                if (me.isBasicWxManCfgEnabled()) {
                    me._calculateWindAt0Agl();
                }

                foreach (var callback; me._engineWxChangeCallback.vector) {
                    callback.invoke();
                }

                if (!me._manCfgListenersTimer.isRunning) {
                    me._manCfgListenersTimer.start();
                }
            },
            init: false,
            type: Listeners.ON_CHANGE_ONLY,
        );

        # Redraw canvas if Manual Config for Basic Weather has benn enabled/disabled.
        me._listeners.add(
            node: me._metarUpdatesEnvNode,
            code: func(node) {
                if (me.isBasicWxManCfgEnabled()) {
                    me._calculateWindAt0Agl();
                }

                me._invokeWxChangeCallbacks();

                if (!me._manCfgListenersTimer.isRunning) {
                    me._manCfgListenersTimer.start();
                }
            },
            init: false,
            type: Listeners.ON_CHANGE_ONLY,
        );

        if (me.isBasicWxManCfgEnabled()) {
            me._addListenersForManualConfig();
        }
    },

    #
    # Add listeners for check value changes for all needed information.
    #
    # @return void
    #
    _addListenersForManualConfig: func() {
        me._addListenersForBoundaryLayers();

        me._manCfgListeners.add(
            node: me._qnhCfgNode,
            code: func(node) {
                if (me.isBasicWxManCfgEnabled() and !me._wxChangeTimer.isRunning) {
                    me._wxChangeTimer.start();
                }
            },
            init: false,
            type: Listeners.ON_CHANGE_ONLY,
        );
    },

    #
    # Add listeners for check value changes for elevation, wind direction and wind speed for boundary layers
    # in manual configuration.
    #
    # @return void
    #
    _addListenersForBoundaryLayers: func() {
        foreach (var layer; me._boundaryCfgNode.getChildren("entry")) {
            if (layer == nil) {
                continue;
            }

            var elevation = layer.getChild("elevation-ft");
            var windDir   = layer.getChild("wind-from-heading-deg");
            var windKt    = layer.getChild("wind-speed-kt");

            me._manCfgListeners.add(
                node: elevation,
                code: func(node) {
                    if (me.isBasicWxManCfgEnabled() and !me._wxChangeTimer.isRunning) {
                        me._wxChangeTimer.start();
                    }
                },
                init: false,
                type: Listeners.ON_CHANGE_ONLY,
            );

            me._manCfgListeners.add(
                node: windDir,
                code: func(node) {
                    if (me.isBasicWxManCfgEnabled() and !me._wxChangeTimer.isRunning) {
                        me._wxChangeTimer.start();
                    }
                },
                init: false,
                type: Listeners.ON_CHANGE_ONLY,
            );

            me._manCfgListeners.add(
                node: windKt,
                code: func(node) {
                    if (me.isBasicWxManCfgEnabled() and !me._wxChangeTimer.isRunning) {
                        me._wxChangeTimer.start();
                    }
                },
                init: false,
                type: Listeners.ON_CHANGE_ONLY,
            );
        }
    },

    #
    # Timer callback called when weather data have been changed in manual configuration.
    #
    # @return void.
    #
    _wxChangeTimerCallback: func() {
        if (me.isBasicWxManCfgEnabled()) {
            me._calculateWindAt0Agl();
        }

        me._invokeWxChangeCallbacks();
        me._wxChangeTimer.stop();
    },

    #
    # Timer callback called when using manual config has been enabled/disabled.
    #
    # @return void.
    #
    _manCfgListenersTimerCallback: func() {
        me._handleManCfgListeners();
        me._manCfgListenersTimer.stop();
    },

    #
    # Add or remove listeners for weather data from manual configuration.
    # If we do not use manual configuration, but only data from METAR, then listeners are unnecessary.
    #
    # @return void.
    #
    _handleManCfgListeners: func() {
        if (me.isBasicWxManCfgEnabled()) {
            if (me._manCfgListeners.size() > 0) {
                return; # already added
            }

            me._addListenersForManualConfig();
            return;
        }

        # Delete listeners for Basic Weather
        me._manCfgListeners.clear();
    },

    #
    # For Basic Weather with Manual Config, calculate wind using boundary layers (with elevation as AGL ft)
    # where airport is always at 0 ft AGL.
    # These calculations are needed because the user can change the elevation of the lowest layer to a negative value.
    # Otherwise, reading the wind values from the lowest layer would be sufficient.
    # To check the accuracy of the results, standing on the runway, compare them to the values ​​calculated by FG:
    # /environment/wind-from-heading-deg and /environment/wind-speed-kt.
    # So why not simply read these values ​​instead of calculating them yourself? Since these are values ​​for the
    # aircraft's altitude, they will change during flight, and we are always interested in the ground level at the airport.
    #
    # @return void
    #
    _calculateWindAt0Agl: func() {
        var airportElevation = 0; # For boundary layers the airport has elevation at 0 ft

        var layers = me._getBoundaryLayers();

        var layersSize = globals.size(layers);
        if (layersSize == 0) {
            return;
        }

        # Clamp airport elevation to the layer range
        var minAlt = layers[0].elevation;
        var maxAlt = layers[layersSize - 1].elevation;
        var clampedElevation = math.max(minAlt, math.min(airportElevation, maxAlt));

        # Find the lower and upper layers for interpolation
        var lower = nil;
        var upper = nil;

        for (var i = 0; i < layersSize - 1; i += 1) {
            var a = layers[i];
            var b = layers[i + 1];
            if (clampedElevation >= a.elevation and clampedElevation <= b.elevation) {
                lower = a;
                upper = b;
                break;
            }
        }

        if (lower == nil or upper == nil) {
            return; # Should never happen if layers are sorted correctly
        }

        # Linear interpolation ratio
        var denom = upper.elevation - lower.elevation;
        var ratio = denom == 0
            ? 0
            : (clampedElevation - lower.elevation) / denom;

        # Interpolate wind speed
        me._windKt = lower.windKt + (upper.windKt - lower.windKt) * ratio;

        # Interpolate wind direction using shortest path
        var delta = geo.normdeg180(upper.windDir - lower.windDir);
        me._windDir = geo.normdeg(lower.windDir + delta * ratio);
    },

    #
    # Get data like elevation, wind dir and wind speed, from boundary layers in manual configuration.
    #
    # @return vector  Vector of hashes.
    #
    _getBoundaryLayers: func() {
        var layers = [];

        foreach (var layer; me._boundaryCfgNode.getChildren("entry")) {
            if (layer == nil) {
                continue;
            }

            globals.append(layers, {
                elevation: layer.getChild("elevation-ft").getValue(),
                windDir  : layer.getChild("wind-from-heading-deg").getValue(),
                windKt   : layer.getChild("wind-speed-kt").getValue(),
            });
        }


        return me._sortLayers(layers);
    },

    #
    # Sort ascending by elevation, because the user may mix up elevations by entering different values.
    #
    # @param  vector  layers
    # @return vector  Sorted layers by elevation.
    #
    _sortLayers: func(layers) {
        return globals.sort(layers, func(a, b) {
              if (a.elevation > b.elevation) return  1;
           elsif (a.elevation < b.elevation) return -1;

           return 0;
        });
    },
};
