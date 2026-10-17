; Food Invaders enemy system: BITS 16 real-mode execution, 386+ DWORD math.
; Included once by main.asm. No BIOS/DOS rendering calls.
; Keep the parent BITS 16 mode; NASM emits 66h/67h prefixes as necessary.
; All public functions use real-mode DWORD-argument cdecl: EBX/ESI/EDI/EBP preserved; EAX/ECX/EDX,
; flags volatile. CALL/RET addresses are WORDs; arguments are DWORDs, caller
; removes them. DS/ES must address the COM segment; ESP is normalized by main.
; Inputs/outputs and shared state documented below. Internal labels are local.

; initialize_enemies(): reads current_wave; clears encounter state/projectiles.
; Creates two rows of five regular enemies or one boss on multiples of five.
initialize_enemies:
 push ebx
 push esi
 push edi
 xor eax,eax
 mov edi,enemies
 mov ecx,MAX_ENEMIES*E_SIZE/4
 cld
 a32 rep stosd
 mov [enemy_events],eax
 mov [completion_sent],eax
 mov [move_timer],eax
 mov [attack_timer],eax
 mov [shooter_cursor],eax
 mov [boss_mode],eax
 mov dword [direction],1
 call clear_projectiles
 mov eax,[current_wave]
 xor edx,edx
 mov ecx,5
 div ecx
 test edx,edx
 jz .boss
 ; Stage scaling is capped so simulation never takes multi-cell steps.
 mov eax,[current_wave]
 dec eax
 cmp eax,8
 jbe .scale
 mov eax,8
.scale:
 imul eax,20
 mov edx,300
 sub edx,eax
 mov [move_interval],edx
 shl eax,1
 mov edx,1200
 sub edx,eax
 mov [attack_interval],edx
 mov dword [alive_count],MAX_ENEMIES
 xor ebx,ebx
 mov esi,enemies
.regular:
 mov eax,ebx
 xor edx,edx
 mov ecx,5
 div ecx
 mov [esi+E_TYPE],edx
 imul edx,T_SIZE
 mov ecx,[type_table+edx+T_HP]
 mov [esi+E_HP],ecx
 imul eax,5
 add eax,3
 mov [esi+E_Y],eax
 mov [esi+E_SY],eax
 mov eax,ebx
 xor edx,edx
 mov ecx,5
 div ecx
 imul edx,13
 add edx,10
 mov [esi+E_X],edx
 mov [esi+E_SX],edx
 mov dword [esi+E_ACTIVE],1
 add esi,E_SIZE
 inc ebx
 cmp ebx,MAX_ENEMIES
 jb .regular
 jmp .done
.boss:
 mov dword [boss_mode],1
 mov dword [alive_count],1
 mov dword [move_interval],200
 mov dword [attack_interval],900
 mov dword [enemies+E_ACTIVE],1
 mov dword [enemies+E_TYPE],5
 mov dword [enemies+E_HP],20
 mov dword [enemies+E_X],34
 mov dword [enemies+E_SX],34
 mov dword [enemies+E_Y],TOP
 mov dword [enemies+E_SY],TOP
.done:
 pop edi
 pop esi
 pop ebx
 ret

; reset_enemy_positions(): preserves HP/dead slots and resets timers/direction.
reset_enemy_positions:
 push esi
 mov esi,enemies
 mov ecx,MAX_ENEMIES
.loop:
 mov eax,[esi+E_SX]
 mov [esi+E_X],eax
 mov eax,[esi+E_SY]
 mov [esi+E_Y],eax
 add esi,E_SIZE
 loop .loop
 mov dword [direction],1
 mov dword [move_timer],0
 mov dword [attack_timer],0
 and dword [enemy_events],~EV_BREACH
 pop esi
 ret

; get_enemy_bounds(index): EAX=slot pointer or 0; EDX=type metadata pointer.
; Callers may read x/y and width/height, but must use damage API to kill.
get_enemy_bounds:
 mov eax,[esp+2]
 cmp eax,MAX_ENEMIES
 jae .invalid
 imul eax,E_SIZE
 add eax,enemies
 cmp dword [eax+E_ACTIVE],0
 je .invalid
 mov edx,[eax+E_TYPE]
 imul edx,T_SIZE
 add edx,type_table
 ret
.invalid:
 xor eax,eax
 xor edx,edx
 ret

; apply_enemy_damage(index, damage): EAX=1 only on new death, EDX=reward.
; Never awards score directly. Invalid/dead targets and nonpositive damage ignored.
apply_enemy_damage:
 push ebx
 push esi
 mov ebx,[esp+14]
 test ebx,ebx
 jle .none
 push dword [esp+10]
 call get_enemy_bounds
 add esp,4
 test eax,eax
 jz .none
 mov esi,eax
 cmp ebx,[esi+E_HP]
 jae .kill
 sub [esi+E_HP],ebx
.none:
 xor eax,eax
 xor edx,edx
 jmp .done
.kill:
 mov dword [esi+E_HP],0
 mov dword [esi+E_ACTIVE],0
 dec dword [alive_count]
 mov edx,[edx+T_SCORE]
 mov eax,1
 cmp dword [alive_count],0
 jne .done
 cmp dword [completion_sent],0
 jne .done
 mov dword [completion_sent],1
 or dword [enemy_events],EV_CLEAR
 cmp dword [boss_mode],0
 je .done
 or dword [enemy_events],EV_BOSS
.done:
 pop esi
 pop ebx
 ret

; consume_enemy_events(): returns and clears event bitset in EAX.
consume_enemy_events:
 xor eax,eax
 xchg eax,[enemy_events]
 ret

; move_enemies(): one atomic formation step. Boss reverses without descending.
move_enemies:
 push ebx
 push esi
 push edi
 cmp dword [alive_count],0
 je .done
 test dword [enemy_events],EV_BREACH
 jnz .done
 mov esi,enemies
 mov edi,MAX_ENEMIES
.check:
 cmp dword [esi+E_ACTIVE],0
 je .next
 mov eax,[esi+E_TYPE]
 imul eax,T_SIZE
 mov edx,[esi+E_X]
 add edx,[direction]
 cmp edx,LEFT
 jl .edge
 add edx,[type_table+eax+T_W]
 cmp edx,RIGHT
 jg .edge
.next:
 add esi,E_SIZE
 dec edi
 jnz .check
 mov esi,enemies
 mov ecx,MAX_ENEMIES
.horizontal:
 cmp dword [esi+E_ACTIVE],0
 je .hnext
 mov eax,[direction]
 add [esi+E_X],eax
.hnext:
 add esi,E_SIZE
 loop .horizontal
 jmp .done
.edge:
 neg dword [direction]
 cmp dword [boss_mode],0
 jne .done
 ; Validate every descent before committing any position.
 mov esi,enemies
 mov ecx,MAX_ENEMIES
.validate:
 cmp dword [esi+E_ACTIVE],0
 je .vnext
 mov eax,[esi+E_TYPE]
 imul eax,T_SIZE
 mov edx,[esi+E_Y]
 inc edx
 add edx,[type_table+eax+T_H]
 cmp edx,BOTTOM
 jg .breach
.vnext:
 add esi,E_SIZE
 loop .validate
 mov esi,enemies
 mov ecx,MAX_ENEMIES
.descend:
 cmp dword [esi+E_ACTIVE],0
 je .dnext
 inc dword [esi+E_Y]
.dnext:
 add esi,E_SIZE
 loop .descend
 jmp .done
.breach:
 or dword [enemy_events],EV_BREACH
.done:
 pop edi
 pop esi
 pop ebx
 ret

; fire_enemy(): bottommost eligible formation slot, round-robin selection.
; Every slot shares a column with the slot five places away.
fire_enemy:
 push ebx
 push esi
 push edi
 xor edi,edi
.scan:
 mov ebx,[shooter_cursor]
 inc dword [shooter_cursor]
 cmp dword [shooter_cursor],MAX_ENEMIES
 jb .cursor_ok
 mov dword [shooter_cursor],0
.cursor_ok:
 push ebx
 call get_enemy_bounds
 add esp,4
 test eax,eax
 jz .next
 cmp dword [edx+T_SHOOT],0
 je .next
 mov esi,eax
 cmp dword [boss_mode],0
 jne .spawn
 cmp ebx,5
 jae .spawn
 imul eax,ebx,E_SIZE
 cmp dword [enemies+5*E_SIZE+eax+E_ACTIVE],0
 jne .next
.spawn:
 mov ecx,[edx+T_H]
 add ecx,[esi+E_Y]
 mov eax,[edx+T_W]
 shr eax,1
 add eax,[esi+E_X]
 push ecx
 push eax
 call spawn_enemy_projectile
 add esp,8
 jmp .done
.next:
 inc edi
 cmp edi,MAX_ENEMIES
 jb .scan
.done:
 pop edi
 pop esi
 pop ebx
 ret

; update_enemies(): original no-argument interface, one nominal 50ms tick.
update_enemies:
 cmp dword [alive_count],0
 je .done
 test dword [enemy_events],EV_BREACH
 jnz .done
 mov eax,50
 add [move_timer],eax
 add [attack_timer],eax
 mov eax,[move_interval]
 cmp [move_timer],eax
 jb .attack
 sub [move_timer],eax
 call move_enemies
.attack:
 test dword [enemy_events],EV_BREACH
 jnz .done
 mov eax,[attack_interval]
 cmp [attack_timer],eax
 jb .done
 sub [attack_timer],eax
 call fire_enemy
.done:
 ret
