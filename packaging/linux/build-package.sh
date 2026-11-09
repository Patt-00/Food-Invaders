#!/usr/bin/env sh
set -eu

format=
target=
version=
runtime_root=
source_archive=
game_com=
output_dir=

usage() {
    cat <<'EOF'
Usage: build-package.sh --format deb|rpm --target ubuntu24.04|debian13|fedora44 \
  --version VERSION --runtime-root DIR --dosbox-source FILE --game-com FILE --output-dir DIR
The runtime root is the installed DOSBox-X prefix containing bin/dosbox-x.
EOF
}

while [ "$#" -gt 0 ]; do
    case "$1" in
        --format) format=${2:?Missing format}; shift 2 ;;
        --target) target=${2:?Missing target}; shift 2 ;;
        --version) version=${2:?Missing version}; shift 2 ;;
        --runtime-root) runtime_root=${2:?Missing runtime root}; shift 2 ;;
        --dosbox-source) source_archive=${2:?Missing DOSBox-X source archive}; shift 2 ;;
        --game-com) game_com=${2:?Missing game binary}; shift 2 ;;
        --output-dir) output_dir=${2:?Missing output directory}; shift 2 ;;
        --help|-h) usage; exit 0 ;;
        *) printf 'Unknown argument: %s\n' "$1" >&2; usage >&2; exit 2 ;;
    esac
done

case "$format:$target" in
    deb:ubuntu24.04|deb:debian13|rpm:fedora44) ;;
    *) printf 'Unsupported package target: %s / %s\n' "$format" "$target" >&2; exit 2 ;;
esac
case "$version" in
    ''|*[!A-Za-z0-9.+~-]*) printf 'Invalid package version: %s\n' "$version" >&2; exit 2 ;;
esac
for path in "$runtime_root/bin/dosbox-x" "$source_archive" "$game_com"; do
    if [ ! -f "$path" ]; then printf 'Required input missing: %s\n' "$path" >&2; exit 1; fi
done
actual_source_sha=$(sha256sum "$source_archive" | awk '{print $1}')
expected_source_sha=df023a6c0e4a139dcbd60befff5947e0db2cc68e4e79db463670f581a4044ed4
if [ "$actual_source_sha" != "$expected_source_sha" ]; then
    printf 'Pinned DOSBox-X source SHA-256 mismatch: %s\n' "$actual_source_sha" >&2
    exit 1
fi
mkdir -p "$output_dir"
output_dir=$(CDPATH= cd -- "$output_dir" && pwd)
workdir=$(mktemp -d)
trap 'rm -rf "$workdir"' EXIT HUP INT TERM
stage="$workdir/root"
mkdir -p "$stage/opt/food-invaders/runtime" \
    "$stage/opt/food-invaders/game" "$stage/opt/food-invaders/config" \
    "$stage/usr/bin" "$stage/usr/share/applications" \
    "$stage/usr/share/doc/food-invaders/third-party"

cp -a "$runtime_root/." "$stage/opt/food-invaders/runtime/"
install -m 0644 "$game_com" "$stage/opt/food-invaders/game/INVADERS.COM"
install -m 0644 "$(dirname "$0")/../dosbox/desktop.conf" "$stage/opt/food-invaders/config/desktop.conf"
install -m 0755 "$(dirname "$0")/food-invaders" "$stage/usr/bin/food-invaders"
install -m 0644 "$(dirname "$0")/food-invaders.desktop" "$stage/usr/share/applications/food-invaders.desktop"
install -m 0644 "$(dirname "$0")/../../LICENSE" "$stage/usr/share/doc/food-invaders/LICENSE"
install -m 0644 "$(dirname "$0")/../../README.md" "$stage/usr/share/doc/food-invaders/README.md"
install -m 0644 "$(dirname "$0")/../../CONTRIBUTORS.md" "$stage/usr/share/doc/food-invaders/CONTRIBUTORS.md"
install -m 0644 "$(dirname "$0")/../../THIRD-PARTY-NOTICES.md" "$stage/usr/share/doc/food-invaders/THIRD-PARTY-NOTICES.md"
install -m 0644 "$source_archive" "$stage/usr/share/doc/food-invaders/third-party/dosbox-x-source.tar.gz"
tar -xOf "$source_archive" --wildcards '*/COPYING' > "$stage/usr/share/doc/food-invaders/third-party/DOSBox-X-COPYING"
source_sha=$(sha256sum "$source_archive" | awk '{print $1}')
cat > "$stage/usr/share/doc/food-invaders/third-party/DOSBox-X-SOURCE.txt" <<EOF
DOSBox-X version: 2026.10.01
Tag: dosbox-x-v2026.10.01
Commit: b6abbd5980a885f5f310a4088c59a8688d1b116c
Source: https://github.com/joncampbell123/dosbox-x/releases/tag/dosbox-x-v2026.10.01
Included archive: dosbox-x-source.tar.gz
SHA-256: $source_sha
License: GNU GPL version 2 (see DOSBox-X-COPYING)
EOF

case "$format" in
    deb)
        command -v dpkg-deb >/dev/null 2>&1 || { echo 'dpkg-deb is required.' >&2; exit 1; }
        command -v dpkg-shlibdeps >/dev/null 2>&1 || { echo 'dpkg-shlibdeps from dpkg-dev is required.' >&2; exit 1; }
        mkdir -p "$workdir/debian"
        cat > "$workdir/debian/control" <<'EOF'
Source: food-invaders
Section: games
Priority: optional
Maintainer: Food Invaders contributors <318558214+Patt-00@users.noreply.github.com>
Standards-Version: 4.6.2

Package: food-invaders
Architecture: amd64
Description: NASM arcade game with DOSBox-X bundled
 Food Invaders is a 16-bit DOS arcade game with original colored ASCII art.
 This package includes the DOSBox-X runtime and its corresponding source.
EOF
        depends_line=$(CDPATH= cd -- "$workdir" && dpkg-shlibdeps -O -e "$stage/opt/food-invaders/runtime/bin/dosbox-x" | sed -n 's/^shlibs:Depends=//p')
        if [ -z "$depends_line" ]; then echo 'Could not derive Debian shared-library dependencies.' >&2; exit 1; fi
        mkdir -p "$stage/DEBIAN"
        cat > "$stage/DEBIAN/control" <<EOF
Package: food-invaders
Version: $version
Section: games
Priority: optional
Architecture: amd64
Maintainer: Food Invaders contributors <318558214+Patt-00@users.noreply.github.com>
Depends: $depends_line
Description: NASM arcade game with DOSBox-X bundled
 Food Invaders is a 16-bit DOS arcade game with original colored ASCII art.
 This package includes the DOSBox-X runtime and its corresponding source.
EOF
        dpkg-deb --build --root-owner-group "$stage" "$output_dir/food-invaders-$version-$target-amd64.deb"
        ;;
    rpm)
        command -v rpmbuild >/dev/null 2>&1 || { echo 'rpmbuild is required.' >&2; exit 1; }
        topdir="$workdir/rpmbuild"
        mkdir -p "$topdir/BUILD" "$topdir/BUILDROOT" "$topdir/RPMS" "$topdir/SOURCES" "$topdir/SPECS" "$topdir/SRPMS"
        tar -czf "$topdir/SOURCES/food-invaders-stage.tar.gz" -C "$stage" .
        cp "$(dirname "$0")/food-invaders.spec" "$topdir/SPECS/food-invaders.spec"
        rpmbuild -bb "$topdir/SPECS/food-invaders.spec" \
            --define "_topdir $topdir" --define "release_version $version"
        built_rpm=$(find "$topdir/RPMS" -type f -name "food-invaders-$version-1*.x86_64.rpm" -print -quit)
        if [ -z "$built_rpm" ]; then echo 'rpmbuild did not produce the expected x86_64 RPM.' >&2; exit 1; fi
        cp "$built_rpm" "$output_dir/food-invaders-$version-$target-x86_64.rpm"
        ;;
esac

echo "Package build finished for $format target $target."
