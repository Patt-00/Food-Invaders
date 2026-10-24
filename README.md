# Food Invaders

Food Invaders is a 16-bit NASM game for 386-compatible real-mode DOS. You play as the Chef and defend the kitchen from food-themed invaders with a cleaver and rolling pin. The game renders colored ASCII art in a 132 by 88 SVGA text screen and runs in DOSBox-X with `machine=svga_s3`.

## Run on Linux

Install NASM and DOSBox-X, then run this script from the repository root:

```sh
./run-linux.sh
```

The script builds `INVADERS.COM` from `main.asm` and launches the game. It uses a native `dosbox-x` command when available, or the DOSBox-X Flatpak when installed.

## Run on Termux

Install NASM and DOSBox-X in Termux. Install the Termux:X11 app and companion package, and make sure `xdpyinfo` is available. Then run:

```sh
./run-termux.sh
```

The game uses DOSBox-X's SVGA S3 mode, so a plain text-only Termux session is not enough for the Food Invaders window.

## Controls

| Key | Action |
| --- | --- |
| A/D or arrow keys | Move the Chef |
| Space | Fire a cleaver |
| X | Fire a rolling pin |
| 1, 2, or 3 | Start on Easy, Normal, or Hard |
| P or Space | Start on Normal |
| R | Restart after a result screen |
| Q or Escape | Quit |

The four regular waves use distinct formations and spread shooters across the left, middle, and right lanes. Enemy movement and fire speed up by wave, followed by a 20 HP Ratatouille boss.

## Gameplay reference

Food Invaders uses the Space Invaders game loop as its premise. For a playable text-mode example, see [doctorfree/ninvaders at revision `dc38ab8`](https://github.com/doctorfree/ninvaders/tree/dc38ab8db9ecdb5f69fbd3b3deb42e253d6f08c3). It uses C and ncurses, and its CMake build ran in Linux and Termux on 2026-10-24. This project keeps its own NASM and DOSBox-X implementation.

## Project details

The game source, manual build steps, controls, module overview, and regression-test instructions are in [asm-space-invaders-main/README.md](asm-space-invaders-main/README.md). Recorded DOSBox-X results are available for the [normal CPU core](asm-space-invaders-main/tests/integrated-normal-result.txt) and [dynamic CPU core](asm-space-invaders-main/tests/integrated-dynamic-result.txt).
