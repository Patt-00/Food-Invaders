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
sleep 1

# Termux:X11 can leave SDL2 in a 640x400 window even when the config requests
# fullscreen. Toggle DOSBox-X's Linux fullscreen hotkey after the game sets its
# video mode, then keep the resulting fullscreen window focused.
if command -v xdotool >/dev/null 2>&1; then
    attempts=0
    fullscreen_requested=0
    while kill -0 "$emulator_pid" 2>/dev/null && [ "$attempts" -lt 30 ]; do
        window_id=$(xdotool search --pid "$emulator_pid" --name DOSBox 2>/dev/null | head -n 1 || true)
        if [ -n "$window_id" ]; then
            if xdotool getwindowgeometry --shell "$window_id" 2>/dev/null |
                awk -F= -v min_width="$((display_width*80/100))" -v min_height="$((display_height*80/100))" '/^WIDTH=/ {w=$2} /^HEIGHT=/ {h=$2} END {exit !(w>=min_width && h>=min_height)}'; then
                xdotool windowfocus "$window_id" || true
                break
            elif [ "$fullscreen_requested" -eq 0 ]; then
                xdotool windowfocus "$window_id" key --clearmodifiers F12+f || true
                fullscreen_requested=1
            fi
        fi
        attempts=$((attempts + 1))
        sleep 0.1
    done
    if [ "$fullscreen_requested" -eq 1 ] && [ "$attempts" -ge 30 ]; then
        echo "DOSBox-X stayed windowed after fullscreen attempts; check Termux:X11." >&2
    fi
fi
wait "$emulator_pid"
