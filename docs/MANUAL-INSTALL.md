# Manual install

What `install.sh` does, step by step. Back up `~/.config` and `~/.local/share` first.

1. Colour schemes: copy `plasma/color-schemes/*.colors` to `~/.local/share/color-schemes/`, then pick LainWired in System Settings > Colours.
2. Look-and-feel: copy `plasma/look-and-feel/org.kde.nier-automata.desktop` to `~/.local/share/plasma/look-and-feel/`.
3. Widgets: copy `widgets/org.wired.snake`, `widgets/org.wired.vitals` and `widgets/KdeControlStation-patched` (rename it to `KdeControlStation`) to `~/.local/share/plasma/plasmoids/`.
4. KWin effects: copy every folder in `kwin/effects/` to `~/.local/share/kwin/effects/` and `kwin/scripts/open-browser-shortcut` to `~/.local/share/kwin/scripts/`. Enable them in System Settings > Desktop Effects and Window Management > KWin Scripts.
5. Settings: open `plasma/config/kdeglobals.excerpt` and `kwinrc.excerpt`. Copy the keys into `~/.config/kdeglobals` and `~/.config/kwinrc`, or merge them with `python3 -I tools/apply_ini.py <excerpt> <target>`. Reload KWin with `qdbus6 org.kde.KWin /KWin reconfigure`.
6. Shortcuts: `plasma/config/kglobalshortcutsrc` merges the same way into `~/.config/kglobalshortcutsrc`.
7. Layout (optional): from a TTY with plasmashell stopped, run
   `sed "s#@HOME@#$HOME#g" plasma/appletsrc.template > ~/.config/plasma-org.kde.plasma.desktop-appletsrc`
8. Log out and back in.
