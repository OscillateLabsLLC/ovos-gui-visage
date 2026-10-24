#!/usr/bin/env bash
# Adds or removes the Linux launcher, its icons and the optional kiosk autostart entry for the current user.
# Usage: tool/linux_desktop.sh install | uninstall | autostart-on | autostart-off
# install points the launcher at a release bundle built by `flutter build linux --release`. With the .deb installed the
# package already provides the launcher and icons, so install refuses, and autostart-on points at the packaged app.
set -euo pipefail

app_id=net.oscillatelabs.ovosGuiVisage
packaged_binary=/usr/bin/ovos-gui-visage
repo=$(cd "$(dirname "$0")/.." && pwd)
data=${XDG_DATA_HOME:-$HOME/.local/share}
config=${XDG_CONFIG_HOME:-$HOME/.config}
launcher=$data/applications/$app_id.desktop
autostart=$config/autostart/$app_id-kiosk.desktop

bundle_binary() {
  local binary
  for binary in "$repo"/build/linux/*/release/bundle/ovos_gui_visage; do
    if [[ -x $binary ]]; then
      echo "$binary"
      return
    fi
  done
  echo "No release bundle under $repo/build/linux; run: flutter build linux --release" >&2
  exit 1
}

app_binary() {
  if [[ -x $packaged_binary ]]; then
    echo "$packaged_binary"
    return
  fi
  bundle_binary
}

refuse_if_packaged() {
  if [[ -x $packaged_binary ]]; then
    echo "The ovos-gui-visage package is installed and provides the launcher and icons; a copy here would hide it." >&2
    exit 1
  fi
}

write_entry() {
  local source=$1 target=$2 binary=$3
  mkdir -p "$(dirname "$target")"
  sed "/^Exec=/s| ovos_gui_visage\$| $binary|; s|^Exec=ovos_gui_visage\$|Exec=$binary|" "$source" >"$target"
  echo "Wrote $target (Exec: $binary)"
}

install_icons() {
  local icon size
  for icon in "$repo"/linux/icons/hicolor/*/apps/"$app_id".png; do
    size=$(basename "$(dirname "$(dirname "$icon")")")
    install -D -m 644 "$icon" "$data/icons/hicolor/$size/apps/$app_id.png"
  done
  gtk-update-icon-cache --force --ignore-theme-index "$data/icons/hicolor"
}

case ${1:-} in
  install)
    refuse_if_packaged
    binary=$(bundle_binary)
    write_entry "$repo/linux/$app_id.desktop" "$launcher" "$binary"
    install_icons
    update-desktop-database "$data/applications"
    ;;
  uninstall)
    rm -f "$launcher" "$data"/icons/hicolor/*/apps/"$app_id".png
    gtk-update-icon-cache --force --ignore-theme-index "$data/icons/hicolor"
    update-desktop-database "$data/applications"
    echo "Removed $launcher and its icons"
    ;;
  autostart-on)
    binary=$(app_binary)
    write_entry "$repo/linux/$app_id-kiosk.desktop" "$autostart" "$binary"
    ;;
  autostart-off)
    rm -f "$autostart"
    echo "Removed $autostart"
    ;;
  *)
    echo "Usage: $0 install | uninstall | autostart-on | autostart-off" >&2
    exit 2
    ;;
esac
