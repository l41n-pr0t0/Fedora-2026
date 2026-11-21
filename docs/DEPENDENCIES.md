# Dependencies

Install these before running `install.sh`. Package names are for Fedora; check with `dnf search` if one has moved.

## Theme parts

| Part | Notes |
|---|---|
| Darkly | Widget style and window decoration. https://github.com/Bali10050/Darkly (build from source or use a Fedora package/COPR if available) |
| Papirus icons | `sudo dnf install papirus-icon-theme`; folder colour: set to violet with `papirus-folders` |
| catppuccin-frappe-pink cursors | https://github.com/catppuccin/cursors, install to `~/.local/share/icons/` |
| Fonts | see [../packages/fonts.md](../packages/fonts.md) |

## KWin add-ons

| Part | Notes |
|---|---|
| Better Blur DX | Needs building against your KWin. Build tools: `cmake`, `extra-cmake-modules`, `kwin-devel`, Qt6/KF6 devel packages (see the project's README). Plasma 6.8 needs the latest upstream release |
| CoverSwitch2 | Install from KDE Store (Window Switcher + effect), by dcrey7 |
| Shader effects | Bundled in `kwin/effects/` |

## Wallpaper

Smart Video Wallpaper Reborn (`luisbocanegra.smart.video.wallpaper.reborn`): https://github.com/luisbocanegra/plasma-smart-video-wallpaper-reborn. It plays video through Qt Multimedia. If playback fails, install the multimedia codecs from RPM Fusion (`ffmpeg`, `gstreamer1-plugin-libav`).

## Widgets

See [../widgets/WIDGETS.md](../widgets/WIDGETS.md).

## Tools used by the scripts

`python3`, `bash`, `kpackagetool6`, optional `qdbus6` (reloads KWin after settings change).
