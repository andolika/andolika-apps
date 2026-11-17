# Linux packages

`build.sh` makes the Arch, Debian and Fedora packages of Sulekha, Lipi, dekho and Dakia,
each inside a container of its own family, and `test.sh` installs every one into clean
containers of the releases it claims and checks that its binaries find every library.

```sh
./build.sh                  # every family, every application
./build.sh deb lipi         # one family, one application
./test.sh                   # install-test everything in ../../<app>/
```

Needs `podman` (rootless is fine). The applications are read from the Andolika tree the
repository sits in (`sulekha/`, `lipi/`, `dekho/`, `dakia/` and `common/` beside
`andolika-apps/`; `ANDOLIKA_TREE` points elsewhere), mounted read-only; cargo's work is
kept in named volumes (`andolika-build-<family>-target`, `-registry`), so a second
build only recompiles what changed. Logs go to `$LOGDIR` (default
`/tmp/andolika-linux-logs`). The packages land in each application's folder of this
repository, beside its Windows and macOS installers.

| File | What it is |
|---|---|
| `apps.sh` | What each application installs, and its dependencies per family |
| `inside.sh` | Run in a builder: `cargo build --release --locked`, stage, package |
| `Containerfile.arch` | Arch Linux → `.pkg.tar.zst` (makepkg) |
| `Containerfile.debian` | Debian 13 → `.deb` (dpkg-deb; library dependencies by dpkg-shlibdeps) |
| `Containerfile.fedora` | Fedora 42 → `.rpm` (rpmbuild; library dependencies by soname) |

Each family builds on its oldest supported release (Debian 13 and Fedora 42 have glibc
2.41, as does Ubuntu 25.04), so a binary never asks for a newer glibc or library than
the systems it claims. The builders use Rust 1.97.1 from rustup and the same cargo
features as the Windows and macOS installers.

`test.sh` installs each package on: Arch (current), Debian 13, Ubuntu 25.04 and 25.10,
Fedora 42 and 43, with the distribution's own package manager and without recommended
packages, then runs `ldd -r` and the binary itself and fails on a missing library or
symbol. It cannot open a window there; it proves that the package installs and the
program loads, not that the program works.
