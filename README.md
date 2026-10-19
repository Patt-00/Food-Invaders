# Food Invaders

Food Invaders is a 16-bit NASM game for real-mode DOS. It renders the team's Chef, food enemies, Ratatouille, weapons, and fireball ASCII art in a 132 by 88 SVGA text screen. Eight-pixel cells produce a 1056 by 704 gameplay field with a 3:2 ratio. Run it in DOSBox-X with `machine=svga_s3`.

The Chef fights independently moving food enemies with cleavers and rolling pins. The game has Easy, Normal, and Hard settings, a falling fireball power-up, four regular stages, and a final Ratatouille boss.

See [build instructions, controls, architecture, and tests](asm-space-invaders-main/README.md). The player and weapon contribution is documented in [DEVELOPER2.md](asm-space-invaders-main/DEVELOPER2.md).
