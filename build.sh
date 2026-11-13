#!/bin/bash

# Builds the Eleven ISO. Run as root on Arch Linux with archiso, base-devel and
# git installed.
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

# Apps that Arch's repositories do not carry are made into packages here and
# handed to mkarchiso through a local repository.
repo=$work/repo
make=$work/make
mkdir -p "$repo" "$make"
chown nobody "$repo" "$make"

# makepkg refuses to run as root.
as_builder() {
  runuser -u nobody -- env HOME="$make" PKGDEST="$repo" PKGEXT=.pkg.tar.zst "$@"
}

# Prints the download address of the file matching $2 in the newest release of
# the GitHub repository $1.
release_file() {
  curl -fsSL ${GITHUB_TOKEN:+-H "Authorization: Bearer $GITHUB_TOKEN"} \
    "https://api.github.com/repos/$1/releases/latest" |
    grep -o "https://[^\"]*$2\"" | tr -d '"' | head -1
}

# Packages the AppImage $3 under the package name $1 and the menu name $2.
appimage_package() {
  local version=${3##*-}
  cp -r "$here/pkg/appimage" "$make/$1"
  chown -R nobody "$make/$1"
  (cd "$make/$1" && as_builder APP_ID="$1" APP_TITLE="$2" APP_VERSION="${version%.AppImage}" APP_FILE="$3" makepkg -d)
}

git clone --depth 1 https://aur.archlinux.org/brave-bin.git "$make/brave-bin"
chown -R nobody "$make/brave-bin"
(cd "$make/brave-bin" && as_builder makepkg -d)

url=$(release_file storytold/photocraft 'linux-x86_64\.pkg\.tar\.zst')
curl -fL --retry 3 -o "$repo/${url##*/}" "$url"

url=$(release_file artikampk-ops/artika-releases '\.AppImage')
curl -fL --retry 3 -o "$make/${url##*/}" "$url"
appimage_package artika-browser "Artika Browser" "$make/${url##*/}"

# Artika Communication has no download page yet, so it is kept in apps/, cut
# into parts small enough for GitHub.
for first in "$here"/apps/artika-communication-*.AppImage.part00; do
  file=$make/$(basename "${first%.part00}")
  cat "${first%00}"* >"$file"
  appimage_package artika-communication "Artika Communication" "$file"
done

rm -f "$repo"/*-debug-*.pkg.tar.zst
repo-add -q "$repo/eleven.db.tar.gz" "$repo"/*.pkg.tar.zst
cat >>"$profile/pacman.conf" <<EOF

[eleven]
SigLevel = Optional TrustAll
Server = file://$repo
EOF
for package in "$repo"/*.pkg.tar.zst; do
  bsdtar -xOf "$package" .PKGINFO | sed -n 's/^pkgname = //p' >>"$profile/packages.x86_64"
done

cp -a "$here/airootfs/." "$profile/airootfs/"

# The desktop uses NetworkManager, so the console image's network daemons
# stand down. Nothing listens for SSH on a desktop either.
find "$profile/airootfs/etc/systemd/system" \
  \( -name 'systemd-networkd*' -o -name 'iwd.service' -o -name 'sshd.service' \) -prune -exec rm -rf {} +

units=$profile/airootfs/etc/systemd/system
mkdir -p "$units/multi-user.target.wants"
ln -sf /usr/lib/systemd/system/graphical.target "$units/default.target"
ln -sf /usr/lib/systemd/system/sddm.service "$units/display-manager.service"
ln -sf /usr/lib/systemd/system/NetworkManager.service "$units/multi-user.target.wants/NetworkManager.service"
ln -sf /usr/lib/systemd/system/bluetooth.service "$units/multi-user.target.wants/bluetooth.service"
ln -sf /etc/systemd/system/eleven-live.service "$units/multi-user.target.wants/eleven-live.service"

# The boot menu names the system it starts.
grep -rl "Arch Linux install medium" "$profile/efiboot" "$profile/syslinux" "$profile/grub" 2>/dev/null |
  xargs -r sed -i 's/Arch Linux install medium/Eleven/g'

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
  ["/usr/local/bin/eleven-desktop-icons"]="0:0:755"
  ["/etc/sudoers.d/10-wheel"]="0:0:440"
)
EOF

mkarchiso -v -w "$work/build" -o "$out" "$profile"
ls -lh "$out"
