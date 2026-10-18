#!/usr/bin/env bash
# DreamByte OS TV — construye la ISO con live-build.
# Uso (como root, en Debian trixie):  build/build.sh [arm64|amd64]
# Resultado: out/dreambyte-os-tv-<version>-<arch>.iso (+ .sha256)
set -euo pipefail

ARCH="${1:-arm64}"
VERSION="0.1"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORK="$ROOT/build/work-$ARCH"
OUT="$ROOT/out"

case "$ARCH" in
  arm64)
    BOOTLOADERS="grub-efi"
    EXTRA_PKGS="grub-efi-arm64-bin"
    ;;
  amd64)
    BOOTLOADERS="syslinux,grub-efi"
    EXTRA_PKGS="grub-efi-amd64-bin grub-pc-bin syslinux syslinux-utils syslinux-common isolinux"
    ;;
  *)
    echo "Arquitectura no soportada: $ARCH (usa arm64 o amd64)" >&2
    exit 1
    ;;
esac

if [ "$(id -u)" -ne 0 ]; then
  echo "Este script necesita root (live-build usa chroot y mount)." >&2
  exit 1
fi

export DEBIAN_FRONTEND=noninteractive
apt-get update
# shellcheck disable=SC2086
apt-get install -y --no-install-recommends \
  live-build debootstrap squashfs-tools xorriso mtools dosfstools \
  ca-certificates gnupg debian-archive-keyring $EXTRA_PKGS

rm -rf "$WORK"
mkdir -p "$WORK" "$OUT"
cd "$WORK"

lb config \
  --mode debian \
  --distribution trixie \
  --architecture "$ARCH" \
  --archive-areas "main contrib non-free-firmware" \
  --binary-images iso-hybrid \
  --bootloaders "$BOOTLOADERS" \
  --debian-installer none \
  --memtest none \
  --linux-flavours "$ARCH" \
  --iso-application "DreamByte OS TV" \
  --iso-publisher "DreamByte Studios" \
  --iso-volume "DREAMBYTE-TV" \
  --bootappend-live "boot=live components quiet username=dreambyte hostname=dreambyte-tv locales=es_MX.UTF-8 keyboard-layouts=latam"

# Nuestra configuración (listas de paquetes, archivos, hooks)
cp -a "$ROOT/image/config/." config/

# El exec bit puede perderse al subir archivos; lo aseguramos.
find config/hooks -type f -name '*.chroot' -exec chmod +x {} +
chmod +x config/includes.chroot/usr/local/bin/dreambyte-session

lb build 2>&1 | tee "$WORK/build.log"

ISO="$(find "$WORK" -maxdepth 1 -name '*.iso' | head -n1)"
if [ -z "$ISO" ]; then
  echo "No se generó ninguna ISO. Revisa $WORK/build.log" >&2
  exit 1
fi

DEST="$OUT/dreambyte-os-tv-$VERSION-$ARCH.iso"
mv "$ISO" "$DEST"
( cd "$OUT" && sha256sum "$(basename "$DEST")" > "$(basename "$DEST").sha256" )
cp "$WORK/build.log" "$OUT/build-$ARCH.log"
echo "ISO lista: $DEST"
ls -lh "$OUT"
