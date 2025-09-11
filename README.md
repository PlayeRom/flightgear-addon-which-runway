
FlightGear "Which Runway" Add-on
================================

This add-on uses the METAR to indicate which runway is best for takeoff or landing. It also calculates headwind, crosswind and tailwind forces for the each runway of the airport.

## Installation

Installation is standard:

1. Download "Which Runway" add-on and unzip it.

2. In Launcher go to "Add-ons" tab. Click "Add" button by "Add-on Module folders" section and select folder with unzipped "Which Runway" add-on directory (or add command line option: `--addon=/path/to/which-runway`), and click "Fly!".

## Using

This add-on adds a "Which Runway" item to the main menu, from which you select "Runways". A dialog box will open with 4 tabs:

1. "Nearest" displays the nearest airport, which will be automatically updated during the flight. At the bottom, there's a field to enter the ICAO code of any other airport, but if you reach a different nearest airport, the data will always change to that nearest airport.
2. "Departure" show the airport selected as departure in Route Manager.
3. "Arrival" show the airport selected as arrival in Route Manager.
4. "Alternate" where at the bottom you can use input field for entering the ICAO code of any airport. This is the best place to enter any ICAO code because here the airport will never be changed by the program.

Each tab showing the airport information, METAR and runways and their winds. The runways are sorted by the one most directly into the headwind. The wind is always retrieved from the real METAR. The METAR will be updated automatically every 15 minutes or by "Load"/"Update METAR" buttons.

**NOTE**: to download and use METAR, this add-on requires the "Live Data" weather scenario to be enabled.

![alt which-runway](docs/which-runway.png "Which Runway main window")

## Authors

- Roman "PlayeRom" Ludwicki (SP-ROM)

## License

"Which Runway" is an Open Source project and it is licensed under the GNU Public License v3 (GPLv3).
