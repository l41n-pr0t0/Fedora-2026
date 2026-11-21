#!/usr/bin/env bash
# Fedora-2026 desktop installer.
#
#   ./install.sh                 theme files, own widgets, KWin effects, settings (safe, no restart needed)
#   ./install.sh --layout        also replace the Plasma panel/widget layout (run from a TTY, see README)
#   ./install.sh --sddm          also install the SDDM login theme config (needs sudo)
#   ./install.sh --dry-run       print what would happen, change nothing
#
# Everything it overwrites is first copied to ~/.local/share/fedora-2026-backup/<timestamp>/
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP="$HOME/.local/share/fedora-2026-backup/$STAMP"
DRY=0; LAYOUT=0; SDDM=0
for a in "$@"; do
  case "$a" in
    --dry-run) DRY=1 ;;
    --layout)  LAYOUT=1 ;;
    --sddm)    SDDM=1 ;;
    -h|--help) sed -n '2,10p' "$0"; exit 0 ;;
    *) echo "unknown option: $a" >&2; exit 2 ;;
  esac
done

run() { if [ "$DRY" = 1 ]; then echo "[dry-run] $*"; else "$@"; fi; }
say() { printf '\033[1;35m::\033[0m %s\n' "$*"; }

backup() { # backup <path>
  [ -e "$1" ] || return 0
  run mkdir -p "$BACKUP$(dirname "$1")"
  run cp -a "$1" "$BACKUP$1"
}

copy_dir() { # copy_dir <src dir> <dest dir>
  backup "$2"
  run mkdir -p "$(dirname "$2")"
  run rm -rf "$2"
  run cp -a "$1" "$2"
}

command -v plasmashell >/dev/null || { echo "Plasma not found; this repo targets KDE Plasma 6." >&2; exit 1; }
PV="$(plasmashell --version 2>/dev/null | awk '{print $2}')"
say "Plasma $PV detected (tested on 6.8.3). Backups go to $BACKUP"

say "Colour schemes"
run mkdir -p "$HOME/.local/share/color-schemes"
for f in "$HERE"/plasma/color-schemes/*.colors; do
  backup "$HOME/.local/share/color-schemes/$(basename "$f")"
  run cp -a "$f" "$HOME/.local/share/color-schemes/"
done

say "Look-and-feel (NieR lock screen)"
copy_dir "$HERE/plasma/look-and-feel/org.kde.nier-automata.desktop" \
         "$HOME/.local/share/plasma/look-and-feel/org.kde.nier-automata.desktop"

say "Own widgets (Wired Snake, Wired Vitals, patched Control Station)"
copy_dir "$HERE/widgets/org.wired.snake"              "$HOME/.local/share/plasma/plasmoids/org.wired.snake"
copy_dir "$HERE/widgets/org.wired.vitals"             "$HOME/.local/share/plasma/plasmoids/org.wired.vitals"
copy_dir "$HERE/widgets/KdeControlStation-patched"    "$HOME/.local/share/plasma/plasmoids/KdeControlStation"

say "KWin shader effects + scripts"
for d in "$HERE"/kwin/effects/*; do copy_dir "$d" "$HOME/.local/share/kwin/effects/$(basename "$d")"; done
for d in "$HERE"/kwin/scripts/*; do copy_dir "$d" "$HOME/.local/share/kwin/scripts/$(basename "$d")"; done

say "Settings (merged key by key; your other settings are kept)"
for pair in "kdeglobals.excerpt:kdeglobals" "kwinrc.excerpt:kwinrc"; do
  src="$HERE/plasma/config/${pair%%:*}"; dst="$HOME/.config/${pair##*:}"
  backup "$dst"
  run python3 -I "$HERE/tools/apply_ini.py" "$src" "$dst"
done
backup "$HOME/.config/kglobalshortcutsrc"
run python3 -I "$HERE/tools/apply_ini.py" "$HERE/plasma/config/kglobalshortcutsrc" "$HOME/.config/kglobalshortcutsrc"

if [ "$LAYOUT" = 1 ]; then
  say "Panel + widget layout"
  if pgrep -x plasmashell >/dev/null && [ "$DRY" = 0 ]; then
    echo "plasmashell is running. It rewrites its config on exit and would undo this." >&2
    echo "Log out, switch to a TTY (Ctrl+Alt+F3), log in, run ./install.sh --layout, then log back in." >&2
    exit 1
  fi
  dst="$HOME/.config/plasma-org.kde.plasma.desktop-appletsrc"
  backup "$dst"
  if [ "$DRY" = 1 ]; then echo "[dry-run] sed @HOME@ -> $HOME > $dst"
  else sed "s#@HOME@#$HOME#g" "$HERE/plasma/appletsrc.template" > "$dst"; fi
fi

if [ "$SDDM" = 1 ]; then
  say "SDDM theme config (sudo)"
  run sudo install -d /usr/share/sddm/themes/nier-automata /etc/sddm.conf.d
  run sudo cp -a "$HERE"/boot-login/sddm/nier-automata/. /usr/share/sddm/themes/nier-automata/
  run sudo install -m 644 "$HERE/boot-login/sddm/10-nier.conf" /etc/sddm.conf.d/10-nier.conf
  echo "NOTE: add bg.mp4 / bg.png / font/ to /usr/share/sddm/themes/nier-automata (see docs/BOOT-LOGIN.md)."
fi

if [ "$DRY" = 0 ] && command -v qdbus6 >/dev/null; then qdbus6 org.kde.KWin /KWin reconfigure >/dev/null 2>&1 || true; fi

cat <<EOF

Done. Still manual (third-party, not bundled): see widgets/WIDGETS.md and docs/DEPENDENCIES.md
  - Panel Colorizer, Andromeda Launcher, Chorus, Reloj LCD, Netspeed, CatWalk, Latte Separator
  - Darkly, Papirus + violet folders, catppuccin-frappe-pink cursors, Better Blur DX, CoverSwitch2
  - Wallpapers (not bundled): place yours at ~/Pictures/Wallpapers/ (names in docs/WALLPAPER.md)
EOF
