; Food Invaders menus. Existing public procedure/input interfaces retained.
%include "assets/title_art.inc"
%include "assets/gameover_art.inc"
menu_hint_text db '1-3 SELECT + PLAY   P/SPACE NORMAL   Q/ESC QUIT',0
controls_text db 'A / D or arrow keys: move     SPACE: cleaver  X: rolling pin',0
legend_text db 'Cupcake   Fries   Burger   Hotdog   Pizza    Boss: Ratatouille',0
details_text db 'Hotdog and Pizza shoot. Burger and Pizza take two cleaver hits.',0
boss_text db 'Clear four stages, then defeat Ratatouille (20 HP).',0
over_hint_text db 'R/SPACE: restart  1-3: difficulty  Q/ESC: quit',0
difficulty_text db 'DIFFICULTY: 1 EASY  2 NORMAL  3 HARD',0
victory_text db 'KITCHEN SAVED - RATATOUILLE DEFEATED!',0
result_text db 'FINAL SCORE:',0

show_main_menu:
 pushad
 call clear_screen
 mov bl,0Ah
 mov dx,0418h + ((SCREEN_HEIGHT-25)/2)*256 + (SCREEN_WIDTH-80)/2
 mov si,title_art_line1
 call print_string
 mov bl,0Fh
 mov dx,080Eh + ((SCREEN_HEIGHT-25)/2)*256 + (SCREEN_WIDTH-80)/2
 mov si,controls_text
 call print_string
 mov dx,0B0Ah + ((SCREEN_HEIGHT-25)/2)*256 + (SCREEN_WIDTH-80)/2
 mov si,legend_text
 call print_string
 mov dx,0D0Ch + ((SCREEN_HEIGHT-25)/2)*256 + (SCREEN_WIDTH-80)/2
 mov si,details_text
 call print_string
 mov dx,0F0Eh + ((SCREEN_HEIGHT-25)/2)*256 + (SCREEN_WIDTH-80)/2
 mov si,boss_text
 call print_string
 mov dx,1116h + ((SCREEN_HEIGHT-25)/2)*256 + (SCREEN_WIDTH-80)/2
 mov si,difficulty_text
 call print_string
 mov bl,0Eh
 mov dx,140Eh + ((SCREEN_HEIGHT-25)/2)*256 + (SCREEN_WIDTH-80)/2
 mov si,menu_hint_text
 call print_string
 call present_screen
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
