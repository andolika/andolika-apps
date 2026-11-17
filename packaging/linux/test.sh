#!/bin/bash
# test.sh [APP…] — install each Linux package into a clean container of every release it
# claims, with that distribution's own package manager (so its dependencies have to
# resolve), then check that every binary finds all its libraries and symbols.
set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
REPO=$(cd "$HERE/../.." && pwd)
APPS=("$@"); [ ${#APPS[@]} -gt 0 ] || APPS=(sulekha lipi dekho dakia)

# family → images it is promised to install on
declare -A IMAGES=(
    [arch]="docker.io/library/archlinux:latest"
    [deb]="docker.io/library/debian:13 docker.io/library/ubuntu:25.04 docker.io/library/ubuntu:25.10"
    [rpm]="registry.fedoraproject.org/fedora:42 registry.fedoraproject.org/fedora:43"
)
declare -A GLOB=([arch]='*-x86_64.pkg.tar.zst' [deb]='*-amd64.deb' [rpm]='*-x86_64.rpm')
declare -A INSTALL=(
    [arch]='pacman -Syu --noconfirm >/dev/null && pacman -U --noconfirm "$P" >/dev/null'
    [deb]='apt-get update -qq && DEBIAN_FRONTEND=noninteractive apt-get install -y -qq --no-install-recommends "$P" >/dev/null'
    [rpm]='dnf -y -q install --setopt=install_weak_deps=False "$P" >/dev/null'
)
# What a binary that cannot start says before it ever looks for a display.
CHECK='for b in $BINS; do
    out=$(ldd -r /usr/bin/$b 2>&1)
    if echo "$out" | grep -qE "not found|undefined symbol"; then echo "  $b: $(echo "$out" | grep -E "not found|undefined symbol" | head -3)"; exit 1; fi
    run=$(timeout 10 /usr/bin/$b --version 2>&1 </dev/null)
    if echo "$run" | grep -qE "error while loading shared libraries|symbol lookup error|version .GLIBC"; then echo "  $b: $run"; exit 1; fi
done'

fail=0
for app in "${APPS[@]}"; do
    case $app in sulekha) bins=sulekha ;; *) bins=$app ;; esac
    for fam in arch deb rpm; do
        for pkg in "$REPO/$app"/${GLOB[$fam]}; do
            [ -e "$pkg" ] || continue
            for img in ${IMAGES[$fam]}; do
                printf '%-44s %-38s ' "$(basename "$pkg")" "${img##*/}"
                if out=$(podman run --rm -v "$pkg:/tmp/$(basename "$pkg"):ro" -e P="/tmp/$(basename "$pkg")" -e BINS="$bins" "$img" \
                        bash -c "${INSTALL[$fam]} && $CHECK" 2>&1); then
                    echo ok
                else
                    echo FAILED; echo "$out" | tail -8 | sed 's/^/    /'; fail=1
                fi
            done
        done
    done
done
exit $fail
