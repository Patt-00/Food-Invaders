; Shared game data and constants.  This file is included once by main.asm.

SCREEN_WIDTH    equ 132
SCREEN_HEIGHT   equ 88
PLAYFIELD_TOP   equ 1        ; Row zero belongs to the HUD.
PLAYER_WIDTH    equ 12
PLAYER_HEIGHT   equ 16
SOURCE_ART_WIDTH equ 12
SOURCE_ART_HEIGHT equ 16
WEAPON_WIDTH    equ SOURCE_ART_WIDTH
WEAPON_HEIGHT   equ SOURCE_ART_HEIGHT
SOURCE_PICKUP_WIDTH equ 14
SOURCE_PICKUP_HEIGHT equ 18
BULLET_SPEED    equ 2        ; Keeps a shot in the shorter viewport through its cooldown.
HOSTILE_SHOT_WIDTH equ 1
HOSTILE_SHOT_HEIGHT equ 1
PLAYER_MOVE_STEP equ 3       ; One key repeat moves far enough to cross the wide playfield.
PLAYER_BOOST_MOVE_STEP equ 5
PLAYER_HITBOX_X equ 0
PLAYER_HITBOX_Y equ 0
PLAYER_HITBOX_WIDTH equ PLAYER_WIDTH
PLAYER_HITBOX_HEIGHT equ PLAYER_HEIGHT

; VGA 32 KiB text memory and 8-bit coordinates bound this display mode.
%if SCREEN_WIDTH != 132 || SCREEN_HEIGHT != 88
    %error "Display timing is configured for 132x88 cells"
%endif
%if SCREEN_WIDTH * SCREEN_HEIGHT * 2 > 32768
    %error "Text frame must fit in VGA text memory"
%endif

; Gameplay hitboxes match the exact document artwork dimensions.
%if PLAYER_WIDTH != SOURCE_ART_WIDTH || PLAYER_HEIGHT != SOURCE_ART_HEIGHT
    %error "Chef dimensions must match the source artwork"
%endif
%if WEAPON_WIDTH != SOURCE_ART_WIDTH || WEAPON_HEIGHT != SOURCE_ART_HEIGHT
    %error "Weapon dimensions must match the source artwork"
%endif
%if BULLET_SPEED < 1 || BULLET_SPEED > WEAPON_HEIGHT
    %error "Projectile steps must stay within sprite height to avoid skipped collisions"
%endif
%if PLAYER_HITBOX_X < 0 || PLAYER_HITBOX_Y < 0 || PLAYER_HITBOX_X + PLAYER_HITBOX_WIDTH > PLAYER_WIDTH || PLAYER_HITBOX_Y + PLAYER_HITBOX_HEIGHT > PLAYER_HEIGHT
    %error "Enemy-shot hitbox must fit inside the Chef sprite"
%endif
MAX_BULLETS     equ 3
CLEAVER         equ 0
ROLLING_PIN     equ 1
NORMAL_COOLDOWN equ 16        ; 0.8 seconds at the 50 ms simulation tick.
BOOST_COOLDOWN  equ 12
SECONDARY_COOLDOWN equ 28    ; Stronger weapon: a slower 1.4 second cadence.
BOOST_SECONDARY_COOLDOWN equ 20
BOOST_BURST_COUNT equ 2
BOOST_FRAMES    equ 80       ; Roughly four seconds.
INITIAL_ENEMY_HEALTH equ 8   ; Eight cleavers or four rolling pins per demo enemy.
PICKUP_STEP_TICKS equ 1      ; A falling pickup moves once every 50 ms.
PICKUP_WIDTH equ SOURCE_PICKUP_WIDTH
PICKUP_HEIGHT equ SOURCE_PICKUP_HEIGHT
%if PICKUP_WIDTH != SOURCE_PICKUP_WIDTH || PICKUP_HEIGHT != SOURCE_PICKUP_HEIGHT
    %error "Pickup dimensions must match the source artwork"
%endif

ENEMY_MOVE_BASE_MIN_MS equ 120
ENEMY_MOVE_BASE_RANGE_MS equ 241
ENEMY_MOVE_STAGE_ACCEL_MS equ 20
ENEMY_ATTACK_BASE_MIN_MS equ 2600
ENEMY_ATTACK_BASE_RANGE_MS equ 2401
ENEMY_ATTACK_STAGE_ACCEL_MS equ 350
HOSTILE_SHOT_BASE_MS equ 80
HOSTILE_SHOT_STAGE_ACCEL_MS equ 15

%define DIFFICULTY_EASY 1
%define DIFFICULTY_NORMAL 2
%define DIFFICULTY_HARD 3
%define BOOST_MASK_SPEED 1
%define BOOST_MASK_DAMAGE 2
%define BOOST_MASK_RAPID 4
%define BOOST_MASK_ALL (BOOST_MASK_SPEED|BOOST_MASK_DAMAGE|BOOST_MASK_RAPID)
%define POWERUP_SPEED 1
%define POWERUP_DAMAGE 2
%define POWERUP_RAPID 3

ENEMY_WIDTH     equ 22       ; Widest source design: the cupcake.
ENEMY_HEIGHT    equ 16       ; Tallest food enemy source design.
MENU_ENEMY_PREVIEW_COUNT equ 5
MENU_ENEMY_PREVIEW_WIDTH equ (SCREEN_WIDTH / MENU_ENEMY_PREVIEW_COUNT)
; Enemies roam the full field but stop above the Chef's safe area.
ENEMY_CHEF_SAFE_GAP equ 8
ENEMY_BREACH_LINE equ (SCREEN_HEIGHT - PLAYER_HEIGHT - 1 - ENEMY_CHEF_SAFE_GAP)
ENEMY_CLEARANCE equ 2
ENEMY_RANDOM_POSITION_TRIES equ 64
ENEMY_RANDOM_STEP_TRIES equ 12
enemy_move_step_x_by_wave db 4,6,8,10
enemy_move_step_y_by_wave db 2,3,4,5

; Four regular waves use different enemy orders.
WAVE_REGULAR_COUNT equ 4
wave_enemy_type_map:
    db 0,1,2,3,4, 3,2,4,0,1
    db 1,0,3,2,4, 4,3,1,0,2
    db 4,0,3,1,2, 1,4,2,0,3
    db 2,4,0,3,1, 3,2,4,0,1

%if ENEMY_BREACH_LINE <= PLAYFIELD_TOP + 1 + ENEMY_HEIGHT
    %error "Enemies need a safe movement area above the Chef"
%endif
%if ENEMY_CHEF_SAFE_GAP < 1
    %error "Enemies must stop above the Chef's area"
%endif
%if ENEMY_MOVE_BASE_MIN_MS <= ENEMY_MOVE_STAGE_ACCEL_MS * 3 || ENEMY_MOVE_BASE_RANGE_MS <= ENEMY_MOVE_STAGE_ACCEL_MS * 3
    %error "Regular enemy movement intervals must stay positive"
%endif
%if ENEMY_ATTACK_BASE_MIN_MS <= ENEMY_ATTACK_STAGE_ACCEL_MS * 3 || ENEMY_ATTACK_BASE_RANGE_MS <= ENEMY_ATTACK_STAGE_ACCEL_MS * 3
    %error "Regular enemy firing intervals must stay positive"
%endif
%if HOSTILE_SHOT_BASE_MS <= HOSTILE_SHOT_STAGE_ACCEL_MS * 3
    %error "Regular hostile-shot steps must stay positive"
%endif

%define LEFT 0
%define RIGHT SCREEN_WIDTH
%define TOP 2
%define BOTTOM (SCREEN_HEIGHT - 1)
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
%define T_ART 16
%define T_COLOR 20
%define T_SIZE 24
%define S_ACTIVE 0
%define S_X 4
%define S_Y 8
%define S_SIZE 12



player_x        db (SCREEN_WIDTH - PLAYER_WIDTH) / 2       ; Left column of the player sprite (0 through SCREEN_WIDTH - PLAYER_WIDTH).
player_y        db SCREEN_HEIGHT - PLAYER_HEIGHT - 1       ; Top row of the player sprite (within the playfield).
player_lives    db 3        ; Remaining lives depend on the selected difficulty.
difficulty_level db DIFFICULTY_NORMAL

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
player_boost_mask db 0

; Legacy enemy names alias slot zero. Enemy fields and score are DWORDs.
enemy_x equ enemies+E_X
enemy_y equ enemies+E_Y
enemy_alive equ enemies+E_ACTIVE
enemy_health equ enemies+E_HP
score dd 0
current_wave dd 1
game_state db MENU
powerup_active db 0
pickup_active db 0
pickup_kind db POWERUP_SPEED
pickup_x db 0
pickup_y db 0
pickup_move_timer db 0
%include "assets/enemy_art.inc"

shot_timer dd 0
alive_count dd 0
boss_mode dd 0
attack_min_interval dd 1800
attack_interval_range dd 1800
enemy_move_min_interval dd ENEMY_MOVE_BASE_MIN_MS
enemy_move_interval_range dd ENEMY_MOVE_BASE_RANGE_MS
enemy_shot_step_ms dd HOSTILE_SHOT_BASE_MS
shooter_cursor dd 0
enemy_events dd 0
loss_pending dd 0
; Persistent completion flag prevents repeated clear events after consumption.
completion_sent dd 0
enemies times MAX_ENEMIES*E_SIZE db 0
shots times MAX_SHOTS*S_SIZE db 0
enemy_shoot_enabled times MAX_ENEMIES db 0
enemy_move_timers times MAX_ENEMIES dd 0
enemy_move_intervals times MAX_ENEMIES dd 0
enemy_fire_timers times MAX_ENEMIES dd 0
enemy_fire_intervals times MAX_ENEMIES dd 0
enemy_candidate_x db 0
enemy_candidate_y db 0
enemy_scan_start_x db 0
enemy_scan_start_y db 0
enemy_step_dx db 0
enemy_step_dy db 0
enemy_position_attempts dd 0
enemy_position_clearance db ENEMY_CLEARANCE
random_state dd 0x6D2B79F5

invulnerable dd 0
