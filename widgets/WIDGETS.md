# Widgets

Versions are the ones installed when this setup was captured (Plasma 6.8.3). Newer versions often work, but Panel Colorizer needs a build that matches your Plasma.

## Bundled in this repo

| Folder | What it is | Licence |
|---|---|---|
| `org.wired.vitals` | Desktop vitals widget (mine) | GPL-2.0+ |
| `org.wired.snake` | Desktop snake game (mine) | GPL-2.0+ |
| `KdeControlStation-patched` | KDE Control Station 2.11.0 with fixes for Plasma 6.8 (`Kirigami.Units`, inhibitions guard, volume config fallbacks, preferredRepresentation) | GPLv3 |

`install.sh` copies these to `~/.local/share/plasma/plasmoids/`.

## Install yourself (not bundled)

Use "Add Widgets > Get New Widgets" or clone from the upstream link and install with
`kpackagetool6 -t Plasma/Applet -i <folder>` (use `-u` to upgrade).

| Plugin id | Name | Version | Upstream |
|---|---|---|---|
| `luisbocanegra.panel.colorizer` | Panel Colorizer | 8.1.0 | https://github.com/luisbocanegra/plasma-panel-colorizer |
| `AndromedaLauncher` | Andromeda Launcher | 0.6 | https://github.com/EliverLara/AndromedaLauncher |
| `net.netherizzium.chorus` | Chorus | 2.11.1 | https://github.com/Netherizzium/chorus |
| `com.gitlab.corral1976.relojlcd` | Reloj LCD Retro | 1.9.2 | https://store.kde.org/p/2363962 |
| `org.kde.netspeedWidget` | Netspeed Widget | 3.1 | https://github.com/dfaust/plasma-applet-netspeed-widget |
| `org.kde.plasma.catwalk` | CatWalk | 2.4 | KDE Store |
| `org.kde.latte.separator` | Latte Separator | 0.1.1 | https://github.com/psifidotos/applet-latte-separator |

Panel Colorizer also installs a QML plugin system-wide (`org/kde/plasma/panelcolorizer`). Follow its README for that step, or the panel will not load.

## Stock Plasma widgets used

Icons-only Task Manager, System Monitor (CPU, memory and sensor rings), Panel Spacer, Trash, Lock/Logout, System Tray and the tray items listed in the main README.
