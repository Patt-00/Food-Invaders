#!/usr/bin/env sh
set -eu

if [ "$#" -ne 2 ]; then
    printf 'Usage: %s TARGET VERSION\n' "$0" >&2
    printf 'Targets: ubuntu24.04, debian13, fedora44\n' >&2
    exit 2
fi
target=$1
version=$2
case "$target" in
    ubuntu24.04|debian13) format=deb ;;
    fedora44) format=rpm ;;
    *) printf 'Unsupported release target: %s\n' "$target" >&2; exit 2 ;;
esac

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
work_root="$repo_root/build/release/$target"
source_archive="$work_root/dosbox-x-v2026.10.01.tar.gz"
runtime_dest="$work_root/runtime-stage"
output_dir="$repo_root/dist"
source_url=https://codeload.github.com/joncampbell123/dosbox-x/tar.gz/refs/tags/dosbox-x-v2026.10.01
expected_source_sha=df023a6c0e4a139dcbd60befff5947e0db2cc68e4e79db463670f581a4044ed4

mkdir -p "$work_root" "$output_dir"
if [ ! -f "$source_archive" ]; then
    curl --fail --location --retry 4 --retry-all-errors --connect-timeout 20 --max-time 900 \
        "$source_url" --output "$source_archive"
fi
actual_source_sha=$(sha256sum "$source_archive" | awk '{print $1}')
if [ "$actual_source_sha" != "$expected_source_sha" ]; then
    printf 'Pinned DOSBox-X source SHA-256 mismatch: %s\n' "$actual_source_sha" >&2
    exit 1
fi

"$repo_root/scripts/build.sh" --profile standard
"$repo_root/packaging/linux/build-dosbox-x.sh" "$source_archive" "$runtime_dest"
runtime_root="$runtime_dest/opt/food-invaders/runtime"
SDL_VIDEODRIVER=dummy SDL_AUDIODRIVER=dummy \
    "$repo_root/scripts/build.sh" --test --core both --dosbox "$runtime_root/bin/dosbox-x"
"$repo_root/packaging/linux/build-package.sh" \
    --format "$format" --target "$target" --version "$version" \
    --runtime-root "$runtime_root" --dosbox-source "$source_archive" \
    --game-com "$repo_root/build/standard/INVADERS.COM" --output-dir "$output_dir"

package=$(find "$output_dir" -maxdepth 1 -type f -name "food-invaders-$version-$target-*" -print -quit)
if [ -z "$package" ]; then printf 'Package output is missing for %s.\n' "$target" >&2; exit 1; fi
case "$format" in
    deb)
        dpkg-deb --contents "$package" | grep -q '/opt/food-invaders/game/INVADERS.COM$'
        dpkg-deb --contents "$package" | grep -q '/usr/share/doc/food-invaders/third-party/dosbox-x-source.tar.gz$'
        dpkg-deb --contents "$package" | grep -q '/usr/share/doc/food-invaders/LICENSE$'
        dpkg-deb --contents "$package" | grep -q '/usr/share/doc/food-invaders/third-party/DOSBox-X-COPYING$'
        dpkg-deb --contents "$package" | grep -q '/usr/share/doc/food-invaders/third-party/DOSBox-X-SOURCE.txt$'
        ;;
    rpm)
        rpm -qpl "$package" | grep -q '^/opt/food-invaders/game/INVADERS.COM$'
        rpm -qpl "$package" | grep -q '^/usr/share/doc/food-invaders/third-party/dosbox-x-source.tar.gz$'
        rpm -qpl "$package" | grep -q '^/usr/share/doc/food-invaders/LICENSE$'
        rpm -qpl "$package" | grep -q '^/usr/share/doc/food-invaders/third-party/DOSBox-X-COPYING$'
        rpm -qpl "$package" | grep -q '^/usr/share/doc/food-invaders/third-party/DOSBox-X-SOURCE.txt$'
        ;;
esac
echo "Built and inspected $package"
