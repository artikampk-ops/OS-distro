// The desktop a new user starts with: one taskbar along the bottom, with Start
// and the pinned apps in the middle and the tray and clock on the right.

var panel = new Panel
panel.location = "bottom"
panel.height = 44
panel.hiding = "none"
// Flush with the screen edge, where the scripting API of this Plasma allows.
try { panel.floating = false } catch (error) {}
try { panel.lengthMode = "fill" } catch (error) {}

panel.addWidget("org.kde.plasma.panelspacer")

var start = panel.addWidget("org.kde.plasma.kickoff")
start.currentConfigGroup = ["General"]
start.writeConfig("icon", "/usr/share/eleven/start.svg")

var tasks = panel.addWidget("org.kde.plasma.icontasks")
tasks.currentConfigGroup = ["General"]
tasks.writeConfig("launchers", [
  "applications:org.kde.dolphin.desktop",
  "applications:brave-browser.desktop",
  "applications:artika-browser.desktop",
  "applications:org.kde.discover.desktop"
].join(","))

panel.addWidget("org.kde.plasma.panelspacer")
panel.addWidget("org.kde.plasma.systemtray")

var clock = panel.addWidget("org.kde.plasma.digitalclock")
clock.currentConfigGroup = ["Appearance"]
clock.writeConfig("showDate", true)
clock.writeConfig("dateDisplayFormat", "BelowTime")

panel.addWidget("org.kde.plasma.showdesktop")

var allDesktops = desktops()
for (var i = 0; i < allDesktops.length; i++) {
  var desktop = allDesktops[i]
  desktop.wallpaperPlugin = "org.kde.image"
  desktop.currentConfigGroup = ["Wallpaper", "org.kde.image", "General"]
  desktop.writeConfig("Image", "file:///usr/share/eleven/wallpaper.jpg")
}
