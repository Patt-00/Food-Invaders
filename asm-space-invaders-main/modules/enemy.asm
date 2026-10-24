; Food Invaders enemy system: BITS 16 real-mode execution, 386+ DWORD math.
; Included once by main.asm. No BIOS/DOS rendering calls.
; Keep the parent BITS 16 mode; NASM emits 66h/67h prefixes as necessary.
; All public functions use real-mode DWORD-argument cdecl: EBX/ESI/EDI/EBP preserved; EAX/ECX/EDX,
; flags volatile. CALL/RET addresses are WORDs; arguments are DWORDs, caller
; removes them. DS/ES must address the COM segment; ESP is normalized by main.
; Inputs/outputs and shared state documented below. Internal labels are local.

; seed_random(): mix the BIOS clock with the previous PRNG state at new-game start.
seed_random:
 pushad
 mov ah,00h
 int 1Ah
 movzx eax,dx
 movzx ebx,cx
 shl ebx,16
 xor eax,ebx
 xor eax,[random_state]
 test eax,eax
 jnz .store
 mov eax,1
.store:
 mov [random_state],eax
 popad
 ret

; next_random(): 32-bit LCG; EAX receives the next value.
next_random:
 mov eax,[random_state]
 imul eax,eax,1664525
 add eax,1013904223
 mov [random_state],eax
 ret

; random_in_range(): EAX=minimum, ECX=range; return [minimum, minimum+range).
random_in_range:
 push ebx
 push edx
 mov ebx,eax
 call next_random
 shr eax,16
 xor edx,edx
 div ecx
 mov eax,edx
 add eax,ebx
 pop edx
 pop ebx
 ret

random_attack_delay:
 mov eax,[attack_min_interval]
 mov ecx,[attack_interval_range]
 call random_in_range
 call scale_difficulty_interval
 ret

; random_enemy_move_interval(): select this wave's movement delay and difficulty.
random_enemy_move_interval:
 mov eax,[enemy_move_min_interval]
 mov ecx,[enemy_move_interval_range]
 call random_in_range
 call scale_difficulty_interval
 ret

; random_enemy_position(): ESI=enemy slot, store a full-field candidate position.
random_enemy_position:
 mov eax,[esi+E_TYPE]
 imul eax,T_SIZE
 mov ecx,SCREEN_WIDTH
 sub ecx,[type_table+eax+T_W]
 inc ecx
 xor eax,eax
 call random_in_range
 mov [enemy_candidate_x],al

 mov eax,[esi+E_TYPE]
 imul eax,T_SIZE
 mov ecx,ENEMY_BREACH_LINE
 sub ecx,[type_table+eax+T_H]
 sub ecx,TOP
 inc ecx
 mov eax,TOP
 call random_in_range
 mov [enemy_candidate_y],al
 ret

; Keep new sprites clear of every living enemy by the configured text-cell gap.
; EBX is the slot being placed, ESI points to that enemy, CF=1 means blocked.
enemy_position_is_clear:
 pushad
 xor edi,edi
.check:
 cmp edi,MAX_ENEMIES
 jae .clear
 cmp edi,ebx
 je .next
 mov eax,edi
 imul eax,E_SIZE
 add eax,enemies
 cmp dword [eax+E_ACTIVE],0
 je .next

 ; Separate the horizontal rectangles before checking their vertical span.
 mov ecx,[esi+E_TYPE]
 imul ecx,T_SIZE
 mov edx,[type_table+ecx+T_W]
 movzx ecx,byte [enemy_candidate_x]
 add ecx,edx
 movzx edx,byte [enemy_position_clearance]
 add ecx,edx
 cmp ecx,[eax+E_X]
 jbe .next
 mov ecx,[eax+E_TYPE]
 imul ecx,T_SIZE
 mov edx,[eax+E_X]
 add edx,[type_table+ecx+T_W]
 movzx ecx,byte [enemy_position_clearance]
 add edx,ecx
 movzx ecx,byte [enemy_candidate_x]
 cmp edx,ecx
 jbe .next

 ; The horizontal rectangles overlap, so require a safe vertical gap.
 mov ecx,[esi+E_TYPE]
 imul ecx,T_SIZE
 mov edx,[type_table+ecx+T_H]
 movzx ecx,byte [enemy_candidate_y]
 add ecx,edx
 movzx edx,byte [enemy_position_clearance]
 add ecx,edx
 cmp ecx,[eax+E_Y]
 jbe .next
 mov ecx,[eax+E_TYPE]
 imul ecx,T_SIZE
 mov edx,[eax+E_Y]
 add edx,[type_table+ecx+T_H]
 movzx ecx,byte [enemy_position_clearance]
 add edx,ecx
 movzx ecx,byte [enemy_candidate_y]
 cmp edx,ecx
 jbe .next
 jmp .blocked
.next:
 inc edi
 jmp .check
.clear:
 popad
 clc
 ret
.blocked:
 popad
 stc
 ret

; random_signed_step(): ECX=maximum distance, EAX=random signed step.
random_signed_step:
 push ebx
 mov ebx,ecx
 xor eax,eax
 lea ecx,[ebx*2+1]
 call random_in_range
 sub eax,ebx
 pop ebx
 ret

; random_enemy_step(): EBX=slot, ESI=enemy record; choose a safe random vector.
; Each axis changes independently; blocked/out-of-bounds candidates are rerolled.
random_enemy_step:
 mov dword [enemy_position_attempts],0
.try:
 mov eax,[current_wave]
 dec eax
 cmp eax,WAVE_REGULAR_COUNT-1
 jbe .x_profile
 mov eax,WAVE_REGULAR_COUNT-1
.x_profile:
 movzx ecx,byte [enemy_move_step_x_by_wave+eax]
 call random_signed_step
 mov [enemy_step_dx],al

 mov eax,[current_wave]
 dec eax
 cmp eax,WAVE_REGULAR_COUNT-1
 jbe .y_profile
 mov eax,WAVE_REGULAR_COUNT-1
.y_profile:
 movzx ecx,byte [enemy_move_step_y_by_wave+eax]
 call random_signed_step
 mov [enemy_step_dy],al
 mov al,[enemy_step_dx]
 or al,[enemy_step_dy]
 jz .retry

 movzx eax,byte [esi+E_X]
 movsx edx,byte [enemy_step_dx]
 add eax,edx
 cmp eax,LEFT
 jl .retry
 mov [enemy_candidate_x],al
 mov edx,[esi+E_TYPE]
 imul edx,T_SIZE
 add eax,[type_table+edx+T_W]
 cmp eax,SCREEN_WIDTH
 ja .retry

 movzx eax,byte [esi+E_Y]
 movsx edx,byte [enemy_step_dy]
 add eax,edx
 cmp eax,TOP
 jl .retry
 mov [enemy_candidate_y],al
 mov edx,[esi+E_TYPE]
 imul edx,T_SIZE
 add eax,[type_table+edx+T_H]
 cmp eax,ENEMY_BREACH_LINE
 jae .retry
 call enemy_position_is_clear
 jc .retry

 movzx eax,byte [enemy_candidate_x]
 mov [esi+E_X],eax
 movzx eax,byte [enemy_candidate_y]
 mov [esi+E_Y],eax
 clc
 ret
.retry:
 inc dword [enemy_position_attempts]
 cmp dword [enemy_position_attempts],ENEMY_RANDOM_STEP_TRIES
 jb .try
 stc
 ret

; place_enemy_randomly(): EBX=slot, ESI=enemy pointer; scatter without overlap.
place_enemy_randomly:
 mov byte [enemy_position_clearance],ENEMY_CLEARANCE
.random_try:
 call random_enemy_position
 mov eax,[esi+E_TYPE]
 imul eax,T_SIZE
 movzx ecx,byte [enemy_candidate_y]
 add ecx,[type_table+eax+T_H]
 cmp ecx,ENEMY_BREACH_LINE
 jae .retry_candidate
 call enemy_position_is_clear
 jnc .placed
.retry_candidate:
 ; Keep every spawn randomized; do not fall back to a fixed grid.
 jmp .random_try
.placed:
 movzx eax,byte [enemy_candidate_x]
 mov [esi+E_X],eax
 mov [esi+E_SX],eax
 movzx eax,byte [enemy_candidate_y]
 mov [esi+E_Y],eax
 mov [esi+E_SY],eax
 mov dword [esi+E_ACTIVE],1
 mov byte [enemy_position_clearance],ENEMY_CLEARANCE
 ret

; scale_difficulty_interval(): EAX=base delay; return adjusted delay.
; Easy is 1.5x slower, normal is unchanged, hard is 0.75x faster.
scale_difficulty_interval:
 cmp byte [difficulty_level],DIFFICULTY_EASY
 je .easy
 cmp byte [difficulty_level],DIFFICULTY_HARD
 je .hard
 ret
.easy:
 imul eax,eax,3
 xor edx,edx
 mov ecx,2
 div ecx
 ret
.hard:
 imul eax,eax,3
 xor edx,edx
 mov ecx,4
 div ecx
 test eax,eax
 jnz .done
 inc eax
.done:
 ret

; initialize_enemies(): clears encounter state and scatters ten regular enemies.
; Every fifth wave contains one boss.
initialize_enemies:
 push ebx
 push esi
 push edi
 xor eax,eax
 mov edi,enemies
 mov ecx,MAX_ENEMIES*E_SIZE/4
 cld
 a32 rep stosd
 ; The next four per-enemy timer/interval tables are contiguous; clear all
 ; four so movement and firing delays do not carry into the next stage.
 mov edi,enemy_move_timers
 mov ecx,MAX_ENEMIES*4
 a32 rep stosd
 mov edi,enemy_shoot_enabled
 mov ecx,MAX_ENEMIES
 a32 rep stosb
 mov [enemy_events],eax
 mov [completion_sent],eax
 mov [shooter_cursor],eax
 mov [boss_mode],eax
 mov byte [enemy_position_clearance],ENEMY_CLEARANCE
 call clear_projectiles
 mov eax,[current_wave]
 xor edx,edx
 mov ecx,5
 div ecx
 test edx,edx
 jz .boss
 ; Each wave advances movement, attack, and hostile-shot speed.
 mov eax,[current_wave]
 dec eax
 cmp eax,WAVE_REGULAR_COUNT-1
 jbe .scale
 mov eax,WAVE_REGULAR_COUNT-1
.scale:
 mov ecx,eax
 imul eax,ENEMY_ATTACK_STAGE_ACCEL_MS
 mov edx,ENEMY_ATTACK_BASE_MIN_MS
 sub edx,eax
 mov [attack_min_interval],edx
 mov edx,ENEMY_ATTACK_BASE_RANGE_MS
 sub edx,eax
 mov [attack_interval_range],edx
 mov eax,ecx
 imul eax,ENEMY_MOVE_STAGE_ACCEL_MS
 mov edx,ENEMY_MOVE_BASE_MIN_MS
 sub edx,eax
 mov [enemy_move_min_interval],edx
 mov edx,ENEMY_MOVE_BASE_RANGE_MS
 sub edx,eax
 mov [enemy_move_interval_range],edx
 mov eax,ecx
 imul eax,HOSTILE_SHOT_STAGE_ACCEL_MS
 mov edx,HOSTILE_SHOT_BASE_MS
 sub edx,eax
 mov [enemy_shot_step_ms],edx
 mov dword [alive_count],MAX_ENEMIES
 xor ebx,ebx
 mov esi,enemies
.regular:
 mov eax,[current_wave]
 dec eax
 cmp eax,WAVE_REGULAR_COUNT-1
 jbe .type_wave_ok
 mov eax,WAVE_REGULAR_COUNT-1
.type_wave_ok:
 imul eax,MAX_ENEMIES
 add eax,ebx
 movzx eax,byte [wave_enemy_type_map+eax]
 mov [esi+E_TYPE],eax
 mov edx,eax
 imul edx,T_SIZE
 mov ecx,[type_table+edx+T_HP]
 mov [esi+E_HP],ecx

 ; Later waves add shooters with distinct enemy art.
 mov eax,[esi+E_TYPE]
 imul eax,T_SIZE
 mov edx,[type_table+eax+T_SHOOT]
 mov [enemy_shoot_enabled+ebx],dl
 mov eax,[current_wave]
 dec eax
 cmp eax,WAVE_REGULAR_COUNT-1
 jbe .bonus_wave_ok
 mov eax,WAVE_REGULAR_COUNT-1
.bonus_wave_ok:
 shl eax,2
 mov edx,[wave_extra_shooter_masks+eax]
 mov ecx,ebx
 shr edx,cl
 test dl,1
 jz .no_bonus_shooter
 mov byte [enemy_shoot_enabled+ebx],1
.no_bonus_shooter:
 call place_enemy_randomly
 call random_enemy_move_interval
 mov [enemy_move_intervals+ebx*4],eax
 cmp byte [enemy_shoot_enabled+ebx],0
 je .no_fire_timer
 call random_attack_delay
 mov [enemy_fire_intervals+ebx*4],eax
.no_fire_timer:
 add esi,E_SIZE
 inc ebx
 cmp ebx,MAX_ENEMIES
 jb .regular
 jmp .done
.boss:
 mov dword [boss_mode],1
 mov dword [alive_count],1
 mov dword [attack_min_interval],1000
 mov dword [attack_interval_range],1001
 mov dword [enemy_move_min_interval],50
 mov dword [enemy_move_interval_range],121
 mov dword [enemy_shot_step_ms],HOSTILE_SHOT_BASE_MS-HOSTILE_SHOT_STAGE_ACCEL_MS*3
 mov byte [enemy_shoot_enabled],1
 mov dword [enemies+E_TYPE],5
 mov dword [enemies+E_HP],20
 xor ebx,ebx
 mov esi,enemies
 call place_enemy_randomly
 call random_enemy_move_interval
 mov [enemy_move_intervals],eax
 call random_attack_delay
 mov [enemy_fire_intervals],eax
.done:
 pop edi
 pop esi
 pop ebx
 ret

; reset_enemy_positions(): preserves HP/dead slots and resets movement timers.
reset_enemy_positions:
 push esi
 push edi
 push ebx
 mov byte [enemy_position_clearance],ENEMY_CLEARANCE
 mov esi,enemies
 xor edi,edi
 mov ecx,MAX_ENEMIES
.loop:
 mov eax,[esi+E_SX]
 mov [esi+E_X],eax
 mov eax,[esi+E_SY]
 mov [esi+E_Y],eax
 mov dword [enemy_move_timers+edi*4],0
 mov dword [enemy_fire_timers+edi*4],0
 add esi,E_SIZE
 inc edi
 loop .loop
 and dword [enemy_events],~EV_BREACH
 pop ebx
 pop edi
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

; fire_enemy(): random starting slot followed by an eligibility scan.
; The random cursor avoids choosing the same active shooter every time.
fire_enemy:
 push ebx
 push esi
 push edi
 call next_random
 shr eax,16
 xor edx,edx
 mov ecx,MAX_ENEMIES
 div ecx
 mov [shooter_cursor],edx
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
 cmp byte [enemy_shoot_enabled+ebx],0
 je .next
 mov esi,eax
.spawn:
 mov ecx,[edx+T_H]
 add ecx,[esi+E_Y]
 mov eax,[edx+T_W]
 shr eax,1
 add eax,[esi+E_X]
 sub eax,HOSTILE_SHOT_WIDTH/2
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

; fire_enemy_slot(): EBX is the shooter whose independent timer expired.
fire_enemy_slot:
 push ebx
 push esi
 push edi
 push ebx
 call get_enemy_bounds
 add esp,4
 test eax,eax
 jz .done
 cmp byte [enemy_shoot_enabled+ebx],0
 je .done
 mov esi,eax
 mov ecx,[edx+T_H]
 add ecx,[esi+E_Y]
 mov eax,[edx+T_W]
 shr eax,1
 add eax,[esi+E_X]
 sub eax,HOSTILE_SHOT_WIDTH/2
 push ecx
 push eax
 call spawn_enemy_projectile
 add esp,8
.done:
 pop edi
 pop esi
 pop ebx
 ret

; update_enemies(): independently wander active enemies and schedule a random volley.
update_enemies:
 pushad
 cmp dword [alive_count],0
 je .done
 test dword [enemy_events],EV_BREACH
 jnz .done
 xor ebx,ebx
 mov esi,enemies
.wander:
 cmp dword [esi+E_ACTIVE],0
 je .next_enemy
 mov eax,[enemy_move_timers+ebx*4]
 add eax,50
 mov [enemy_move_timers+ebx*4],eax
 cmp eax,[enemy_move_intervals+ebx*4]
 jb .fire_timer
 sub eax,[enemy_move_intervals+ebx*4]
 mov [enemy_move_timers+ebx*4],eax
 call random_enemy_step
 .reschedule:
 call random_enemy_move_interval
 mov [enemy_move_intervals+ebx*4],eax
.fire_timer:
 cmp byte [enemy_shoot_enabled+ebx],0
 je .next_enemy
 mov eax,[enemy_fire_timers+ebx*4]
 add eax,50
 mov [enemy_fire_timers+ebx*4],eax
 cmp eax,[enemy_fire_intervals+ebx*4]
 jb .next_enemy
 sub eax,[enemy_fire_intervals+ebx*4]
 mov [enemy_fire_timers+ebx*4],eax
 call random_attack_delay
 mov [enemy_fire_intervals+ebx*4],eax
 call fire_enemy_slot
.next_enemy:
 add esi,E_SIZE
 inc ebx
 cmp ebx,MAX_ENEMIES
 jb .wander
.done:
 popad
 ret
