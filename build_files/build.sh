#!/bin/bash

set -ouex pipefail

# Copy the contents of system_files/ of the git repo to /
cp -avf "/ctx/system_files"/. /

# Enforce cosign signature verification for this image's own registry
# namespace, same as ublue does for ghcr.io/ublue-os in the base policy.json
# (system_files placed the key at /etc/pki/containers/picardas.pub and the
# matching registries.d entry already; this just merges the policy rule in
# rather than overwriting the file, so ublue's own entries are kept intact)
jq '.transports.docker["ghcr.io/picardas"] = [{
        "type": "sigstoreSigned",
        "keyPath": "/etc/pki/containers/picardas.pub",
        "signedIdentity": {"type": "matchRepository"}
    }]' /etc/containers/policy.json > /tmp/policy.json.new
mv /tmp/policy.json.new /etc/containers/policy.json

### Install packages

# Packages can be installed from any enabled yum repo on the image.
# RPMfusion repos are available by default in ublue main images
# List of rpmfusion packages can be found here:
# https://mirrors.rpmfusion.org/mirrorlist?path=free/fedora/updates/43/x86_64/repoview/index.html&protocol=https&redirect=1

# this removes packages installed by default in Silverblue & uBlue main images
dnf5 remove -y distrobox fzf net-tools ibus-unikey ibus-mozc \
    solaar-udev oversteer-udev openrgb-udev-rules libratbag-ratbagd tcpdump \
    traceroute lshw powerstat squashfs-tools vim-enhanced gnome-software \
    gnome-tour

# this installs a package from fedora repos
dnf5 install -y chezmoi nvim arm-image-installer

# hide CLI tools from the GNOME app grid (still usable from a terminal)
for f in htop nvtop nvim; do
    sed -i '/^\[Desktop Entry\]/a NoDisplay=true' "/usr/share/applications/${f}.desktop"
done

# install packages form Terra repo
sudo dnf install -y --nogpgcheck --repofrompath 'terra,https://repos.fyralabs.com/terra$releasever' terra-gpg-keys terra-release
sudo dnf install -y 1password 1password-cli zed steam

# Use a COPR Example:
#
# dnf5 -y copr enable ublue-os/staging
# dnf5 -y install package
# Disable COPRs so they don't end up enabled on the final image:
# dnf5 -y copr disable ublue-os/staging

# Claude Code from Anthropic's official RPM repo
cat > /etc/yum.repos.d/claude-code.repo <<'EOF'
[claude-code]
name=Claude Code
baseurl=https://downloads.claude.ai/claude-code/rpm/stable
enabled=1
gpgcheck=1
gpgkey=https://downloads.claude.ai/keys/claude-code.asc
EOF
dnf5 install -y claude-code

# Git Credential Manager (GUI build) — Terra's RPM lacks GUI support
GCM_ASSET_JSON=$(curl -fsSL https://api.github.com/repos/git-ecosystem/git-credential-manager/releases/latest \
    | jq -r '.assets[] | select(.name | test("^gcm-linux-x64-[0-9.]+\\.tar\\.gz$"))')
GCM_URL=$(echo "${GCM_ASSET_JSON}" | jq -r '.browser_download_url')
GCM_SHA256=$(echo "${GCM_ASSET_JSON}" | jq -r '.digest' | sed 's/^sha256://')
curl -fsSL -o /tmp/gcm.tar.gz "${GCM_URL}"
echo "${GCM_SHA256}  /tmp/gcm.tar.gz" | sha256sum -c -
tar --no-same-owner -xzf /tmp/gcm.tar.gz -C /usr/bin
rm -f /tmp/gcm.tar.gz

# Mosaic WM GNOME Shell extension, system-wide, enabled by default
MOSAIC_UUID="mosaicwm@cleomenezesjr.github.io"
MOSAIC_DIR="/usr/share/gnome-shell/extensions/${MOSAIC_UUID}"
curl -fsSL -o /tmp/mosaicwm.tar.gz https://github.com/CleoMenezesJr/MosaicWM/archive/refs/heads/main.tar.gz
mkdir -p /tmp/mosaicwm-src
tar --no-same-owner -xzf /tmp/mosaicwm.tar.gz -C /tmp/mosaicwm-src --strip-components=1
mkdir -p "${MOSAIC_DIR}"
cp -r /tmp/mosaicwm-src/extension/. "${MOSAIC_DIR}/"
glib-compile-schemas "${MOSAIC_DIR}/schemas"
rm -rf /tmp/mosaicwm.tar.gz /tmp/mosaicwm-src

cat > /usr/share/glib-2.0/schemas/zz-mosaicwm.gschema.override <<EOF
[org.gnome.shell]
enabled-extensions=['${MOSAIC_UUID}']
EOF
glib-compile-schemas /usr/share/glib-2.0/schemas

#### Example for enabling a System Unit File
#
# systemctl enable podman.socket

### Install Nvidia Drivers
AKMODNV_PATH=/tmp/akmods-nv-rpms IMAGE_NAME=silverblue /tmp/akmods-nv-rpms/ublue-os/nvidia-install.sh

### Regenerate initramfs
/ctx/initramfs.sh

### Clean up dnf repo metadata
rm -rf /var/lib/dnf/repos
