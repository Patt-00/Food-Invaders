#!/usr/bin/env sh
set -eu

repo_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
source_dir="$repo_dir/src"
tests_dir="$repo_dir/tests"
profile=standard
core=both
run_tests=false
nasm_path=${NASM_PATH:-nasm}
dosbox_path=${DOSBOX_X_PATH:-}

usage() {
    cat <<'EOF'
Usage: scripts/build.sh [--profile standard|termux] [--test] [--core normal|dynamic|both] [--nasm PATH] [--dosbox PATH]
Builds Food Invaders into build/<profile> and optionally runs the DOSBox-X suites.
EOF
}

while [ "$#" -gt 0 ]; do
    case "$1" in
        --profile) profile=${2:?Missing profile}; shift 2 ;;
        --core) core=${2:?Missing core}; shift 2 ;;
        --nasm) nasm_path=${2:?Missing NASM path}; shift 2 ;;
        --dosbox) dosbox_path=${2:?Missing DOSBox-X path}; shift 2 ;;
        --test) run_tests=true; shift ;;
        --help|-h) usage; exit 0 ;;
        *) printf 'Unknown option: %s\n' "$1" >&2; usage >&2; exit 2 ;;
    esac
done

case "$profile" in standard|termux) ;; *) printf 'Unsupported profile: %s\n' "$profile" >&2; exit 2 ;; esac
case "$core" in normal|dynamic|both) ;; *) printf 'Unsupported CPU core: %s\n' "$core" >&2; exit 2 ;; esac
if ! command -v "$nasm_path" >/dev/null 2>&1 && [ ! -x "$nasm_path" ]; then
    printf 'NASM not found. Install NASM or pass --nasm PATH.\n' >&2
    exit 1
fi

build_dir="$repo_dir/build/$profile"
test_build_dir="$repo_dir/build/tests"
mkdir -p "$build_dir"
if [ "$profile" = termux ]; then
    "$nasm_path" -DTERMUX_FAST -I "$repo_dir/" -I "$source_dir/" -I "$tests_dir/" -f bin -Wall -w-reloc -Werror "$source_dir/main.asm" -o "$build_dir/INVADERS.COM"
else
    "$nasm_path" -I "$repo_dir/" -I "$source_dir/" -I "$tests_dir/" -f bin -Wall -w-reloc -Werror "$source_dir/main.asm" -o "$build_dir/INVADERS.COM"
fi

check_com_size() {
    size=$(wc -c < "$1" | tr -d '[:space:]')
    if [ "$size" -ge 60000 ]; then
        printf '%s is %s bytes, exceeding the 60,000-byte DOS segment budget.\n' "$(basename "$1")" "$size" >&2
        exit 1
    fi
    printf '%s %s bytes\n' "$(basename "$1")" "$size"
}

printf 'Built profile %s\n' "$profile"
check_com_size "$build_dir/INVADERS.COM"
[ "$run_tests" = true ] || exit 0

mkdir -p "$test_build_dir"
cd "$repo_dir"
"$nasm_path" -I "$repo_dir/" -I "$source_dir/" -I "$tests_dir/" -f bin -Wall -w-reloc -Werror -DCOMPACT_TEST_DISPLAY -DSELFTEST "$source_dir/main.asm" -o "$test_build_dir/TEST.COM"
"$nasm_path" -I "$repo_dir/" -I "$source_dir/" -I "$tests_dir/" -f bin -Wall -w-reloc -Werror -DCOMPACT_TEST_DISPLAY "$tests_dir/player-bullet.asm" -o "$test_build_dir/PBTEST.COM"
"$nasm_path" -I "$repo_dir/" -I "$source_dir/" -I "$tests_dir/" -f bin -Wall -w-reloc -Werror -DCOMPACT_TEST_DISPLAY "$tests_dir/collision.asm" -o "$test_build_dir/COLLTEST.COM"
"$nasm_path" -I "$repo_dir/" -I "$source_dir/" -I "$tests_dir/" -f bin -Wall -w-reloc -Werror -DCOMPACT_TEST_DISPLAY -DSELFTEST -DVISUAL_TEST "$source_dir/main.asm" -o "$test_build_dir/WINTEST.COM"
cp "$tests_dir/RUNTEST.BAT" "$test_build_dir/RUNTEST.BAT"
for binary in TEST.COM PBTEST.COM COLLTEST.COM WINTEST.COM; do
    check_com_size "$test_build_dir/$binary"
done

if [ -z "$dosbox_path" ]; then
    dosbox_path=$(command -v dosbox-x || true)
fi
if [ -z "$dosbox_path" ] && command -v flatpak >/dev/null 2>&1 && flatpak info com.dosbox_x.DOSBox-X >/dev/null 2>&1; then
    dosbox_kind=flatpak
elif [ -n "$dosbox_path" ]; then
    if ! command -v "$dosbox_path" >/dev/null 2>&1 && [ ! -x "$dosbox_path" ]; then
        printf 'DOSBox-X executable not found: %s\n' "$dosbox_path" >&2
        exit 1
    fi
    dosbox_kind=native
else
    printf 'DOSBox-X not found. Install DOSBox-X or pass --dosbox PATH.\n' >&2
    exit 1
fi

run_core() {
    cpu_core=$1
    config="$test_build_dir/dosbox-$cpu_core.conf"
    host_log="$test_build_dir/dosbox-$cpu_core.log"
    cat > "$config" <<EOF
[sdl]
output=surface
[dosbox]
machine=svga_s3
working directory option=noprompt
[cpu]
core=$cpu_core
cputype=386
cycles=max
[mixer]
nosound=true
[ne2000]
ne2000=false
[autoexec]
mount c "$test_build_dir"
c:
RUNTEST.BAT
EOF
    rm -f "$test_build_dir/TESTLOG.TXT" "$test_build_dir/PBLOG.TXT" "$test_build_dir/COLLLOG.TXT" "$test_build_dir/STATUS.TXT"
    if [ "$dosbox_kind" = flatpak ]; then
        SDL_AUDIODRIVER=dummy flatpak run --filesystem="$repo_dir":rw --command=dosbox-x com.dosbox_x.DOSBox-X -silent -nopromptfolder -fastlaunch -conf "$config" > "$host_log" 2>&1
    else
        SDL_AUDIODRIVER=dummy "$dosbox_path" -silent -nopromptfolder -fastlaunch -conf "$config" > "$host_log" 2>&1
    fi
    if [ ! -f "$test_build_dir/STATUS.TXT" ] || [ "$(tr -d '\r\n' < "$test_build_dir/STATUS.TXT")" != PASS ]; then
        for log in TESTLOG.TXT PBLOG.TXT COLLLOG.TXT; do
            [ ! -f "$test_build_dir/$log" ] || cat "$test_build_dir/$log"
        done
        printf 'DOSBox-X %s core tests failed. See %s.\n' "$cpu_core" "$host_log" >&2
        exit 1
    fi
    for log in TESTLOG.TXT PBLOG.TXT COLLLOG.TXT; do
        if ! grep -q '^PASS' "$test_build_dir/$log" || grep -q '^FAIL' "$test_build_dir/$log"; then
            printf 'Missing PASS or found FAIL in %s.\n' "$log" >&2
            exit 1
        fi
    done
    {
        printf 'DOSBox-X, 386 CPU, %s core\n' "$cpu_core"
        cat "$test_build_dir/TESTLOG.TXT" "$test_build_dir/PBLOG.TXT" "$test_build_dir/COLLLOG.TXT"
    } > "$test_build_dir/integrated-$cpu_core-result.txt"
    cat "$test_build_dir/integrated-$cpu_core-result.txt"
}

case "$core" in
    normal) run_core normal ;;
    dynamic) run_core dynamic ;;
    both) run_core normal; run_core dynamic ;;
esac
