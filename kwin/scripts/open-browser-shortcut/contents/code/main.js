// Browser Shortcut (Meta+F)
registerShortcut("LaunchDefaultBrowser", "Launch Default Web Browser", "Meta+F", function() {
    callDBus("org.freedesktop.systemd1", "/org/freedesktop/systemd1", "org.freedesktop.systemd1.Manager", "StartUnit", "open-default-browser.service", "replace");
});
