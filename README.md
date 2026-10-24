# Food Invaders

Food Invaders is a 16-bit NASM game for 386-compatible real-mode DOS. You play as the Chef and defend the kitchen from food-themed invaders with a cleaver and rolling pin. The 132 by 88 SVGA text board launches full-screen in DOSBox-X and preserves its 3:2 shape. The Chef, enemies, weapons, and pickups render at half their source artwork dimensions.

## Run on Linux

Install NASM and DOSBox-X, then run this script from the repository root:

```sh
./run-linux.sh
```

The script builds `INVADERS.COM` from `main.asm` and launches the game. It uses a native `dosbox-x` command when available, or the DOSBox-X Flatpak when installed. The preset uses `cycles=max`, which can increase CPU use, heat, and battery drain on mobile devices.

## Run on Termux

Install NASM and DOSBox-X in Termux. Install the Termux:X11 app and companion package, and make sure `xdpyinfo` is available. Then run:

```sh
./run-termux.sh
```

The game uses DOSBox-X's SVGA S3 mode. Its launcher fills the Termux:X11 display while preserving the board's proportions. A plain text-only Termux session is not enough for the game window.

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

The four regular waves place enemies at random positions across the playfield. Each enemy then takes independent random steps on both axes, avoids the other enemies, and stays above a safety line eight rows above the Chef. Later waves add shooters and increase movement and bullet speed. A 20 HP Ratatouille boss follows the fourth wave. Enemy bullets use a single text cell and move once every 50 to 80 milliseconds, depending on the wave; the 50 ms game tick sets the fastest rate.

## Project details

The [game README](asm-space-invaders-main/README.md) covers wave behavior, the playable text-mode reference, module roles, and manual test commands. Recorded DOSBox-X results are available for the [normal CPU core](asm-space-invaders-main/tests/integrated-normal-result.txt) and [dynamic CPU core](asm-space-invaders-main/tests/integrated-dynamic-result.txt).
