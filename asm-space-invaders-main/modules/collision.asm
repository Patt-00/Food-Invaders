; Shared rectangle collision for every player shot and enemy type.
; Public checks require DS=shared segment, preserve all general-purpose
; registers, and ignore non-PLAYING states. Contacts/breaches are aggregated
; in loss_pending; resolve_game_events applies one life loss per tick.
check_bullet_enemy:
 pushad
 cmp byte [game_state],PLAYING
 jne .done
 xor edi,edi
.shot:
 cmp byte [bullets_active+di],1
 jne .next_shot
 xor ebx,ebx
.enemy:
 push ebx
 call get_enemy_bounds
 add esp,4
 test eax,eax
 jz .next_enemy
 mov esi,eax
 movzx ecx,byte [bullets_x+di]
 mov eax,ecx
 add eax,WEAPON_WIDTH
 cmp eax,[esi+E_X]
 jle .next_enemy
 mov eax,[esi+E_X]
 add eax,[edx+T_W]
 cmp ecx,eax
 jge .next_enemy
 movzx ecx,byte [bullets_y+di]
 mov eax,ecx
 add eax,WEAPON_HEIGHT
 cmp eax,[esi+E_Y]
 jle .next_enemy
 mov eax,[esi+E_Y]
 add eax,[edx+T_H]
 cmp ecx,eax
 jge .next_enemy
 movzx ecx,byte [bullets_damage+di]
 mov si,di
 call remove_bullet_slot
 push ecx
 push ebx
 call apply_enemy_damage
 add esp,8
 add [score],edx
 jmp .next_shot
.next_enemy:
 inc ebx
 cmp ebx,MAX_ENEMIES
 jb .enemy
.next_shot:
 inc edi
 cmp edi,MAX_BULLETS
 jb .shot
.done:
 popad
 ret

check_enemy_player:
 pushad
 cmp byte [game_state],PLAYING
 jne .done
 cmp dword [invulnerable],0
 jne .done
 xor ebx,ebx
.loop:
 push ebx
 call get_enemy_bounds
 add esp,4
 test eax,eax
 jz .next
 mov esi,eax
 movzx ecx,byte [player_x]
 mov eax,ecx
 add eax,PLAYER_WIDTH
 cmp eax,[esi+E_X]
 jle .next
 mov eax,[esi+E_X]
 add eax,[edx+T_W]
 cmp ecx,eax
 jge .next
 movzx ecx,byte [player_y]
 mov eax,ecx
 add eax,PLAYER_HEIGHT
 cmp eax,[esi+E_Y]
 jle .next
 mov eax,[esi+E_Y]
 add eax,[edx+T_H]
 cmp ecx,eax
 jge .next
 mov dword [loss_pending],1
 jmp .done
.next:
 inc ebx
 cmp ebx,MAX_ENEMIES
 jb .loop
.done:
 popad
 ret


check_hostile_hits:
 pushad
 cmp byte [game_state],PLAYING
 jne .done
 mov esi,shots
 mov ecx,MAX_SHOTS
.loop:
 cmp dword [esi+S_ACTIVE],0
 je .next
 ; Projectile rectangle must overlap the small central danger area, not the
 ; Chef's entire decorative 12x16 sprite. This leaves clear lanes to dodge.
 mov eax,[esi+S_X]
 add eax,HOSTILE_SHOT_WIDTH
 movzx edx,byte [player_x]
 add edx,PLAYER_DANGER_X
 cmp eax,edx
 jbe .next
 mov eax,[esi+S_X]
 movzx edx,byte [player_x]
 add edx,PLAYER_DANGER_X+PLAYER_DANGER_WIDTH
 cmp eax,edx
 jae .next
 mov eax,[esi+S_Y]
 add eax,HOSTILE_SHOT_HEIGHT
 movzx edx,byte [player_y]
 add edx,PLAYER_DANGER_Y
 cmp eax,edx
 jbe .next
 mov eax,[esi+S_Y]
 movzx edx,byte [player_y]
 add edx,PLAYER_DANGER_Y+PLAYER_DANGER_HEIGHT
 cmp eax,edx
 jae .next
 mov dword [esi+S_ACTIVE],0
 cmp dword [invulnerable],0
 jne .next
 mov dword [loss_pending],1
.next:
 add esi,S_SIZE
 loop .loop
.done:
 popad
 ret


; Latch an occupied cell entering the footer, or an atomic movement breach.
check_enemy_bottom:
 pushad
 cmp byte [game_state],PLAYING
 jne .done
 test dword [enemy_events],EV_BREACH
 jnz .breach
 xor ebx,ebx
.loop:
 push ebx
 call get_enemy_bounds
 add esp,4
 test eax,eax
 jz .next
 mov ecx,[eax+E_Y]
 add ecx,[edx+T_H]
 cmp ecx,BOTTOM
 jg .breach
.next:
 inc ebx
 cmp ebx,MAX_ENEMIES
 jb .loop
 jmp .done
.breach:
 or dword [enemy_events],EV_BREACH
 cmp dword [invulnerable],0
 jne .done
 mov dword [loss_pending],1
.done:
 popad
 ret

check_collisions:
 call check_bullet_enemy
 call check_enemy_player
 call check_hostile_hits
 call check_enemy_bottom
 ret
