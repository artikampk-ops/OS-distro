# Eleven

Arch Linux with a Windows 11 style desktop: a taskbar along the bottom with Start and pinned apps in the middle, the Windows keyboard shortcuts, an app store, and Windows programs running through Proton. Underneath it is stock Arch Linux; nothing of Arch is patched or replaced.

## What is in this repository

- `build.sh` builds the ISO. It takes Arch's own `releng` install image and lays this repository over it.
- `packages.x86_64` lists the packages added to Arch's image: the KDE Plasma desktop, a handful of apps, and the app store.
- `pkg/` and `apps/` hold what is needed to package the apps Arch does not carry.
- `airootfs/` holds the files added to the system: the desktop layout, the shortcuts, and the installer.
- `.github/workflows/build-iso.yml` builds the ISO on every push to `main` and publishes it under Releases.

## Getting the ISO

Download the newest ISO from the repository's Releases page. If it comes in parts, the release notes say how to join them.

To build it yourself on Arch Linux:

```bash
sudo pacman -S archiso base-devel git
sudo ./build.sh
```

## Installing

Write the ISO to a USB stick and start the computer from it in UEFI mode. It starts a live desktop; open **Install Eleven** on the desktop and answer its questions. The installer erases the whole disk you pick.

## Keyboard shortcuts

| Keys | Action |
| --- | --- |
| Win | Start menu |
| Win + S, Win + R | Search and run |
| Win + E | File manager |
| Win + I | Settings |
| Win + D | Show desktop |
| Win + L | Lock |
| Win + V | Clipboard history |
| Win + . | Emoji picker |
| Win + Tab | Task view |
| Win + Up / Down | Maximize / minimize |
| Win + Left / Right | Snap to a half |
| Win + Shift + Left / Right | Move window to another monitor |
| Win + Ctrl + Left / Right | Switch virtual desktop |
| Win + 1 to 9 | Open the pinned app in that position |
| Win + Shift + S | Screenshot a region |
| Alt + Tab | Switch windows |
| Alt + F4 | Close window |
| Ctrl + Shift + Esc | Task manager |
| Ctrl + Alt + Del | Lock, log out, restart |

## Accounts

The root account is locked. The user created during install is an administrator and uses `sudo`.

## Apps

These come installed, each with an icon on the desktop:

| App | What it is |
| --- | --- |
| File manager | Dolphin |
| Brave | The default web browser |
| Artika Browser, Artika Communication | Packaged from their AppImages |
| PhotoCraft | Photo editor |
| Notepad | KWrite, under the name Notepad |
| Discord | The Discord app |
| ChatGPT, Canva, YouTube, YouTube Music, Spotify, Watermark | Each site in its own window, through Brave |

Brave, PhotoCraft and the Artika apps are not in Arch's repositories, so a system update does not update them; a newer ISO carries newer versions.

Beyond those:

- **Discover** is the app store. It installs Linux apps from Flathub.
- Opening a `.exe` or `.msi` runs it through Proton. The first start downloads Proton, which takes a few minutes.
