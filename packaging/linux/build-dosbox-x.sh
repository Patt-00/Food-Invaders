#!/usr/bin/env sh
set -eu

if [ "$#" -ne 2 ]; then
    printf 'Usage: %s DOSBOX_X_SOURCE.tar.gz DESTDIR\n' "$0" >&2
    exit 2
fi
source_archive=$(CDPATH= cd -- "$(dirname -- "$1")" && pwd)/$(basename -- "$1")
destdir=$2
jobs=${JOBS:-2}
mkdir -p "$destdir"
destdir=$(CDPATH= cd -- "$destdir" && pwd)
workdir=$(mktemp -d)
trap 'rm -rf "$workdir"' EXIT HUP INT TERM

command -v tar >/dev/null 2>&1 || { echo 'tar is required.' >&2; exit 1; }
command -v make >/dev/null 2>&1 || { echo 'make is required.' >&2; exit 1; }
command -v gcc >/dev/null 2>&1 || { echo 'gcc is required.' >&2; exit 1; }

mkdir "$workdir/source"
tar -xzf "$source_archive" -C "$workdir/source" --strip-components=1
cd "$workdir/source"
./autogen.sh
./configure --prefix=/opt/food-invaders/runtime --enable-sdl2
make -j"$jobs"
make DESTDIR="$destdir" install

binary="$destdir/opt/food-invaders/runtime/bin/dosbox-x"
if [ ! -x "$binary" ]; then
    printf 'DOSBox-X install did not produce %s\n' "$binary" >&2
    exit 1
fi
version_output=$("$binary" -version 2>&1 || true)
printf '%s\n' "$version_output"
if ! printf '%s\n' "$version_output" | grep -F 'DOSBox-X version 2026.10.01' >/dev/null; then
    printf 'The bundled emulator did not report DOSBox-X 2026.10.01.\n' >&2
    exit 1
fi
