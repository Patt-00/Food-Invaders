; Shared game data and constants.  This file is included once by main.asm.

SCREEN_WIDTH    equ 132
SCREEN_HEIGHT   equ 120
PLAYFIELD_TOP   equ 1        ; Row zero belongs to the HUD.
PLAYER_WIDTH    equ 12
PLAYER_HEIGHT   equ 16
SOURCE_ART_WIDTH equ 12
SOURCE_ART_HEIGHT equ 16
WEAPON_SCALE    equ 2        ; Reduce only weapon artwork in the renderer.
WEAPON_WIDTH    equ SOURCE_ART_WIDTH / WEAPON_SCALE
WEAPON_HEIGHT   equ SOURCE_ART_HEIGHT / WEAPON_SCALE
BULLET_SPEED    equ 3        ; Rows per update; independent of firing cooldown.
HOSTILE_SHOT_WIDTH equ 2
HOSTILE_SHOT_HEIGHT equ 2
HOSTILE_SHOT_STEP_MS equ 200 ; Enemy shots advance more slowly than each 50 ms game tick.
PLAYER_DANGER_WIDTH equ 4   ; Narrow center of the Chef is vulnerable to enemy shots.
PLAYER_DANGER_HEIGHT equ 6
PLAYER_DANGER_X equ (PLAYER_WIDTH - PLAYER_DANGER_WIDTH) / 2
PLAYER_DANGER_Y equ (PLAYER_HEIGHT - PLAYER_DANGER_HEIGHT) / 2

; VGA 32 KiB text memory and 8-bit coordinates bound this display mode.
%if SCREEN_WIDTH != 132 || SCREEN_HEIGHT != 120
    %error "Display timing is configured for 132x120 cells"
%endif
%if SCREEN_WIDTH * SCREEN_HEIGHT * 2 > 32768
    %error "Text frame must fit in VGA text memory"
%endif

; Keep the chef at source size; halve weapon width and height at draw time.
%if PLAYER_WIDTH != SOURCE_ART_WIDTH || PLAYER_HEIGHT != SOURCE_ART_HEIGHT
    %error "Player dimensions must match source artwork dimensions"
%endif
%if WEAPON_SCALE != 2 || WEAPON_WIDTH * WEAPON_SCALE != SOURCE_ART_WIDTH || WEAPON_HEIGHT * WEAPON_SCALE != SOURCE_ART_HEIGHT
    %error "Weapon renderer requires exact 2x2 source blocks"
%endif
%if BULLET_SPEED < 1 || BULLET_SPEED > WEAPON_HEIGHT
    %error "Projectile steps must stay within sprite height to avoid skipped collisions"
%endif
%if PLAYER_DANGER_WIDTH < 1 || PLAYER_DANGER_WIDTH > PLAYER_WIDTH || PLAYER_DANGER_HEIGHT < 1 || PLAYER_DANGER_HEIGHT > PLAYER_HEIGHT
    %error "Enemy-shot vulnerable area must fit inside the Chef sprite"
%endif
MAX_BULLETS     equ 3
CLEAVER         equ 0
ROLLING_PIN     equ 1
NORMAL_COOLDOWN equ 24        ; Frames; main loop waits roughly 50 ms.
BOOST_COOLDOWN  equ 20
SECONDARY_COOLDOWN equ 40   ; Stronger weapon: a slower two-second cadence.
BOOST_SECONDARY_COOLDOWN equ 32
BOOST_BURST_COUNT equ 2
BOOST_FRAMES    equ 80       ; Roughly four seconds.
INITIAL_ENEMY_HEALTH equ 8   ; Eight cleavers or four rolling pins per demo enemy.

ENEMY_WIDTH     equ 5
ENEMY_HEIGHT    equ 3

%define LEFT 0
%define RIGHT SCREEN_WIDTH
%define TOP 2
%define BOTTOM (SCREEN_HEIGHT - 1)
%define RANDOM_ENEMY_MAX_Y (SCREEN_HEIGHT - PLAYER_HEIGHT - 10)
%define MAX_ENEMIES 10
%define MAX_SHOTS 16
%define MENU 0
%define PLAYING 1
%define GAME_OVER 2
%define VICTORY 4
%define QUIT 3
%define FINAL_STAGE 5
%define EV_CLEAR 1
%define EV_BOSS 2
%define EV_BREACH 4
%define E_ACTIVE 0
%define E_TYPE 4
%define E_X 8
%define E_Y 12
%define E_HP 16
%define E_SX 20
%define E_SY 24
%define E_SIZE 28
%define T_HP 0
%define T_W 4
%define T_H 8
%define T_SCORE 12
%define T_SHOOT 16
%define T_ART 20
%define T_COLOR 24
%define T_SIZE 28
%define S_ACTIVE 0
%define S_X 4
%define S_Y 8
%define S_SIZE 12



player_x        db (SCREEN_WIDTH - PLAYER_WIDTH) / 2       ; Left column of the player sprite (0 through SCREEN_WIDTH - PLAYER_WIDTH).
player_y        db SCREEN_HEIGHT - PLAYER_HEIGHT - 1       ; Top row of the player sprite (within the playfield).
player_lives    db 3        ; Remaining player lives for future enemy attacks.

; Legacy names alias slot zero; array users index with SI (0..MAX_BULLETS-1).
bullet_x:
bullets_x       times MAX_BULLETS db 0
bullet_y:
bullets_y       times MAX_BULLETS db 0
bullet_active:
bullets_active  times MAX_BULLETS db 0
bullets_kind    times MAX_BULLETS db CLEAVER
bullets_damage  times MAX_BULLETS db 0 ; Damage is captured at firing time.
fire_cooldown   db 0
player_boost_frames dw 0

; Legacy enemy names alias slot zero. Enemy fields and score are DWORDs.
enemy_x equ enemies+E_X
enemy_y equ enemies+E_Y
enemy_alive equ enemies+E_ACTIVE
enemy_health equ enemies+E_HP
score dd 0
current_wave dd 1
game_state db MENU
shield_active db 0
powerup_active db 0
%include "assets/enemy_art.inc"

shot_timer dd 0
alive_count dd 0
boss_mode dd 0
direction dd 1
move_timer dd 0
attack_timer dd 0
move_interval dd 300
attack_interval dd 1200
attack_min_interval dd 1800
attack_interval_range dd 1800
shooter_cursor dd 0
enemy_events dd 0
loss_pending dd 0
; Persistent completion flag prevents repeated clear events after consumption.
completion_sent dd 0
enemies times MAX_ENEMIES*E_SIZE db 0
shots times MAX_SHOTS*S_SIZE db 0
enemy_move_timers times MAX_ENEMIES dd 0
enemy_move_intervals times MAX_ENEMIES dd 0
enemy_fire_timers times MAX_ENEMIES dd 0
enemy_fire_intervals times MAX_ENEMIES dd 0
enemy_target_x times MAX_ENEMIES db 0
enemy_target_y times MAX_ENEMIES db 0
random_state dd 0x6D2B79F5

invulnerable dd 0
