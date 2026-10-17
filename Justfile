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

# Run the app on macOS (core bus 8181, GUI socket 18181)
run *ARGS:
    flutter run -d macos {{ARGS}}
