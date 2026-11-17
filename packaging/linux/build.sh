#!/bin/bash
# build.sh [arch|deb|rpm|all] [APP…] — the Linux packages, each built in a container of
# its own family so it links against that family's libraries and glibc.
#
#   ./build.sh                 every family, every application
#   ./build.sh deb lipi        one family, one application
#
# Needs podman. Reads the applications from ../../.. (the Andolika tree: sulekha, lipi,
# dekho, dakia, common beside one another) read-only, keeps cargo's work in named
# volumes between runs, and writes the packages into each application's folder of this
# repository, beside its Windows and macOS installers. Then run test.sh.
set -euo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
REPO=$(cd "$HERE/../.." && pwd)
TREE=${ANDOLIKA_TREE:-$(cd "$REPO/.." && pwd)}
FAMILY=${1:-all}; shift || true
APPS=("$@"); [ ${#APPS[@]} -gt 0 ] || APPS=(sulekha lipi dekho dakia)
case $FAMILY in all) FAMILIES=(arch deb rpm) ;; arch|deb|rpm) FAMILIES=("$FAMILY") ;; *) echo "family: arch, deb, rpm or all" >&2; exit 2 ;; esac
declare -A FILE=([arch]=Containerfile.arch [deb]=Containerfile.debian [rpm]=Containerfile.fedora)

OUT=$(mktemp -d)
trap 'rm -rf "$OUT"' EXIT
LOGS=${LOGDIR:-${TMPDIR:-/tmp}/andolika-linux-logs}
mkdir -p "$LOGS"
pids=()
for f in "${FAMILIES[@]}"; do
    podman build -q -t "andolika-build-$f" -f "$HERE/${FILE[$f]}" "$HERE" >/dev/null
    mkdir -p "$OUT/$f"
    # The families build at once; each keeps its own logs.
    podman run --rm \
        -v "$TREE:/src:ro" -v "$HERE:/pkg:ro" -v "$OUT/$f:/out" \
        -v "andolika-build-$f-target:/build" -v "andolika-build-$f-registry:/opt/cargo/registry" \
        "andolika-build-$f" bash /pkg/inside.sh "$f" "${APPS[@]}" > "$LOGS/$f.log" 2>&1 &
    pids+=("$!:$f")
done
fail=0
for p in "${pids[@]}"; do
    if wait "${p%%:*}"; then echo "${p#*:}: built"; else echo "${p#*:}: FAILED, last lines of the log:"; tail -20 "$LOGS/${p#*:}.log"; fail=1; fi
done
for f in "${FAMILIES[@]}"; do
    for pkg in "$OUT/$f"/*; do
        [ -e "$pkg" ] || continue
        name=$(basename "$pkg"); app=$(echo "${name%%-*}" | tr 'A-Z' 'a-z')
        mkdir -p "$REPO/$app"; cp "$pkg" "$REPO/$app/"; echo "  $app/$name"
    done
done
exit $fail
