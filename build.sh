#!/bin/bash

# Builds the Eleven ISO. Run as root on Arch Linux with archiso installed.
#
# The ISO is Arch's own "releng" install image with this repository laid over
# it: packages.x86_64 adds the desktop, airootfs/ adds its configuration and
# the installer. Nothing of Arch underneath is patched or replaced.

set -euo pipefail

here=$(cd "$(dirname "$0")" && pwd)
work=${WORK_DIR:-/tmp/eleven-work}
out=${OUT_DIR:-$here/out}
profile=$work/profile
releng=/usr/share/archiso/configs/releng

rm -rf "$work"
mkdir -p "$profile" "$out"
cp -a "$releng/." "$profile/"

# Wine and Proton need 32-bit libraries, which live in multilib.
enable_multilib() {
  sed -i '/^#\[multilib\]/,/^#Include/ s/^#//' "$1"
}
enable_multilib "$profile/pacman.conf"
enable_multilib /etc/pacman.conf
pacman -Sy --noconfirm >/dev/null

# A package that was renamed or dropped upstream is skipped with a warning
# rather than failing the build an hour in.
while read -r package; do
  [[ -n $package && $package != \#* ]] || continue
  if pacman -Si "$package" &>/dev/null || pacman -Sg "$package" &>/dev/null; then
    echo "$package" >>"$profile/packages.x86_64"
  else
    echo "::warning::package not found, skipped: $package"
  fi
done <"$here/packages.x86_64"

cp -a "$here/airootfs/." "$profile/airootfs/"

# The desktop uses NetworkManager, so the console image's network daemons
# stand down. Nothing listens for SSH on a desktop either.
find "$profile/airootfs/etc/systemd/system" \
  \( -name 'systemd-networkd*' -o -name 'iwd.service' -o -name 'sshd.service' \) -delete

units=$profile/airootfs/etc/systemd/system
mkdir -p "$units/multi-user.target.wants"
ln -sf /usr/lib/systemd/system/graphical.target "$units/default.target"
ln -sf /usr/lib/systemd/system/sddm.service "$units/display-manager.service"
ln -sf /usr/lib/systemd/system/NetworkManager.service "$units/multi-user.target.wants/NetworkManager.service"
ln -sf /usr/lib/systemd/system/bluetooth.service "$units/multi-user.target.wants/bluetooth.service"
ln -sf /etc/systemd/system/eleven-live.service "$units/multi-user.target.wants/eleven-live.service"

sed -i \
  -e 's/^iso_name=.*/iso_name="eleven"/' \
  -e 's/^iso_label=.*/iso_label="ELEVEN_$(date --date="@${SOURCE_DATE_EPOCH:-$(date +%s)}" +%Y%m)"/' \
  -e 's/^iso_publisher=.*/iso_publisher="Eleven"/' \
  -e 's/^iso_application=.*/iso_application="Eleven Live and Install Medium"/' \
  "$profile/profiledef.sh"

cat >>"$profile/profiledef.sh" <<'EOF'
file_permissions+=(
  ["/usr/local/bin/eleven-install"]="0:0:755"
  ["/usr/local/bin/eleven-live-setup"]="0:0:755"
  ["/usr/local/bin/eleven-run-windows"]="0:0:755"
  ["/etc/sudoers.d/10-wheel"]="0:0:440"
)
EOF

mkarchiso -v -w "$work/build" -o "$out" "$profile"
ls -lh "$out"
