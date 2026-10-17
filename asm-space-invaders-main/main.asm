; Food Invaders: DOSBox real mode with 386+ 32-bit gameplay calculations.
; Build with: nasm -f bin main.asm -o INVADERS.COM

bits 16
cpu 386
org 100h

%ifdef SELFTEST
    jmp tests_start
%else
    jmp start
%endif

%include "variables.inc"

start:
    ; DWORD-argument procedures use ESP addressing; DOS only specifies SP.
    movzx esp, sp
    cld
    mov ax, cs
    mov ds, ax
    mov es, ax
    call initialize_program

main_menu:
    call show_main_menu
    call wait_for_menu_input       ; AL = 1 for play, 2 for quit.
    cmp al, 2
    je quit_program

new_game:
    call initialize_game

game_loop:
    call read_input
    cmp byte [game_state], QUIT
    je quit_program
    call update_player
    call simulate_tick
    call update_features
    call draw_game
    call wait_frame

    cmp byte [game_state], PLAYING
    je game_loop
    cmp byte [game_state], VICTORY
    je won_game
    cmp byte [game_state], GAME_OVER
    jne quit_program

    call show_game_over
    jmp result_input
won_game:
    call show_victory
result_input:
    call wait_for_menu_input       ; R/Space starts over; Q/Esc quits.
    cmp al, 1
    je new_game

quit_program:
    mov ah, 01h             ; Restore a visible VGA text cursor for DOS.
    mov cx, 0D0Eh
    int 10h
    mov ax, 4C00h
    int 21h

; -------------------------------------------------
; Procedure: initialize_program
; Purpose: Select the standard DOS text mode.
; Input: None
; Output: Screen is in 80x25 text mode.
; Modifies: AX, CX (BIOS services)
; Shared variables used: None
; -------------------------------------------------
initialize_program:
    mov ax, 0003h
    int 10h
    mov ah, 01h             ; Hide hardware cursor; sprites use a back buffer.
    mov ch, 20h
    xor cl, cl
    int 10h
    ret

; -------------------------------------------------
; Procedure: initialize_game
; Purpose: Reset all shared state for a new game.
; Input: None
; Output: A fresh Food Invaders formation, score/lives/stage reset.
; Modifies: Flags only; all general-purpose registers preserved.
; Shared variables used: All game state variables
; -------------------------------------------------
initialize_game:
    pushad
    mov byte [player_x], 38
    mov byte [player_y], 22
    mov byte [player_lives], 3
    mov byte [bullet_active], 0
    mov dword [score], 0
    mov dword [current_wave], 1
    mov dword [invulnerable], 0
    mov dword [fire_timer], 0
    mov dword [loss_pending], 0
    mov byte [shield_active], 0
    mov byte [powerup_active], 0
    mov byte [game_state], PLAYING
    call initialize_enemies
    popad
    ret

; -------------------------------------------------
; Procedure: read_input
; Purpose: Read one pending keyboard command without pausing the game loop.
; Input: None
; Output: May move, fire, or request quit.
; Modifies: AX
; Shared variables used: game_state
; -------------------------------------------------
read_input:
    mov ah, 01h
    int 16h
    jz .done
    mov ah, 00h
    int 16h

    cmp al, 1Bh                 ; Escape
    je .quit
    cmp al, 'a'
    je .left
    cmp al, 'A'
    je .left
    cmp al, 'd'
    je .right
    cmp al, 'D'
    je .right
    cmp al, ' '
    je .fire
    cmp ah, 4Bh                 ; Left arrow scan code
    je .left
    cmp ah, 4Dh                 ; Right arrow scan code
    je .right
    jmp .done
.left:
    call move_player_left
    jmp .done
.right:
    call move_player_right
    jmp .done
.fire:
    call fire_bullet
    jmp .done
.quit:
    mov byte [game_state], QUIT
.done:
    ret

; -------------------------------------------------
; Procedure: wait_frame
; Purpose: Make movement visible instead of running the loop at full CPU speed.
; Input: None
; Output: Approximately 50 milliseconds pass when BIOS wait is supported.
; Modifies: AX, CX, DX
; Shared variables used: None
; -------------------------------------------------
wait_frame:
    mov ah, 86h
    mov cx, 0
    mov dx, 50000
    int 15h
    ret

%include "modules/player.asm"
%include "modules/bullet.asm"
%include "modules/enemy.asm"
%include "modules/collision.asm"
%include "modules/encounter.asm"
%include "modules/display.asm"
%include "modules/menu.asm"
%include "modules/features.asm"

%ifdef SELFTEST
%include "tests/core.asm"
%endif
