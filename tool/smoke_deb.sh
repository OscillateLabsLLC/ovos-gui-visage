#!/usr/bin/env bash
# Installs a .deb from tool/package_deb.sh with plain apt (Recommends too, as a user's apt does), starts the app
# under Xvfb with a session bus, then removes it.
# Usage: tool/smoke_deb.sh build/release/ovos-gui-visage_<version>_<arch>.deb
# Runs as root in a throwaway Debian or Ubuntu container; it installs packages.
set -euo pipefail

PACKAGE=ovos-gui-visage
RUN_SECONDS=20
STILL_RUNNING=124

DEB="$(realpath "${1:?usage: $0 <package.deb>}")"
if [[ $(id -u) -ne 0 ]]; then
  echo "error: run as root in a throwaway container; this installs packages" >&2
  exit 1
fi
export DEBIAN_FRONTEND=noninteractive

install_package() {
  apt-get update -qq
  apt-get install -y "$DEB"
  dpkg -L "$PACKAGE"
}

check_files() {
  local binary
  binary="$(readlink -f "/usr/bin/$PACKAGE")"
  echo "/usr/bin/$PACKAGE -> $binary"
  test -x "$binary"
  if ldd "$binary" | grep 'not found'; then
    echo "error: $binary has unresolved libraries" >&2
    exit 1
  fi
  ldd --version | sed -n '1p'
  desktop-file-validate /usr/share/applications/*.desktop "/usr/share/$PACKAGE"/*.desktop
}

# The app runs until it is stopped, so a timeout is a pass; any earlier exit is a crash.
run_app() {
  local log=/tmp/$PACKAGE-smoke.log status=0
  GDK_BACKEND=x11 VISAGE_MODE=window timeout "$RUN_SECONDS" \
    xvfb-run -a -s '-screen 0 1280x800x24' dbus-run-session -- "$PACKAGE" >"$log" 2>&1 || status=$?
  cat "$log"
  if [[ $status -ne $STILL_RUNNING ]]; then
    echo "error: $PACKAGE exited with $status within $RUN_SECONDS s" >&2
    exit 1
  fi
  echo "$PACKAGE was still running after $RUN_SECONDS s"
}

remove_package() {
  apt-get remove -y "$PACKAGE"
  if [[ -e /opt/$PACKAGE || -e /usr/bin/$PACKAGE ]]; then
    echo "error: apt remove left /opt/$PACKAGE or /usr/bin/$PACKAGE behind" >&2
    exit 1
  fi
}

install_package
apt-get install -y --no-install-recommends xvfb xauth dbus desktop-file-utils >/dev/null
check_files
run_app
remove_package
echo "smoke test passed: $(basename "$DEB")"
