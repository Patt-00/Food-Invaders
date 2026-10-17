; DOSBox real mode, 386+ arithmetic; original player bullet stays byte-sized.
; Public no-argument routines preserve all general-purpose registers.
fire_bullet:
 pushad
 cmp byte [bullet_active],0
 jne .done
 cmp dword [fire_timer],0
 jne .done
 movzx eax,byte [player_x]
 add eax,2
 mov [bullet_x],al
 movzx eax,byte [player_y]
 dec eax
 mov [bullet_y],al
 mov byte [bullet_active],1
 mov dword [fire_timer],250
.done:
 popad
 ret

remove_bullet:
 mov byte [bullet_active],0
 ret

; Clears both player and hostile shots, resets hostile movement timer.
clear_projectiles:
 pushad
 cld
 xor eax,eax
 mov edi,shots
 mov ecx,MAX_SHOTS*S_SIZE/4
 a32 rep stosd
 mov byte [bullet_active],0
 mov dword [shot_timer],0
 popad
 ret

; spawn_enemy_projectile(x,y): DWORD args, 2-byte return address.
; EAX=1 if allocated, 0 on invalid position/full pool; ECX/EDX/flags volatile.
; Preserves EBX/ESI/EDI/EBP, DS/ES. All hostile shots use this bounded pool.
spawn_enemy_projectile:
 push esi
 mov eax,[esp+6]
 mov edx,[esp+10]
 cmp eax,LEFT
 jl .fail
 cmp eax,RIGHT
 jge .fail
 cmp edx,TOP
 jl .fail
 cmp edx,BOTTOM
 jge .fail
 mov esi,shots
 mov ecx,MAX_SHOTS
.find:
 cmp dword [esi+S_ACTIVE],0
 je .spawn
 add esi,S_SIZE
 loop .find
.fail:
 xor eax,eax
 jmp .done
.spawn:
 mov [esi+S_X],eax
 mov [esi+S_Y],edx
 mov dword [esi+S_ACTIVE],1
 mov eax,1
.done:
 pop esi
 ret

; Fixed 50ms tick: saturating cooldowns and start a new damage aggregation.
update_combat_timers:
 pushad
 mov eax,[fire_timer]
 sub eax,50
 jnc .fire
 xor eax,eax
.fire:
 mov [fire_timer],eax
 mov eax,[invulnerable]
 sub eax,50
 jnc .inv
 xor eax,eax
.inv:
 mov [invulnerable],eax
 mov dword [loss_pending],0
 popad
 ret

; Before/after one-cell checks prevent projectile tunnelling.
; Player moves one row per tick; hostile shots move every three ticks.
update_bullets:
 pushad
 call check_bullet_enemy
 cmp byte [bullet_active],0
 je .hostile
 cmp byte [bullet_y],TOP
 jbe .remove
 movzx eax,byte [bullet_y]
 dec eax
 mov [bullet_y],al
 call check_bullet_enemy
 jmp .hostile
.remove:
 call remove_bullet
.hostile:
 call check_hostile_hits
 add dword [shot_timer],50
 cmp dword [shot_timer],150
 jb .done
 sub dword [shot_timer],150
 mov esi,shots
 mov ecx,MAX_SHOTS
.move:
 cmp dword [esi+S_ACTIVE],0
 je .next
 inc dword [esi+S_Y]
 cmp dword [esi+S_Y],BOTTOM
 jl .next
 mov dword [esi+S_ACTIVE],0
.next:
 add esi,S_SIZE
 loop .move
 call check_hostile_hits
.done:
 popad
 ret
