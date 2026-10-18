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
