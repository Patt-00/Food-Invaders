; Collision reads the same bounds/type table as movement and drawing.
; Real-mode DWORD cdecl, nonvolatile 32-bit registers preserved. Contacts are aggregated, then resolved.

; check_bullet_enemy(): point vs half-open enemy rectangle, one bullet/one hit.
check_bullet_enemy:
 push ebx
 push esi
 cmp byte [bullet_active],0
 je .done
 xor ebx,ebx
.loop:
 push ebx
 call get_enemy_bounds
 add esp,4
 test eax,eax
 jz .next
 mov esi,eax
 movzx ecx,byte [bullet_x]
 cmp ecx,[esi+E_X]
 jl .next
 mov eax,[esi+E_X]
 add eax,[edx+T_W]
 cmp ecx,eax
 jge .next
 movzx ecx,byte [bullet_y]
 cmp ecx,[esi+E_Y]
 jl .next
 mov eax,[esi+E_Y]
 add eax,[edx+T_H]
 cmp ecx,eax
 jge .next
 mov byte [bullet_active],0
 push dword 1
 push ebx
 call apply_enemy_damage
 add esp,8
 add [score],edx
 jmp .done
.next:
 inc ebx
 cmp ebx,MAX_ENEMIES
 jb .loop
.done:
 pop esi
 pop ebx
 ret

; check_enemy_player(): AABB overlap, no hit on merely touching edges.
check_enemy_player:
 push ebx
 push esi
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
 pop esi
 pop ebx
 ret

; check_hostile_hits(): consumes shots even during player invulnerability.
check_hostile_hits:
 push esi
 mov esi,shots
 mov ecx,MAX_SHOTS
.loop:
 cmp dword [esi+S_ACTIVE],0
 je .next
 mov eax,[esi+S_X]
 movzx edx,byte [player_x]
 sub eax,edx
 cmp eax,PLAYER_WIDTH
 jae .next
 mov eax,[esi+S_Y]
 movzx edx,byte [player_y]
 sub eax,edx
 cmp eax,PLAYER_HEIGHT
 jae .next
 mov dword [esi+S_ACTIVE],0
 cmp dword [invulnerable],0
 jne .next
 mov dword [loss_pending],1
.next:
 add esi,S_SIZE
 loop .loop
 pop esi
 ret

; check_collisions(): does not immediately mutate stage/lives, allowing aggregation.
check_collisions:
 call check_bullet_enemy
 call check_enemy_player
 call check_hostile_hits
 test dword [enemy_events],EV_BREACH
 jz .done
 cmp dword [invulnerable],0
 jne .done
 mov dword [loss_pending],1
.done:
 ret
