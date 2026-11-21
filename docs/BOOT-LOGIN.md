# Login screen and bootloader

## SDDM: nier-automata

`boot-login/sddm/nier-automata/` holds the QML, `theme.conf` and `metadata.desktop`. The background video, image and fonts are not included.

1. Install the base theme (the "Qylock" nier-automata theme by Darkkal44) or create the folder yourself.
2. `./install.sh --sddm` copies the QML and `/etc/sddm.conf.d/10-nier.conf`.
3. Add your own `bg.mp4`, `bg.png` and a `font/` folder to `/usr/share/sddm/themes/nier-automata/`.
4. Test without logging out: `sddm-greeter-qt6 --test-mode --theme /usr/share/sddm/themes/nier-automata`.

`10-nier.conf` sets the theme to `nier-automata` and the cursor to `catppuccin-frappe-pink-cursors`.

## Limine

I boot through Limine on Fedora with Secure Boot on. The config is generated per machine, with partition UUIDs, machine ID and file hashes, so it is not published here.

What carries over is the look: a `wallpaper:` image and the `interface_branding` / colour options in `limine.conf`. Limine's own docs: https://github.com/Limine-Bootloader/Limine/blob/v12.x/CONFIG.md

Gotcha under Fedora's shim: Limine needs an `.sbat` section or shim refuses to load it ("Verification failed: Security Violation"). Add one with `objcopy --add-section .sbat=...` before signing.
