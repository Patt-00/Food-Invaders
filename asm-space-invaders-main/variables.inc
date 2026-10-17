; One authoritative data definition. Logical cells, half-open arena bounds.
%define LEFT 0
%define RIGHT 80
%define TOP 2
%define BOTTOM 25
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


; Existing interfaces retained. Player/bullet coordinates are BYTES.
SCREEN_WIDTH equ RIGHT
PLAYER_WIDTH equ 5
PLAYER_HEIGHT equ 3
ENEMY_WIDTH equ 5 ; legacy fallback only; new code uses each type's metadata
ENEMY_HEIGHT equ 3
player_x db 38
player_y db 22
player_lives db 3
bullet_x db 0
bullet_y db 0
bullet_active db 0
game_state db MENU
shield_active db 0
powerup_active db 0
score dd 0
current_wave dd 1
; Legacy names alias slot zero, not duplicate enemy state.
enemy_x equ enemies+E_X
enemy_y equ enemies+E_Y
enemy_alive equ enemies+E_ACTIVE

%include "assets/enemy_art.inc"
%include "assets/player_art.inc"

shot_timer dd 0
alive_count dd 0
boss_mode dd 0
direction dd 1
move_timer dd 0
attack_timer dd 0
move_interval dd 300
attack_interval dd 1200
shooter_cursor dd 0
enemy_events dd 0
loss_pending dd 0
; Persistent completion flag prevents repeated clear events after consumption.
completion_sent dd 0
enemies times MAX_ENEMIES*E_SIZE db 0
shots times MAX_SHOTS*S_SIZE db 0

invulnerable dd 0
fire_timer dd 0
