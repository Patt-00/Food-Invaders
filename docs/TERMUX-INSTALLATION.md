# Install and run Food Invaders on Termux

Food Invaders runs on Android through Termux, DOSBox-X, and Termux:X11. The `run-termux.sh` launcher builds the DOS game, starts the X server when needed, opens the Termux:X11 app, then sizes and centers a DOSBox-X window to fill the display at the game's 3:2 ratio. Termux:X11 requires Android 8 or later, its Android app, and its companion Termux package, as described in the [official setup instructions](https://github.com/termux/termux-x11#setup-instructions).

## Requirements

- An Android device running Android 8 or later.
- Termux installed from an official source.
- The regular Termux:X11 universal APK and the Termux:X11 companion package.
- A network connection to install packages and download the source.
- A keyboard for the game's controls.

The launcher uses NASM to build `INVADERS.COM`, DOSBox-X to run the game, and `xdpyinfo` to check the X display. The X11 repository provides DOSBox-X and the Termux:X11 companion package. See the [DOSBox-X package recipe](https://github.com/termux/termux-packages/blob/master/x11-packages/dosbox-x/build.sh) and [Termux:X11 setup instructions](https://github.com/termux/termux-x11#setup-instructions).

## Install the Android apps

1. Install Termux from [F-Droid](https://f-droid.org/en/packages/com.termux/) or the [official Termux GitHub releases](https://github.com/termux/termux-app/releases). The Termux project documents its supported installation sources in the [installation guide](https://github.com/termux/termux-app#installation). If Termux is already installed and package commands work, keep using that installation.
2. Open the [Termux:X11 nightly releases](https://github.com/termux/termux-x11/releases/tag/nightly) on your Android device.
3. Download and install `termux-x11-universal-debug.apk` from the release assets. If Android asks, allow your browser to install this APK.
4. Use the regular universal APK. The `sharedUid` APK variant requires a GitHub-signed Termux installation, as noted by the [Termux:X11 project](https://github.com/termux/termux-x11#avoiding-slowdowns).
5. Open Termux once and wait for its first setup to finish.

## Install the Termux packages

Run these commands in the Termux app:

```sh
pkg update
pkg upgrade
pkg install x11-repo
pkg update
pkg install git nasm dosbox-x termux-x11-nightly xorg-xdpyinfo xdotool
```

Confirm that Termux can find the launcher tools:

```sh
command -v git nasm dosbox-x termux-x11 xdpyinfo xdotool
nasm -v
```

The `x11-repo` package enables the graphical package repository. The `termux-x11-nightly` package installs the X server command, while the Android APK provides its display window. NASM builds the game, Git downloads its source, `xorg-xdpyinfo` reads the display size, and `xdotool` re-exposes the window after the text-mode timing change.

## Download the game

Clone the project into Termux's home directory:

```sh
cd "$HOME"
git clone https://github.com/Patt-00/Food-Invaders.git
cd Food-Invaders
chmod +x run-termux.sh
```

If you already cloned the project, open its folder instead:

```sh
cd "$HOME/Food-Invaders"
```

## Launch the game

Run the launcher from the repository folder:

```sh
./run-termux.sh
```

The launcher assembles `main.asm`, starts the X server on display `:0` if needed, opens Termux:X11, and sizes the DOSBox-X window to the largest centered 3:2 rectangle that fits the display. Keep Termux:X11 open while you play.

The launcher builds a Termux fast profile with a 25 ms frame wait, then runs DOSBox-X with `core=dynamic` and `cycles=max`. It sets `frameskip=1`, so DOSBox-X skips alternate screen redraws while the game still processes every update. This speeds up gameplay on the Xiaomi Pad 7; motion is less smooth, and performance varies by device. Desktop builds keep their existing timing. Maximum CPU speed can use more battery and warm the device during a long session.

## Controls

| Key | Action |
| --- | --- |
| `1`, `2`, or `3` | Start on Easy, Normal, or Hard |
| `P` or Space | Start on Normal |
| A/D or arrow keys | Move the Chef |
| Space | Fire a cleaver |
| `X` | Fire a rolling pin |
| `R` | Restart after a result screen |
| `Q` or Escape | Quit |

## Troubleshooting

### `Unable to locate package dosbox-x`

Enable the X11 repository, refresh the package list, then install the packages again:

```sh
pkg install x11-repo
pkg update
pkg install dosbox-x termux-x11-nightly xorg-xdpyinfo xdotool
```

### `nasm: command not found`

Install NASM from the Termux package repository:

```sh
pkg install nasm
```

### The launcher reports that X11 did not start

Check that you installed both the Termux:X11 Android app and the `termux-x11-nightly` package. Open Termux:X11 once from Android, return to Termux, and rerun the launcher. If it still fails, read the launch log:

```sh
cat "$HOME/Food-Invaders/termux-x11.log"
```

### `xdpyinfo` cannot open the display

The X server may not be running. Start it and open its Android window, then check display `:0`:

```sh
termux-x11 :0 >/dev/null 2>&1 &
am start -n com.termux.x11/.MainActivity
xdpyinfo -display :0 | head
```

When the display responds, run `./run-termux.sh` again from the `Food-Invaders` folder.

### The game window is black or stops updating

Close DOSBox-X and Termux:X11, reopen Termux:X11, then run `./run-termux.sh` again. The launcher writes X server startup errors to `termux-x11.log` in the repository folder.

## Update the source

To download the latest committed changes and rebuild the game, run:

```sh
cd "$HOME/Food-Invaders"
git pull
./run-termux.sh
```
