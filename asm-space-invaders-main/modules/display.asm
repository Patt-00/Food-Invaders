; Text-mode renderer: one 80x25 back buffer, copied to B800h once per frame.
; Movement/collision/drawing share type widths/heights. No Windows pixels.
; All routines preserve full general-purpose registers unless noted.
buffer_guard_before dd 0A5C33C5Ah
back_buffer times 80*25 dw 0720h
buffer_guard_after dd 05AC33CA5h
render_x dd 0
render_y dd 0
render_width dd 0
render_rows dd 0
render_column dd 0
number_buffer times 12 db 0
hud_score_text db 'SCORE:',0
hud_lives_text db 'LIVES:',0
hud_stage_text db 'STAGE:',0
hud_boss_text db 'RATATOUILLE HP:',0

clear_screen:
 pushad
 push es
 mov ax,ds
 mov es,ax
 mov di,back_buffer
 mov ax,0720h
 mov cx,80*25
 cld
 rep stosw
 pop es
 popad
 ret

present_screen:
 pushad
 push es
 mov ax,0B800h
 mov es,ax
 mov si,back_buffer
 xor di,di
 mov cx,80*25
 cld
 rep movsw
 pop es
 popad
 ret

; EAX=x, EDX=y, BL=character, BH=text attribute. Clip before buffer access.
draw_cell:
 pushad
 cmp eax,80
 jae .done
 cmp edx,25
 jae .done
 imul edi,edx,80
 add edi,eax
 shl edi,1
 mov [back_buffer+edi],bx
.done:
 popad
 ret

; Original interface kept: DH=row, DL=column. Software rendering uses DX.
set_cursor:
 ret

; DS:SI=zero-terminated string, DX=row/column, BL=attribute. All preserved.
print_string:
 pushad
 movzx esi,si
 movzx ecx,dl
 movzx ebp,dh
 movzx edi,bl
 shl edi,8
.next:
 mov al,[esi]
 test al,al
 jz .done
 cmp ecx,80
 jae .done
 mov ebx,edi
 mov bl,al
 mov eax,ecx
 mov edx,ebp
 call draw_cell
 inc esi
 inc ecx
 jmp .next
.done:
 popad
 ret

; Legacy character/attribute pair interface, for future assets. CX=row length.
; Do not overwrite CX with BIOS repeat counts as the original renderer did.
draw_colored_sprite:
 pushad
 movzx esi,si
 movzx ecx,cx
 movzx eax,dl
 movzx edx,dh
.loop:
 test ecx,ecx
 jz .done
 mov bx,[esi]
 call draw_cell
 add esi,2
 inc eax
 dec ecx
 jmp .loop
.done:
 popad
 ret

; EAX=x, EDX=y, ESI=raw rectangular art, ECX=width, EBP=height, BL=color.
draw_rectangle_art:
 pushad
 mov [render_x],eax
 mov [render_y],edx
 mov [render_width],ecx
 mov [render_rows],ebp
 mov bh,bl
.row:
 mov dword [render_column],0
.column:
 mov bl,[esi]
 mov eax,[render_x]
 add eax,[render_column]
 mov edx,[render_y]
 call draw_cell
 inc esi
 inc dword [render_column]
 mov eax,[render_width]
 cmp [render_column],eax
 jb .column
 inc dword [render_y]
 dec dword [render_rows]
 jnz .row
 popad
 ret

draw_enemy:
 pushad
 mov edi,enemies
 mov ecx,MAX_ENEMIES
.loop:
 cmp dword [edi+E_ACTIVE],0
 je .next
 push ecx
 mov eax,[edi+E_TYPE]
 imul eax,T_SIZE
 lea ebx,[type_table+eax]
 mov esi,[ebx+T_ART]
 mov ecx,[ebx+T_W]
 mov ebp,[ebx+T_H]
 mov ebx,[ebx+T_COLOR]
 mov eax,[edi+E_X]
 mov edx,[edi+E_Y]
 call draw_rectangle_art
 pop ecx
.next:
 add edi,E_SIZE
 loop .loop
 popad
 ret

draw_player:
 pushad
 test dword [invulnerable],80h
 jnz .done
 movzx eax,byte [player_x]
 movzx edx,byte [player_y]
 mov esi,art_player
 mov ecx,PLAYER_WIDTH
 mov ebp,PLAYER_HEIGHT
 mov bl,0Bh
 call draw_rectangle_art
.done:
 popad
 ret

draw_bullet:
 pushad
 cmp byte [bullet_active],0
 je .hostile
 movzx eax,byte [bullet_x]
 movzx edx,byte [bullet_y]
 mov bx,0F7Ch                ; white '|' (cleaver projectile)
 call draw_cell
.hostile:
 mov esi,shots
 mov ecx,MAX_SHOTS
.loop:
 cmp dword [esi+S_ACTIVE],0
 je .next
 mov eax,[esi+S_X]
 mov edx,[esi+S_Y]
 mov bx,0C21h                ; red '!' (hostile projectile)
 call draw_cell
.next:
 add esi,S_SIZE
 loop .loop
 popad
 ret

; EAX=unsigned DWORD number, DX=row/column, BL=color. All preserved.
; Original name retained as an alias; now safely handles scores above 99.
print_number_0_99:
print_number32:
 pushad
 movzx ebp,dx
 mov esi,number_buffer+11
 mov byte [esi],0
 mov ecx,10
.digit:
 xor edx,edx
 div ecx
 add dl,'0'
 dec esi
 mov [esi],dl
 test eax,eax
 jnz .digit
 mov edx,ebp
 call print_string
 popad
 ret

draw_hud:
 pushad
 mov bl,0Fh
 mov dx,0001h
 mov si,hud_score_text
 call print_string
 mov dl,8
 mov eax,[score]
 call print_number32
 mov dl,29
 mov si,hud_lives_text
 call print_string
 mov dl,36
 movzx eax,byte [player_lives]
 call print_number32
 mov dl,48
 mov si,hud_stage_text
 call print_string
 mov dl,55
 mov eax,[current_wave]
 call print_number32
 cmp dword [boss_mode],0
 je .done
 mov dx,0118h
 mov si,hud_boss_text
 call print_string
 mov dl,40
 mov eax,[enemies+E_HP]
 call print_number32
.done:
 popad
 ret

draw_game:
 call clear_screen
 call draw_hud
 call draw_enemy
 call draw_bullet
 call draw_player
 call present_screen
 ret
