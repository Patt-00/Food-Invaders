#!/data/data/com.termux/files/usr/bin/sh
set -eu

repo_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
game_dir="$repo_dir/asm-space-invaders-main"
export DISPLAY="${DISPLAY:-:0}"
export SDL_VIDEODRIVER=x11
export SDL_AUDIODRIVER=dummy

if ! command -v dosbox-x >/dev/null 2>&1; then
    echo "Install DOSBox-X for the 180x120 battlefield: pkg install dosbox-x" >&2
    exit 1
fi

cd "$game_dir"
nasm -f bin main.asm -o INVADERS.COM

if ! xdpyinfo -display "$DISPLAY" >/dev/null 2>&1; then
    termux-x11 "$DISPLAY" > "$repo_dir/termux-x11.log" 2>&1 &
    attempts=0
    until xdpyinfo -display "$DISPLAY" >/dev/null 2>&1; do
        attempts=$((attempts + 1))
        if [ "$attempts" -ge 10 ]; then
            echo "X11 did not start. Check $repo_dir/termux-x11.log" >&2
            exit 1
        fi
        sleep 1
    done
fi

am start -n com.termux.x11/.MainActivity >/dev/null 2>&1 || true
# Wait for the Android X11 surface to attach before SDL opens its window.
sleep 1
# Use the full Termux:X11 display while preserving the board's 3:2 ratio.
# Character artwork is rendered at its documented text-cell dimensions.
set -- $(xdpyinfo -display "$DISPLAY" | awk '/dimensions:/ {split($2, size, "x"); print size[1], size[2]; exit}')
display_width=$1
display_height=$2
if [ "$((display_width*2))" -le "$((display_height*3))" ]; then
    window_width=$display_width
    window_height=$((display_width*2/3))
else
    window_height=$display_height
    window_width=$((display_height*3/2))
fi
window_x=$(((display_width-window_width)/2))
window_y=$(((display_height-window_height)/2))
config_file=$(mktemp)
trap 'rm -f "$config_file"' EXIT
cat > "$config_file" <<EOF
[sdl]
output=openglnb
fullscreen=false
fullresolution=desktop
windowresolution=${window_width}x${window_height}
windowposition=${window_x},${window_y}
autolock=false
[dosbox]
machine=svga_s3
working directory option=noprompt
[render]
scaler=none
aspect=true
aspect_ratio=3:2
modeswitch=false
glshader=none
[cpu]
cycles=max
[midi]
mididevice=none
EOF

dosbox-x -nopromptfolder -fastlaunch -nomenu -conf "$config_file" -c "mount c \"$game_dir\"" -c 'c:' -c 'INVADERS.COM' -c 'exit' &
emulator_pid=$!

wait "$emulator_pid"
