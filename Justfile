# Task runner for ovos-gui-visage (flutter + just)

default:
    @just --list

# Fetch dependencies
sync:
    flutter pub get

# Run the test suite
test:
    flutter test

# Format check and static analysis
lint:
    dart format --output=none --set-exit-if-changed --line-length 130 lib test tool
    flutter analyze --fatal-infos

# Format the code
fmt:
    dart format --line-length 130 lib test tool

# Run the app on macOS as an ordinary window (core bus 8181, GUI socket 18181)
run *ARGS:
    VISAGE_MODE=window flutter run -d macos {{ARGS}}

# Run the app on macOS as it ships: a desktop widget in the top-right corner
widget *ARGS:
    flutter run -d macos {{ARGS}}

# Add the Linux launcher and icons for this user, pointing at the release bundle (flutter build linux --release)
linux-install:
    tool/linux_desktop.sh install

# Remove the Linux launcher and icons for this user
linux-uninstall:
    tool/linux_desktop.sh uninstall

# Start the Linux app in kiosk mode when this user logs in: `just linux-autostart on` or `just linux-autostart off`
linux-autostart STATE:
    tool/linux_desktop.sh autostart-{{STATE}}

# Package the Linux release bundle as a .deb in build/release (on Debian or Ubuntu with dpkg-dev and chrpath)
linux-deb:
    tool/package_deb.sh
