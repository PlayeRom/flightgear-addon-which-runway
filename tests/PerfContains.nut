#
# Which Runway Add-on for FlightGear
#
# Written and developer by Roman Ludwicki (PlayeRom, SP-ROM)
#
# Copyright (C) 2025 Roman Ludwicki
#
# This is an Open Source project and it is licensed
# under the GNU Public License v3 (GPLv3)
#

# Tests confirming that contains for a hash executes faster than for a vector.

var setUp = func {
    # Get add-on namespace:
    var namespace = globals['__addon[org.flightgear.addons.which-runway]__'];
};

var tearDown = func {
};

var test_contains10Items = func {
    var vector = [
        'transport',
        'douglas',
        '1990s',
        '2000s',
        'ifr',
        'retractable-gear',
        'glass-cockpit',
        'pressurised',
        'jet',
        '3-engine',
    ];

    var hash = {
        'transport':,
        'douglas':,
        '1990s':,
        '2000s':,
        'ifr':,
        'retractable-gear':,
        'glass-cockpit':,
        'pressurised':,
        'jet':,
        '3-engine':,
    };

    var items = [
        # contains
        'transport',
        'douglas',
        '1990s',
        '2000s',
        'ifr',

        # not contains
        'aerobatic',
        'trainer',
        'prototype',
        'turboprop',
        'twin-engine',
    ];

    namespace.Profiler.start('vector');
    foreach (var item; items) {
        contains(vector, item);
    }
    namespace.Profiler.stop();

    namespace.Profiler.start('hash');
    foreach (var item; items) {
        contains(hash, item);
    }
    namespace.Profiler.stop();

    unitTest.assert(true);
};

var test_contains60Items = func {
    var vector = [
        'transport',
        'douglas',
        '1990s',
        '2000s',
        'ifr',
        'retractable-gear',
        'glass-cockpit',
        'pressurised',
        'jet',
        '3-engine',
    ];

    var hash = {
        'transport':,
        'douglas':,
        '1990s':,
        '2000s':,
        'ifr':,
        'retractable-gear':,
        'glass-cockpit':,
        'pressurised':,
        'jet':,
        '3-engine':,
    };

    var items = [
        '3-engine',
        'jet',
        'pressurised',
        'glass-cockpit',
        'retractable-gear',
        'ifr',
        '2000s',
        '1990s',
        'douglas',
        'transport',

        'aerobatic',
        'trainer',
        'prototype',
        'turboprop',
        'twin-engine',
        'cargo',
        'naval',
        'stol',
        'experimental',
        'regional',

        '3-engine',
        'jet',
        'pressurised',
        'glass-cockpit',
        'retractable-gear',
        'ifr',
        '2000s',
        '1990s',
        'douglas',
        'transport',

        'aerobatic',
        'trainer',
        'prototype',
        'turboprop',
        'twin-engine',
        'cargo',
        'naval',
        'stol',
        'experimental',
        'regional',

        '3-engine',
        'jet',
        'pressurised',
        'glass-cockpit',
        'retractable-gear',
        'ifr',
        '2000s',
        '1990s',
        'douglas',
        'transport',

        'aerobatic',
        'trainer',
        'prototype',
        'turboprop',
        'twin-engine',
        'cargo',
        'naval',
        'stol',
        'experimental',
        'regional',
    ];

    namespace.Profiler.start('vector');
    foreach (var item; items) {
        contains(vector, item);
    }
    namespace.Profiler.stop();

    namespace.Profiler.start('hash');
    foreach (var item; items) {
        contains(hash, item);
    }
    namespace.Profiler.stop();

    unitTest.assert(true);
};
