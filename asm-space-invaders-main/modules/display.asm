%include "assets/player_art.inc"
%include "assets/bullet_art.inc"

; Text-mode renderer: one 132x120 back buffer, copied to B800h once per frame.
; Movement/collision/drawing share type widths/heights. No Windows pixels.
; All routines preserve full general-purpose registers unless noted.
buffer_guard_before dd 0A5C33C5Ah
render_cursor dw 0
render_buffer:
back_buffer times SCREEN_WIDTH*SCREEN_HEIGHT dw 0720h
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
hud_ready_text db 'READY',0
hud_wait_text db 'WAIT ',0
hud_boost_text db 'BOOST',0
hud_controls_text db 'SPACE: Cleaver  X: Pin  A/D: Move  ESC: Quit',0
hud_controls_end:

initialize_display:
    push ax
    push bx
    push cx
    push dx
    push si
    push es
    mov ax, 4F02h
    mov bx, 010Ch             ; Start with SVGA 132 columns and the 8x8 font.
    int 10h
    cmp ax, 004Fh
    jne .unsupported
    mov ax, 40h
    mov es, ax
    cmp word [es:4Ah], SCREEN_WIDTH
    jne .unsupported

    ; Unlock the VGA timing registers before extending the vertical raster.
    mov dx, 03D4h
    mov al, 11h
    out dx, al
    inc dx
    in al, dx
    and al, 7Fh
    out dx, al
    mov dx, 03D4h
    mov si, tall_display_timing
    mov cx, (tall_display_timing_end - tall_display_timing) / 2
    cld
.timing:
    lodsw                    ; AL=CRTC register, AH=value; OUT writes both ports.
    out dx, ax
    loop .timing
    mov byte [es:84h], SCREEN_HEIGHT - 1
    mov word [es:4Ch], 8000h  ; One complete frame uses almost 32 KiB.
    mov ah, 01h
    mov cx, 2000h
    int 10h                  ; Hide the text cursor.
    call clear_screen
    call present_frame
    ; Allow the emulator to resize before the first nonblank menu is drawn.
    mov ah, 86h
    mov cx, 3
    mov dx, 0D40h             ; 200,000 microseconds, only during mode setup.
    int 15h
    clc
    jmp .restore
.unsupported:
    stc
.restore:
    pop es
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret

; 960 visible scanlines = 120 rows * 8 pixels. 1023 total scanlines
; leave room for blanking/retrace. Overflow bits encode scanlines 8 and 9.
; Max-scanline retains eight-pixel glyphs and disables double scanning.
tall_display_timing:
    dw 0FD06h                ; Vertical total = 1023 (register stores total-2).
    dw 0FF07h                ; Vertical overflow bits; line compare > raster.
    dw 06709h                ; Eight glyph scanlines; blank/line-compare overflow.
    dw 0BF12h                ; Last visible scanline = 959 (03BFh).
    dw 0D410h                ; Vertical retrace starts at scanline 980.
    dw 02811h                ; Retrace ends at 984; timing registers unlocked.
    dw 0C015h                ; Vertical blank starts at scanline 960.
    dw 0FF16h                ; Vertical blank ends at the end of the raster.
    dw 0FF18h                ; Line compare = 1023, avoiding a split screen.
tall_display_timing_end:


clear_screen:
 pushad
 push es
 mov ax,ds
 mov es,ax
 mov di,back_buffer
 mov ax,0720h
 mov cx,SCREEN_WIDTH*SCREEN_HEIGHT
 cld
 rep stosw
 mov word [render_cursor],0
 pop es
 popad
 ret

present_frame:
present_screen:
 pushad
 push es
 mov ax,0B800h
 mov es,ax
 mov si,back_buffer
 xor di,di
 mov cx,SCREEN_WIDTH*SCREEN_HEIGHT
 cld
 rep movsw
 pop es
 popad
 ret

; EAX=x, EDX=y, BL=character, BH=text attribute. Clip before buffer access.
draw_cell:
 pushad
 cmp eax,SCREEN_WIDTH
 jae .done
 cmp edx,SCREEN_HEIGHT
 jae .done
 imul edi,edx,SCREEN_WIDTH
 add edi,eax
 shl edi,1
 mov [back_buffer+edi],bx
.done:
 popad
 ret

; Original interface kept: DH=row, DL=column. Software rendering uses DX.
set_cursor:
    push ax
    push bx
    push dx
    xor ax, ax
    mov al, dh
    mov bx, SCREEN_WIDTH
    mul bx
    pop dx
    push dx
    xor dh, dh
    add ax, dx
    shl ax, 1
    mov [render_cursor], ax
    pop dx
    pop bx
    pop ax
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
 cmp ecx,SCREEN_WIDTH
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

draw_sprite:
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    push bp
    xor ax, ax
    mov al, dh
    mov di, SCREEN_WIDTH
    push dx
    mul di
    pop dx
    xor dh, dh
    add ax, dx
    shl ax, 1
    mov di, ax
    mov bp, cx
    shr bp, 8
    xor ch, ch
    jcxz .done
    test bp, bp
    jz .done
    cld
.row:
    push cx
.cell:
    cmp di, SCREEN_WIDTH * SCREEN_HEIGHT * 2
    jae .row_done
    lodsb
    mov ah, bl
    mov [render_buffer + di], ax
    add di, 2
    loop .cell
.row_done:
    pop cx
    cmp di, SCREEN_WIDTH * SCREEN_HEIGHT * 2
    jae .done
    add di, SCREEN_WIDTH * 2
    sub di, cx
    sub di, cx
    dec bp
    jnz .row
.done:
    pop bp
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret

; -------------------------------------------------
; Procedure: draw_weapon_sprite
; Purpose: Reduce unchanged 12x16 weapon art uniformly to 6x8 screen cells.
; Input: DS:SI=source art, DH=row, DL=column, BL=color.
; Output: Each 2x2 block keeps its first nonblank source character.
; Modifies: Flags only; all general-purpose registers preserved.
; Shared: render_buffer. Chef rendering continues to use draw_sprite.
; -------------------------------------------------
draw_weapon_sprite:
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    push bp
    xor ax, ax
    mov al, dh
    mov di, SCREEN_WIDTH
    push dx
    mul di
    pop dx
    xor dh, dh
    add ax, dx
    shl ax, 1
    mov di, ax
    mov bp, WEAPON_HEIGHT
.row:
    mov cx, WEAPON_WIDTH
.cell:
    cmp di, SCREEN_WIDTH * SCREEN_HEIGHT * 2
    jae .done
    mov al, [si]
    cmp al, ' '
    jne .paint
    mov al, [si + 1]
    cmp al, ' '
    jne .paint
    mov al, [si + SOURCE_ART_WIDTH]
    cmp al, ' '
    jne .paint
    mov al, [si + SOURCE_ART_WIDTH + 1]
.paint:
    mov ah, bl
    mov [render_buffer + di], ax
    add di, 2
    add si, WEAPON_SCALE
    loop .cell
    add si, SOURCE_ART_WIDTH ; Skip the other row of each source block.
    add di, (SCREEN_WIDTH - WEAPON_WIDTH) * 2
    dec bp
    jnz .row
.done:
    pop bp
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret


draw_player:
 pushad
 test dword [invulnerable],80h
 jnz .done
 movzx eax,byte [player_x]
 movzx edx,byte [player_y]
 mov esi,player_art
 mov ecx,PLAYER_WIDTH
 mov ebp,PLAYER_HEIGHT
 mov bl,0Fh
 call draw_rectangle_art
.done:
 popad
 ret

draw_bullet:
    pushad
    xor di, di
.loop:
    cmp byte [bullets_active + di], 1
    jne .next
    mov si, cleaver_art
    mov bl, 0Bh
    cmp byte [bullets_kind + di], ROLLING_PIN
    jne .color
    mov si, rolling_pin_art
    mov bl, 0Eh
.color:
    mov al, [bullets_kind + di]
    inc al
    cmp [bullets_damage + di], al
    jbe .draw
    mov bl, 0Ch
.draw:
    mov dh, [bullets_y + di]
    mov dl, [bullets_x + di]
    call draw_weapon_sprite
.next:
    inc di
    cmp di, MAX_BULLETS
    jb .loop
    call draw_hostile_bullets
    popad
    ret


draw_hostile_bullets:
 pushad
 mov esi,shots
 mov ecx,MAX_SHOTS
.loop:
 cmp dword [esi+S_ACTIVE],0
 je .next
 mov eax,[esi+S_X]
 mov edx,[esi+S_Y]
 mov bx,0CDBh                ; 2x2 bright-red block, visible across the large arena.
 call draw_cell
 inc eax
 call draw_cell
 mov eax,[esi+S_X]
 mov edx,[esi+S_Y]
 inc edx
 mov bx,0CDBh
 call draw_cell
 inc eax
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
 mov dx,0048h
 mov si,hud_ready_text
 cmp byte [fire_cooldown],0
 je .ready
 mov si,hud_wait_text
.ready:
 call print_string
 cmp word [player_boost_frames],0
 je .footer
 mov dl,85
 mov si,hud_boost_text
 call print_string
.footer:
 mov dh,SCREEN_HEIGHT-1
 mov dl,(SCREEN_WIDTH-(hud_controls_end-hud_controls_text-1))/2
 mov si,hud_controls_text
 call print_string
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
 pushad
 call clear_screen
 call draw_hud
 call draw_enemy
 call draw_bullet
 call draw_player
 call present_screen
 popad
 ret
