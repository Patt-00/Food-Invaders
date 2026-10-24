#!/usr/bin/env sh
set -eu

repo_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
game_dir="$repo_dir/asm-space-invaders-main"

if ! command -v nasm >/dev/null 2>&1; then
    echo "NASM is required. Install NASM, then run this script again." >&2
    exit 1
fi

cd "$game_dir"
nasm -f bin -Wall -w-reloc -Werror main.asm -o INVADERS.COM

if command -v dosbox-x >/dev/null 2>&1; then
    exec dosbox-x -nopromptfolder -fastlaunch -conf "$game_dir/dosbox.conf" -noautoexec \
        -c "mount c \"$game_dir\"" -c 'c:' -c 'INVADERS.COM' -c 'exit'
fi

if command -v flatpak >/dev/null 2>&1 && flatpak info com.dosbox_x.DOSBox-X >/dev/null 2>&1; then
    exec flatpak run --command=dosbox-x --filesystem="$game_dir":rw com.dosbox_x.DOSBox-X \
        -nopromptfolder -fastlaunch -conf "$game_dir/dosbox.conf" -noautoexec \
        -c "mount c \"$game_dir\"" -c 'c:' -c 'INVADERS.COM' -c 'exit'
fi

echo "DOSBox-X is required. Install it natively or install the com.dosbox_x.DOSBox-X Flatpak." >&2
exit 1
