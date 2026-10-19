; Food Invaders menus. Existing public procedure/input interfaces retained.
%include "assets/title_art.inc"
%include "assets/gameover_art.inc"
MENU_RULE_TOP_ROW equ 2
MENU_TITLE_ROW equ 4
MENU_SUBTITLE_ROW equ 7
MENU_ENEMY_ROW equ 13
MENU_ENEMY_LABEL_ROW equ 30
MENU_SHOWCASE_ROW equ 34
MENU_SHOWCASE_LABEL_ROW equ 52
MENU_CONTROLS_ROW equ 56
MENU_WEAPONS_ROW equ 59
MENU_POWERUP_ROW equ 62
MENU_DETAILS_ROW equ 65
MENU_BOSS_ROW equ 68
MENU_DIFFICULTY_ROW equ 72
MENU_START_ROW equ 76
MENU_QUIT_ROW equ 79
MENU_RULE_BOTTOM_ROW equ 83

menu_rule_text db '================================================================================',0
menu_subtitle_text db 'THE KITCHEN IS UNDER ATTACK',0
menu_hint_text db 'PRESS 1-3 TO SELECT AND START, OR P/SPACE FOR NORMAL',0
menu_quit_text db 'Q OR ESC: QUIT',0
controls_text db 'A/D OR ARROWS: MOVE',0
weapons_text db 'SPACE: CLEAVER     X: ROLLING PIN',0
powerup_text db 'CATCH A FALLING FIREBALL FOR A TEMPORARY BOOST',0
details_text db 'HOTDOGS AND PIZZAS SHOOT; BURGER AND PIZZA TAKE TWO CLEAVER HITS',0
boss_text db 'CLEAR FOUR STAGES, THEN DEFEAT RATATOUILLE (20 HP)',0
over_hint_text db 'R/SPACE: restart  1-3: difficulty  Q/ESC: quit',0
difficulty_text db 'DIFFICULTY: 1 EASY  2 NORMAL  3 HARD',0
difficulty_text_width equ $ - difficulty_text - 1
cupcake_label db 'CUPCAKE',0
fries_label db 'FRIES',0
burger_label db 'BURGER',0
hotdog_label db 'HOTDOG',0
pizza_label db 'PIZZA',0
boss_label db 'RATATOUILLE',0
cleaver_label db 'CLEAVER',0
chef_label db 'CHEF',0
rolling_pin_label db 'ROLLING PIN',0
fireball_label db 'FIREBALL',0
victory_text db 'KITCHEN SAVED - RATATOUILLE DEFEATED!',0
result_text db 'FINAL SCORE:',0

show_main_menu:
 pushad
 call clear_screen
 mov bl,09h
 mov dh,MENU_RULE_TOP_ROW
 mov si,menu_rule_text
 call print_centered_string
 mov bl,0Ah
 mov dh,MENU_TITLE_ROW
 mov si,title_art_line1
 call print_centered_string
 mov bl,0Fh
 mov dh,MENU_SUBTITLE_ROW
 mov si,menu_subtitle_text
 call print_centered_string

 call draw_menu_preview

 mov bl,0Fh
 mov dh,MENU_ENEMY_LABEL_ROW
 mov dl,10
 mov si,cupcake_label
 call print_string
 mov dl,37
 mov si,fries_label
 call print_string
 mov dl,63
 mov si,burger_label
 call print_string
 mov dl,89
 mov si,hotdog_label
 call print_string
 mov dl,115
 mov si,pizza_label
 call print_string

 mov dh,MENU_SHOWCASE_LABEL_ROW
 mov dl,18
 mov si,boss_label
 call print_string
 mov dl,41
 mov si,cleaver_label
 call print_string
 mov dl,64
 mov si,chef_label
 call print_string
 mov dl,81
 mov si,rolling_pin_label
 call print_string
 mov dl,106
 mov si,fireball_label
 call print_string

 mov bl,0Fh
 mov dh,MENU_CONTROLS_ROW
 mov si,controls_text
 call print_centered_string
 mov dh,MENU_WEAPONS_ROW
 mov si,weapons_text
 call print_centered_string
 mov dh,MENU_POWERUP_ROW
 mov si,powerup_text
 call print_centered_string
 mov dh,MENU_DETAILS_ROW
 mov si,details_text
 call print_centered_string
 mov dh,MENU_BOSS_ROW
 mov si,boss_text
 call print_centered_string
 mov bl,0Eh
 mov dh,MENU_DIFFICULTY_ROW
 mov si,difficulty_text
 call print_centered_string
 mov bl,0Fh
 mov dh,MENU_START_ROW
 mov si,menu_hint_text
 call print_centered_string
 mov bl,0Eh
 mov dh,MENU_QUIT_ROW
 mov si,menu_quit_text
 call print_centered_string
 mov bl,09h
 mov dh,MENU_RULE_BOTTOM_ROW
 mov si,menu_rule_text
 call print_centered_string
 call present_screen
 popad
 ret

; Draw the existing full-size ASCII assets as a title-screen preview.
draw_menu_preview:
 pushad
 ; Five regular invaders, centered in the same lanes used by gameplay.
 mov eax,(SCREEN_WIDTH-ENEMY_LANE_COUNT*ENEMY_LANE_WIDTH)/2 + (ENEMY_LANE_WIDTH-22)/2
 mov edx,MENU_ENEMY_ROW
 mov esi,art_cupcake
 mov ecx,22
 mov ebp,16
 mov bl,0Dh
 call draw_rectangle_art
 mov eax,(SCREEN_WIDTH-ENEMY_LANE_COUNT*ENEMY_LANE_WIDTH)/2 + ENEMY_LANE_WIDTH + (ENEMY_LANE_WIDTH-14)/2
 mov edx,MENU_ENEMY_ROW
 mov esi,art_fries
 mov ecx,14
 mov ebp,16
 mov bl,0Eh
 call draw_rectangle_art
 mov eax,(SCREEN_WIDTH-ENEMY_LANE_COUNT*ENEMY_LANE_WIDTH)/2 + ENEMY_LANE_WIDTH*2 + (ENEMY_LANE_WIDTH-14)/2
 mov edx,MENU_ENEMY_ROW+(16-11)/2
 mov esi,art_burger
 mov ecx,14
 mov ebp,11
 mov bl,0Bh
 call draw_rectangle_art
 mov eax,(SCREEN_WIDTH-ENEMY_LANE_COUNT*ENEMY_LANE_WIDTH)/2 + ENEMY_LANE_WIDTH*3 + (ENEMY_LANE_WIDTH-14)/2
 mov edx,MENU_ENEMY_ROW
 mov esi,art_hotdog
 mov ecx,14
 mov ebp,16
 mov bl,0Ch
 call draw_rectangle_art
 mov eax,(SCREEN_WIDTH-ENEMY_LANE_COUNT*ENEMY_LANE_WIDTH)/2 + ENEMY_LANE_WIDTH*4 + (ENEMY_LANE_WIDTH-14)/2
 mov edx,MENU_ENEMY_ROW
 mov esi,art_pizza
 mov ecx,14
 mov ebp,16
 mov bl,0Ah
 call draw_rectangle_art

 ; Boss, weapons, Chef and power-up preview below the enemy row.
 mov eax,16
 mov edx,MENU_SHOWCASE_ROW
 mov esi,art_rat
 mov ecx,15
 mov ebp,16
 mov bl,0Fh
 call draw_rectangle_art
 mov eax,39
 mov edx,MENU_SHOWCASE_ROW
 mov esi,cleaver_art
 mov ecx,WEAPON_WIDTH
 mov ebp,WEAPON_HEIGHT
 mov bl,0Bh
 call draw_rectangle_art
 mov eax,(SCREEN_WIDTH-PLAYER_WIDTH)/2
 mov edx,MENU_SHOWCASE_ROW
 mov esi,player_art
 mov ecx,PLAYER_WIDTH
 mov ebp,PLAYER_HEIGHT
 mov bl,0Fh
 call draw_rectangle_art
 mov eax,81
 mov edx,MENU_SHOWCASE_ROW
 mov esi,rolling_pin_art
 mov ecx,WEAPON_WIDTH
 mov ebp,WEAPON_HEIGHT
 mov bl,0Eh
 call draw_rectangle_art
 mov eax,103
 mov edx,MENU_SHOWCASE_ROW-1
 mov esi,art_fireball
 mov ecx,PICKUP_WIDTH
 mov ebp,PICKUP_HEIGHT
 mov bl,0Eh
 call draw_rectangle_art
 popad
 ret

; Center DS:SI on row DH with color BL. All registers preserved.
print_centered_string:
 pushad
 movzx esi,si
 xor ecx,ecx
.length:
 cmp byte [esi+ecx],0
 je .place
 inc ecx
 jmp .length
.place:
 mov eax,SCREEN_WIDTH
 sub eax,ecx
 shr eax,1
 mov dl,al
 call print_string
 popad
 ret

show_game_over:
 pushad
 call clear_screen
 mov dx,071Eh + ((SCREEN_HEIGHT-25)/2)*256 + (SCREEN_WIDTH-80)/2
 mov bl,0Ch
 mov si,gameover_art_line1
 call print_string
 call draw_result
 popad
 ret

show_victory:
 pushad
 call clear_screen
 mov dx,0716h + ((SCREEN_HEIGHT-25)/2)*256 + (SCREEN_WIDTH-80)/2
 mov bl,0Ah
 mov si,victory_text
 call print_string
 call draw_result
 popad
 ret

draw_result:
 mov bl,0Fh
 mov dx,0A1Eh + ((SCREEN_HEIGHT-25)/2)*256 + (SCREEN_WIDTH-80)/2
 mov si,result_text
 call print_string
 mov dl,43+(SCREEN_WIDTH-80)/2
 mov eax,[score]
 call print_number32
 mov dx,0E16h + ((SCREEN_HEIGHT-25)/2)*256 + (SCREEN_WIDTH-80)/2
 mov si,over_hint_text
 call print_string
 call present_screen
 ret

; Menu input: AL=selected difficulty 1..3; zero means quit.
wait_for_menu_input:
.read:
 mov ah,00h
 int 16h
 cmp al,'1'
 je .easy
 cmp al,'2'
 je .normal
 cmp al,'3'
 je .hard
 cmp al,'p'
 je .normal
 cmp al,'P'
 je .normal
 cmp al,' '
 je .normal
 cmp al,'q'
 je .quit
 cmp al,'Q'
 je .quit
 cmp al,1Bh
 je .quit
 jmp .read
.easy:
 mov al,DIFFICULTY_EASY
 ret
.normal:
 mov al,DIFFICULTY_NORMAL
 ret
.hard:
 mov al,DIFFICULTY_HARD
 ret
.quit:
 xor al,al
 ret

; Result input: R/Space restarts at the current difficulty; 1..3 changes it.
; AL=1 means restart, AL=2 means quit.
wait_for_result_input:
.read:
 mov ah,00h
 int 16h
 cmp al,'1'
 je .easy
 cmp al,'2'
 je .normal
 cmp al,'3'
 je .hard
 cmp al,'r'
 je .restart
 cmp al,'R'
 je .restart
 cmp al,' '
 je .restart
 cmp al,'q'
 je .quit
 cmp al,'Q'
 je .quit
 cmp al,1Bh
 je .quit
 jmp .read
.easy:
 mov byte [difficulty_level],DIFFICULTY_EASY
 jmp .restart
.normal:
 mov byte [difficulty_level],DIFFICULTY_NORMAL
 jmp .restart
.hard:
 mov byte [difficulty_level],DIFFICULTY_HARD
.restart:
 mov al,1
 ret
.quit:
 mov al,2
 ret
