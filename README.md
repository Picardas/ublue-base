# uBlue-Picardas

A custom [bootc](https://github.com/bootc-dev/bootc) image built on top of
[`ghcr.io/ublue-os/silverblue-main`](https://github.com/ublue-os/main). Kept
closer to stock Fedora Silverblue than the base image and other uBlue
derivatives. NVIDIA drivers with secureboot support, a handful of apps, and
Mosaic window manager extension.

## NVIDIA + secure boot

After a fresh install, run:

```
ujust enroll-secure-boot-key
```

then reboot and enroll the key in the MOK Manager UI (password
`universalblue`).

## Removed from the base image

```
distrobox fzf net-tools ibus-unikey ibus-mozc solaar-udev oversteer-udev
openrgb-udev-rules libratbag-ratbagd tcpdump traceroute lshw powerstat
squashfs-tools vim-enhanced gnome-software gnome-tour
```

## Installed

```
chezmoi nvim arm-image-installer 1password 1password-cli zed steam claude-code
git-credential-manager MosaicWM
```

## Suggested Flatpaks

Flatpak is the recommended method to install additional software.
`gnome-software` isn't part of this image, so Flatpaks are installed via the CLI
or a seperate app store such as Bazaar (included in the below recommendations).
The Flathub remote pre-configured system-wide. To install my list of recommended
Flatpaks, run the following post-install:

```
flatpak install flathub \
    org.gnome.Calculator \
    org.gnome.Calendar \
    org.gnome.Characters \
    org.gnome.Contacts \
    org.gnome.Logs \
    org.gnome.Loupe \
    org.gnome.NautilusPreviewer \
    org.gnome.Papers \
    org.gnome.Showtime \
    org.gnome.Snapshot \
    org.gnome.TextEditor \
    org.gnome.Weather \
    org.gnome.baobab \
    org.gnome.clocks \
    org.gnome.font-viewer \
    io.github.kolunmi.Bazaar \
    page.tesk.Refine \
    com.mattjakeman.ExtensionManager \
    com.vysp3r.ProtonPlus
```
