#!/bin/bash
# inside.sh FAMILY APP… — runs in a builder container (see build.sh).
#
#   /src     the Andolika tree, read-only (applications find ../common and ../sulekha)
#   /build   cargo's target directories, one per application, kept between runs
#   /out     where the finished packages go
#   /pkg     this directory (apps.sh)
set -euo pipefail
FAMILY=$1; shift
export CARGO_HOME=/opt/cargo
MAINTAINER="Andolika Labs <hello@andolika.com>"

for APP in "$@"; do
    source /pkg/apps.sh
    SRC=/src/$APP
    VERSION=$(sed -n 's/^version *= *"\([^"]*\)".*/\1/p' "$SRC/Cargo.toml" | head -1)
    LICENSE=$(sed -n 's/^license *= *"\([^"]*\)".*/\1/p' "$SRC/Cargo.toml" | head -1)
    LICENSE=${LICENSE:-LicenseRef-Andolika}
    export TARGET=/build/$APP
    echo "=== $FAMILY: $APP $VERSION"

    # The source is read-only, so cargo keeps everything it writes under /build; --locked
    # builds exactly what Cargo.lock names, as the other platforms' installers do.
    CARGO_TARGET_DIR=$TARGET cargo build --release --locked --manifest-path "$SRC/Cargo.toml"

    export STAGE=/tmp/stage/$APP
    rm -rf "$STAGE"; mkdir -p "$STAGE"
    (cd "$SRC" && stage)
    for b in "${BINARIES[@]}"; do strip --strip-unneeded "$STAGE/usr/bin/$b"; done
    # Files are root's in every package, whoever built them.
    find "$STAGE" -type d -exec chmod 755 {} +

    case $FAMILY in
    arch)
        W=/tmp/makepkg/$APP; rm -rf "$W"; mkdir -p "$W"
        {
            echo "pkgname=$APP"
            echo "pkgver=$VERSION"
            echo "pkgrel=1"
            printf 'pkgdesc=%q\n' "$SUMMARY"
            echo "arch=('x86_64')"
            echo "url='$URL'"
            echo "license=('$LICENSE')"
            printf 'depends=('; printf "'%s' " "${ARCH_DEPENDS[@]}"; echo ')'
            printf 'optdepends=('; printf "'%s' " "${ARCH_OPTDEPENDS[@]}"; echo ')'
            echo "options=(!strip !debug !lto)"
            echo "package() { cp -a '$STAGE'/. \"\$pkgdir\"/; }"
        } > "$W/PKGBUILD"
        chown -R builder "$W"; chmod -R a+rX "$STAGE"
        (cd "$W" && su builder -c "PKGDEST=$W makepkg -f --nodeps --noconfirm" >/dev/null)
        cp "$W/$APP-$VERSION-1-x86_64.pkg.tar.zst" "/out/$NAME-$VERSION-x86_64.pkg.tar.zst"
        ;;
    deb)
        W=/tmp/deb/$APP; rm -rf "$W"; mkdir -p "$W/debian" "$STAGE/DEBIAN"
        printf 'Source: %s\n\nPackage: %s\nArchitecture: amd64\n' "$APP" "$APP" > "$W/debian/control"
        bins=(); for b in "${BINARIES[@]}"; do bins+=("-e$STAGE/usr/bin/$b"); done
        shlibs=$(cd "$W" && dpkg-shlibdeps -O "${bins[@]}" 2>/dev/null | sed -n 's/^shlibs:Depends=//p')
        join() { local IFS=,; echo "$*" | sed 's/,/, /g'; }
        depends=$(join "$shlibs" "${DEB_DEPENDS[@]}")
        {
            echo "Package: $APP"
            echo "Version: $VERSION-1"
            echo "Architecture: amd64"
            echo "Maintainer: $MAINTAINER"
            echo "Installed-Size: $(du -sk --exclude=DEBIAN "$STAGE" | cut -f1)"
            echo "Depends: $depends"
            [ ${#DEB_RECOMMENDS[@]} -gt 0 ] && echo "Recommends: $(join "${DEB_RECOMMENDS[@]}")"
            [ ${#DEB_SUGGESTS[@]} -gt 0 ] && echo "Suggests: $(join "${DEB_SUGGESTS[@]}")"
            echo "Section: misc"
            echo "Priority: optional"
            echo "Homepage: $URL"
            echo "Description: $SUMMARY"
            echo "$DESCRIPTION" | fold -s -w 78 | sed 's/^/ /'
        } > "$STAGE/DEBIAN/control"
        dpkg-deb --root-owner-group -Zxz --build "$STAGE" "/out/$NAME-$VERSION-amd64.deb" >/dev/null
        rm -rf "$STAGE/DEBIAN"
        ;;
    rpm)
        W=/tmp/rpm/$APP; rm -rf "$W"; mkdir -p "$W"/{SPECS,RPMS,BUILD,BUILDROOT}
        {
            echo "%global debug_package %{nil}"
            echo "%global __brp_strip %{nil}"
            echo "Name: $APP"
            echo "Version: $VERSION"
            echo "Release: 1"
            echo "Summary: $SUMMARY"
            echo "License: $LICENSE"
            echo "URL: $URL"
            for r in "${RPM_REQUIRES[@]}"; do echo "Requires: $r"; done
            for r in "${RPM_RECOMMENDS[@]}"; do echo "Recommends: $r"; done
            for r in "${RPM_SUGGESTS[@]}"; do echo "Suggests: $r"; done
            echo; echo "%description"; echo "$DESCRIPTION" | fold -s -w 78
            echo; echo "%install"; echo "cp -a '$STAGE'/. %{buildroot}/"
            echo; echo "%files"
            # rpmbuild compresses man pages after %install, so name them by their stem.
            (cd "$STAGE" && find . -type f -o -type l | sed 's|^\.||; s|^\(/usr/share/man/.*\)$|\1*|' | sort)
        } > "$W/SPECS/$APP.spec"
        rpmbuild -bb --define "_topdir $W" "$W/SPECS/$APP.spec" >/dev/null
        cp "$W/RPMS/x86_64/$APP-$VERSION-1.x86_64.rpm" "/out/$NAME-$VERSION-x86_64.rpm"
        ;;
    esac
    echo "=== $FAMILY: $APP done"
done
