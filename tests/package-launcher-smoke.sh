#!/usr/bin/env sh
set -eu

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
tmp=$(mktemp -d "${TMPDIR:-/tmp}/Food Invaders launcher.XXXXXX")
trap 'rm -rf "$tmp"' EXIT HUP INT TERM
app_root="$tmp/app root"
mkdir -p "$app_root/runtime/bin" "$app_root/game" "$app_root/config"
install -m 0644 /dev/null "$app_root/game/INVADERS.COM"
install -m 0644 "$repo_root/packaging/dosbox/desktop.conf" "$app_root/config/desktop.conf"
cat > "$app_root/runtime/bin/dosbox-x" <<'EOF'
#!/bin/sh
printf '%s\n' "$@" > "$DOSBOX_TEST_ARGS"
EOF
chmod +x "$app_root/runtime/bin/dosbox-x"

DOSBOX_TEST_ARGS="$tmp/arguments.txt" FOOD_INVADERS_ROOT="$app_root" \
    "$repo_root/packaging/linux/food-invaders"
grep -Fx -- '-nopromptfolder' "$tmp/arguments.txt" >/dev/null
grep -Fx -- '-conf' "$tmp/arguments.txt" >/dev/null
grep -Fx -- "$app_root/config/desktop.conf" "$tmp/arguments.txt" >/dev/null
grep -Fx -- "mount c \"$app_root/game\"" "$tmp/arguments.txt" >/dev/null
grep -Fx -- 'INVADERS.COM' "$tmp/arguments.txt" >/dev/null

echo 'PASS: Linux package launcher passes the game path and DOSBox-X config.'
