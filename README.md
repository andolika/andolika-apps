# Andolika applications

Installers for the Andolika applications, one folder each. Every file is named
`<Application>-<version>-<architecture>` and its kind says which system it is for.

| | Windows | macOS | Linux |
|---|---|---|---|
| **Sulekha** — PDF viewer and stylus annotator | x64, arm64 | Apple silicon | Arch, Debian/Ubuntu, Fedora |
| **Lipi** — LaTeX editor, collaborative without a server | x64, arm64 | Apple silicon | Arch, Debian/Ubuntu, Fedora |
| **dekho** — file manager | x64, arm64 | Apple silicon | Arch, Debian/Ubuntu, Fedora |
| **Dakia** — email client | x64, arm64 | Apple silicon | Arch, Debian/Ubuntu, Fedora |
| **Jannal** | x64, arm64 | | |

## Windows

`<App>-<version>-x64-setup.exe` for Intel and AMD processors, `-arm64-setup.exe` for
Windows on ARM. Run it and follow the installer.

## macOS

`<App>-<version>-arm64.dmg`, for Macs with Apple silicon. Open it and drag the
application to Applications.

## Linux

Packages for x86_64, built on each family's own system so they use its libraries. The
applications need GTK 4.18 and libadwaita 1.7, which sets the oldest release each
package supports:

| Family | File | Installs on | Install with |
|---|---|---|---|
| Arch | `<App>-<version>-x86_64.pkg.tar.zst` | Arch Linux and its derivatives (EndeavourOS, Manjaro, CachyOS) | `sudo pacman -U ./Sulekha-1.1.1-x86_64.pkg.tar.zst` |
| Debian | `<App>-<version>-amd64.deb` | Debian 13 and later, Ubuntu 25.04 and later | `sudo apt install ./Sulekha-1.1.1-amd64.deb` |
| Red Hat | `<App>-<version>-x86_64.rpm` | Fedora 42 and later | `sudo dnf install ./Sulekha-1.1.1-x86_64.rpm` |

Install through the package manager as shown, not with `dpkg -i` or `rpm -i`, so that
the libraries each application needs are installed with it. Ubuntu 24.04 LTS and
Debian 12 are too old for GTK 4.18.

Each package says what it needs and what it can use:

- **Sulekha** plays video embedded in a PDF with GStreamer's good and libav plugins,
  and exports a recorded talk to video with ffmpeg; both are optional.
- **Lipi** builds with your own TeX distribution (TeX Live and `latexmk`), which the
  Debian and Fedora packages recommend; texlab adds completion and go-to-definition.
- **dekho** needs GStreamer's GTK 4 sink for media, and uses ripgrep, fd, git, unzip and
  7-Zip when they are installed.
- **Dakia** reads mail from a local maildir kept with `isync` and searched with
  `notmuch`, which every package installs with it; `pdftotext` (poppler) summarises PDF
  attachments.

The Linux packages are built by `packaging/linux/` (see its README).
