#!/usr/bin/env bash
# Packages a Linux release bundle (flutter build linux --release) as a .deb with dpkg-deb. docs/PACKAGING.md has the flow.
# Usage: tool/package_deb.sh [bundle-dir]
# The bundle defaults to the one for this machine's architecture. Needs dpkg-dev: dpkg-shlibdeps reads Depends from the
# libraries the binaries link. The .deb and its .sha256 go to build/release.
set -euo pipefail

cd "$(dirname "$0")/.."

PACKAGE=ovos-gui-visage
APP_ID=net.oscillatelabs.ovosGuiVisage
BINARY=ovos_gui_visage
PREFIX=opt/$PACKAGE
MAINTAINER="Oscillate Labs LLC <mike@oscillatelabs.net>"
HOMEPAGE=https://github.com/OscillateLabsLLC/ovos-gui-visage
OUT_DIR=build/release
# The engine renders with EGL and GLES, which libepoxy dlopens, so dpkg-shlibdeps cannot see them.
DLOPEN_DEPENDS="libegl1, libgles2"

ARCH="$(dpkg --print-architecture)"
VERSION="$(sed -n 's/^version: *\([^+[:space:]]*\).*$/\1/p' pubspec.yaml)"
if [[ -z "$VERSION" ]]; then
  echo "error: no version in pubspec.yaml" >&2
  exit 1
fi
DEB_NAME="${PACKAGE}_${VERSION}_${ARCH}.deb"

default_bundle() {
  case $ARCH in
    amd64) echo build/linux/x64/release/bundle ;;
    arm64) echo build/linux/arm64/release/bundle ;;
    *)
      echo "error: no Flutter Linux build for $ARCH" >&2
      exit 1
      ;;
  esac
}

BUNDLE="${1:-$(default_bundle)}"
if [[ ! -x "$BUNDLE/$BINARY" ]]; then
  echo "error: no $BINARY in $BUNDLE; run: flutter build linux --release" >&2
  exit 1
fi

# dpkg-shlibdeps treats libraries under debian/<package> as part of the package, so the bundled ones need no Depends.
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
STAGE="$WORK/debian/$PACKAGE"

stage_bundle() {
  mkdir -p "$STAGE/$PREFIX" "$STAGE/usr/bin"
  cp -R "$BUNDLE/." "$STAGE/$PREFIX/"
  # libapp.so is the AOT snapshot and the engine ships stripped; strip only what the runner and plugin builds left.
  strip --strip-unneeded "$STAGE/$PREFIX/$BINARY" "$STAGE/$PREFIX"/lib/lib*_plugin.so
  # The plugins' RUNPATH is the build machine's flutter/ephemeral; the runner has loaded libflutter before them.
  chrpath -d "$STAGE/$PREFIX"/lib/lib*_plugin.so
  ln -s "/$PREFIX/$BINARY" "$STAGE/usr/bin/$PACKAGE"
}

desktop_entry() {
  sed "/^Exec=/s/$BINARY\$/$PACKAGE/" "linux/$1"
}

# No maintainer scripts: the file triggers of hicolor-icon-theme and desktop-file-utils refresh both caches.
stage_desktop_files() {
  local icon size
  mkdir -p "$STAGE/usr/share/applications" "$STAGE/usr/share/$PACKAGE"
  desktop_entry "$APP_ID.desktop" >"$STAGE/usr/share/applications/$APP_ID.desktop"
  desktop_entry "$APP_ID-kiosk.desktop" >"$STAGE/usr/share/$PACKAGE/$APP_ID-kiosk.desktop"
  for icon in linux/icons/hicolor/*/apps/"$APP_ID".png; do
    size=$(basename "$(dirname "$(dirname "$icon")")")
    install -D -m 644 "$icon" "$STAGE/usr/share/icons/hicolor/$size/apps/$APP_ID.png"
  done
}

write_copyright() {
  cat <<EOF
Format: https://www.debian.org/doc/packaging-manuals/copyright-format/1.0/
Upstream-Name: $PACKAGE
Source: $HOMEPAGE

Files: *
Copyright: $(date -u +%Y) Oscillate Labs LLC
License: Apache-2.0
 On Debian systems, the full text of the Apache License 2.0 is in
 /usr/share/common-licenses/Apache-2.0.
EOF
}

write_changelog() {
  cat <<EOF
$PACKAGE ($VERSION) stable; urgency=medium

  * Release $VERSION. The changes are in CHANGELOG.md at the v$VERSION tag:
    $HOMEPAGE/releases/tag/v$VERSION

 -- $MAINTAINER  $(date -u -R)
EOF
}

stage_docs() {
  local doc="$STAGE/usr/share/doc/$PACKAGE"
  mkdir -p "$doc" "$STAGE/usr/share/lintian/overrides"
  write_copyright >"$doc/copyright"
  write_changelog | gzip -9n >"$doc/changelog.gz"
  cp linux/debian/lintian-overrides "$STAGE/usr/share/lintian/overrides/$PACKAGE"
}

fix_permissions() {
  find "$STAGE" -type d -exec chmod 755 {} +
  find "$STAGE" -type f -exec chmod 644 {} +
  chmod 755 "$STAGE/$PREFIX/$BINARY"
}

shlib_depends() {
  local elf_files=("$STAGE/$PREFIX/$BINARY" "$STAGE/$PREFIX"/lib/*.so)
  mkdir -p "$WORK/debian"
  printf 'Source: %s\n\nPackage: %s\nArchitecture: any\n' "$PACKAGE" "$PACKAGE" >"$WORK/debian/control"
  (cd "$WORK" && dpkg-shlibdeps -O "-ldebian/$PACKAGE/$PREFIX/lib" "${elf_files[@]/#$WORK\//}") |
    sed -n 's/^shlibs:Depends=//p'
}

write_control() {
  local depends
  depends="$(shlib_depends)"
  if [[ -z "$depends" ]]; then
    echo "error: dpkg-shlibdeps found no dependencies" >&2
    exit 1
  fi
  mkdir -p "$STAGE/DEBIAN"
  cat >"$STAGE/DEBIAN/control" <<EOF
Package: $PACKAGE
Version: $VERSION
Architecture: $ARCH
Maintainer: $MAINTAINER
Installed-Size: $(du -sk --exclude=DEBIAN "$STAGE" | cut -f 1)
Depends: $depends, $DLOPEN_DEPENDS
Section: utils
Priority: optional
Homepage: $HOMEPAGE
Description: face and screens for an OpenVoiceOS voice assistant
 OVOS Visage is a GUI client for OpenVoiceOS in the style of the 2018
 Mycroft Mark II concept. It connects to a stock ovos-gui service on the
 same machine and shows the animated face, the clock and the skill pages.
 .
 It runs as a corner widget on the desktop, as an ordinary window, or full
 screen as a kiosk, for example on a Raspberry Pi with a touchscreen.
EOF
}

build_deb() {
  mkdir -p "$OUT_DIR"
  dpkg-deb --build --root-owner-group -Zxz "$STAGE" "$OUT_DIR/$DEB_NAME"
  (cd "$OUT_DIR" && sha256sum "$DEB_NAME" | tee "$DEB_NAME.sha256")
}

stage_bundle
stage_desktop_files
stage_docs
fix_permissions
write_control
build_deb
echo "built $OUT_DIR/$DEB_NAME (version $VERSION, $ARCH)"
