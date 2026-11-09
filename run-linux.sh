#!/usr/bin/env sh
set -eu

repo_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
game_dir="$repo_dir/build/standard"
config_file="$repo_dir/packaging/dosbox/desktop.conf"

if ! command -v nasm >/dev/null 2>&1; then
    echo "NASM is required. Install NASM, then run this script again." >&2
    exit 1
fi

"$repo_dir/scripts/build.sh" --profile standard

if [ -n "${DOSBOX_X_PATH:-}" ]; then
    dosbox_path=$DOSBOX_X_PATH
elif command -v dosbox-x >/dev/null 2>&1; then
    dosbox_path=$(command -v dosbox-x)
elif command -v flatpak >/dev/null 2>&1 && flatpak info com.dosbox_x.DOSBox-X >/dev/null 2>&1; then
    exec flatpak run --command=dosbox-x --filesystem="$repo_dir":rw com.dosbox_x.DOSBox-X \
        -nopromptfolder -fastlaunch -conf "$config_file" -noautoexec \
        -c "mount c \"$game_dir\"" -c 'c:' -c 'INVADERS.COM' -c 'exit'
else
    echo "DOSBox-X is required. Install it natively, through Flatpak, or set DOSBOX_X_PATH." >&2
    exit 1
fi

exec "$dosbox_path" -nopromptfolder -fastlaunch -conf "$config_file" -noautoexec \
    -c "mount c \"$game_dir\"" -c 'c:' -c 'INVADERS.COM' -c 'exit'
