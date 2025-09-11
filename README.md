
FlightGear "Which Runway" Add-on
================================

This add-on uses the METAR to indicate which runway is best for takeoff or landing. It also calculates headwind, crosswind and tailwind forces for the each runway of the airport.

## Installation

Installation is standard:

1. Download "Which Runway" add-on and unzip it.

2. In Launcher go to "Add-ons" tab. Click "Add" button by "Add-on Module folders" section and select folder with unzipped "Which Runway" add-on directory (or add command line option: `--addon=/path/to/which-runway`), and click "Fly!".

## Using

This add-on adds a "Which Runway" item to the main menu, from which you select "Runways". A dialog box will open showing the runways and their winds. The runways are sorted by the one most directly into the headwind. By default, the runways are retrieved from the nearest airport. The wind is always retrieved from the real METAR.

At the bottom, there's an input field for entering the ICAO code of any other airport, allowing you to also check the runway for your destination airport.

![alt main-window](docs/which-runway.png "Wich Runway main window")

## Authors

- Roman "PlayeRom" Ludwicki (SP-ROM)

## License

Logbook is an Open Source project and it is licensed under the GNU Public License v3 (GPLv3).
