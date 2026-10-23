#!/usr/bin/env bash
# Adds or removes the Linux launcher, its icons and the optional kiosk autostart entry for the current user.
# Usage: tool/linux_desktop.sh install | uninstall | autostart-on | autostart-off
# install and autostart-on point the entries at a release bundle built by `flutter build linux --release`.
set -euo pipefail

app_id=net.oscillatelabs.ovos_gui_visage
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

write_entry() {
  local source=$1 target=$2 binary
  binary=$(bundle_binary)
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
    write_entry "$repo/linux/$app_id.desktop" "$launcher"
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
    write_entry "$repo/linux/$app_id-kiosk.desktop" "$autostart"
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
