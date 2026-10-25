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
# Use the full Termux:X11 display while preserving the board's 3:2 ratio.
# Character artwork is rendered at its documented text-cell dimensions.
set -- $(xdpyinfo -display "$DISPLAY" | awk '/dimensions:/ {split($2, size, "x"); print size[1], size[2]; exit}')
display_width=$1
display_height=$2
config_file=$(mktemp)
trap 'rm -f "$config_file"' EXIT
cat > "$config_file" <<EOF
[sdl]
output=openglnb
fullscreen=true
fullresolution=desktop
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

# Termux X11/SDL2 can retain the old blank surface after VGA raster changes.
# Re-expose only this emulator's window once its final geometry is available.
if command -v xdotool >/dev/null 2>&1; then
    attempts=0
    while kill -0 "$emulator_pid" 2>/dev/null && [ "$attempts" -lt 30 ]; do
        window_id=$(xdotool search --pid "$emulator_pid" --name DOSBox 2>/dev/null | head -n 1 || true)
        if [ -n "$window_id" ] && xdotool getwindowgeometry --shell "$window_id" 2>/dev/null |
            awk -F= -v expected_width="$display_width" -v expected_height="$display_height" '/^WIDTH=/ {w=$2} /^HEIGHT=/ {h=$2} END {exit !(w==expected_width && h==expected_height)}'; then
            sleep 0.3
            xdotool windowunmap "$window_id" windowmap "$window_id" windowfocus "$window_id" || true
            break
        fi
        attempts=$((attempts + 1))
        sleep 0.1
    done
fi
wait "$emulator_pid"
