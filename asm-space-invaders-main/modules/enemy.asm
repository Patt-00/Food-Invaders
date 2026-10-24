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

; random_enemy_lane_drop_interval(): scaled delay before one lane descends.
random_enemy_lane_drop_interval:
 mov eax,[enemy_lane_drop_min_interval]
 mov ecx,[enemy_lane_drop_interval_range]
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

; get_formation_lane_offset(): EBX=enemy slot, EAX=wave-specific vertical offset.
get_formation_lane_offset:
 push ecx
 push edx
 mov eax,ebx
 xor edx,edx
 mov ecx,ENEMY_LANE_COUNT
 div ecx
 mov ecx,[current_wave]
 dec ecx
 cmp ecx,WAVE_REGULAR_COUNT-1
 jbe .wave_ok
 mov ecx,WAVE_REGULAR_COUNT-1
.wave_ok:
 imul ecx,ENEMY_LANE_COUNT
 add ecx,edx
 movzx eax,byte [formation_lane_offsets+ecx]
 pop edx
 pop ecx
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

; choose_enemy_target(): EBX=slot, ESI=enemy record; choose a spaced random destination.
choose_enemy_target:
 push ecx
 push edx
 push edi
 push ebp
 cmp dword [boss_mode],0
 jne .boss_target

 ; Regular sprites stay within one of five columns and one of two vertical
 ; bands. Each column applies its own descent offset to both enemies, while
 ; the largest 22-cell design stays inside its lane.
 mov edx,[esi+E_TYPE]
 imul edx,T_SIZE
 mov edi,[type_table+edx+T_W]
 mov eax,ebx
 xor edx,edx
 mov ecx,ENEMY_LANE_COUNT
 div ecx
 movzx ebp,byte [enemy_lane_descent+edx]
 call get_formation_lane_offset
 add ebp,eax
 imul edx,ENEMY_LANE_WIDTH
 add edx,(SCREEN_WIDTH-ENEMY_LANE_COUNT*ENEMY_LANE_WIDTH)/2
 mov ecx,ENEMY_LANE_WIDTH
 sub ecx,edi
 inc ecx
 mov eax,edx
 call random_in_range
 mov [enemy_target_x+ebx],al

 mov eax,ebx
 xor edx,edx
 mov ecx,ENEMY_LANE_COUNT
 div ecx
 test eax,eax
 jnz .rear_band
 mov eax,ENEMY_FRONT_TOP
 add eax,ebp
 mov ecx,ENEMY_FRONT_BAND_HEIGHT
 jmp .target_y
.rear_band:
 mov eax,ENEMY_REAR_TOP
 add eax,ebp
 mov ecx,ENEMY_REAR_BAND_HEIGHT
.target_y:
 mov edx,[esi+E_TYPE]
 imul edx,T_SIZE
 sub ecx,[type_table+edx+T_H]
 inc ecx
 call random_in_range
 mov [enemy_target_y+ebx],al
 jmp .done

.boss_target:
 mov edx,[esi+E_TYPE]
 imul edx,T_SIZE
 mov ecx,SCREEN_WIDTH
 sub ecx,[type_table+edx+T_W]
 inc ecx
 xor eax,eax
 call random_in_range
 mov [enemy_target_x+ebx],al
 mov eax,BOSS_MIN_Y
 mov ecx,BOSS_Y_RANGE
 call random_in_range
 mov [enemy_target_y+ebx],al
.done:
 pop ebp
 pop edi
 pop edx
 pop ecx
 ret

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
 ; The next four per-enemy timer/interval tables are contiguous; clear all
 ; four so movement and firing delays do not carry into the next stage.
 mov edi,enemy_move_timers
 mov ecx,MAX_ENEMIES*4
 a32 rep stosd
 ; Lane descent timers restart independently for each formation.
 mov edi,enemy_lane_drop_timers
 mov ecx,ENEMY_LANE_COUNT*2
 a32 rep stosd
 mov edi,enemy_lane_descent
 mov ecx,ENEMY_LANE_COUNT
 a32 rep stosb
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
 imul eax,ENEMY_LANE_DROP_STAGE_ACCEL_MS
 mov edx,ENEMY_LANE_DROP_MIN_MS
 sub edx,eax
 mov [enemy_lane_drop_min_interval],edx
 mov edx,ENEMY_LANE_DROP_RANGE_MS
 sub edx,eax
 mov [enemy_lane_drop_interval_range],edx
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
 mov dword [move_interval],300 ; Legacy field; live movement uses per-enemy random timers.
 mov dword [alive_count],MAX_ENEMIES
 xor ebx,ebx
.lane_drop_intervals:
 call random_enemy_lane_drop_interval
 mov [enemy_lane_drop_intervals+ebx*4],eax
 inc ebx
 cmp ebx,ENEMY_LANE_COUNT
 jb .lane_drop_intervals
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
 movzx eax,byte [formation_type_map+eax]
 mov [esi+E_TYPE],eax
 mov edx,eax
 imul edx,T_SIZE
 mov ecx,[type_table+edx+T_HP]
 mov [esi+E_HP],ecx

 ; Center each complete ASCII design inside its own 26-cell column lane.
 mov eax,ebx
 xor edx,edx
 mov ecx,ENEMY_LANE_COUNT
 div ecx
 mov edi,eax
 imul edx,ENEMY_LANE_WIDTH
 add edx,(SCREEN_WIDTH-ENEMY_LANE_COUNT*ENEMY_LANE_WIDTH)/2
 mov eax,[esi+E_TYPE]
 imul eax,T_SIZE
 mov ecx,ENEMY_LANE_WIDTH
 sub ecx,[type_table+eax+T_W]
 shr ecx,1
 add edx,ecx
 mov [esi+E_X],edx
 mov [esi+E_SX],edx

 cmp edi,0
 jne .rear_start
 mov eax,ENEMY_FRONT_TOP
 mov ecx,ENEMY_FRONT_BAND_HEIGHT
 jmp .start_y
.rear_start:
 mov eax,ENEMY_REAR_TOP
 mov ecx,ENEMY_REAR_BAND_HEIGHT
.start_y:
 mov edx,[esi+E_TYPE]
 imul edx,T_SIZE
 sub ecx,[type_table+edx+T_H]
 shr ecx,1
 add eax,ecx
 mov edi,eax
 call get_formation_lane_offset
 add edi,eax
 mov [esi+E_Y],edi
 mov [esi+E_SY],edi
 mov dword [esi+E_ACTIVE],1
 call random_enemy_move_interval
 mov [enemy_move_intervals+ebx*4],eax
 call choose_enemy_target
 mov eax,[esi+E_TYPE]
 imul eax,T_SIZE
 cmp dword [type_table+eax+T_SHOOT],0
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
 mov dword [move_interval],200
 mov dword [attack_min_interval],1200
 mov dword [attack_interval_range],1201
 mov dword [enemy_move_min_interval],90
 mov dword [enemy_move_interval_range],181
 mov dword [enemy_shot_step_ms],90
 mov dword [enemies+E_ACTIVE],1
 mov dword [enemies+E_TYPE],5
 mov dword [enemies+E_HP],20
 mov dword [enemies+E_X],34
 mov dword [enemies+E_SX],34
 mov dword [enemies+E_Y],TOP
 mov dword [enemies+E_SY],TOP
 xor ebx,ebx
 mov esi,enemies
 call choose_enemy_target
 call random_enemy_move_interval
 mov [enemy_move_intervals],eax
 call random_attack_delay
 mov [enemy_fire_intervals],eax
.done:
 pop edi
 pop esi
 pop ebx
 ret

; reset_enemy_positions(): preserves HP/dead slots and resets movement/drop timers.
reset_enemy_positions:
 push esi
 push edi
 push ebx
 xor eax,eax
 mov edi,enemy_lane_descent
 mov ecx,ENEMY_LANE_COUNT
 a32 rep stosb
 mov edi,enemy_lane_drop_timers
 mov ecx,ENEMY_LANE_COUNT
 a32 rep stosd
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
 cmp dword [esi+E_ACTIVE],0
 je .next_reset
 mov ebx,edi
 call choose_enemy_target
.next_reset:
 add esi,E_SIZE
 inc edi
 loop .loop
 mov dword [direction],1
 mov dword [move_timer],0
 mov dword [attack_timer],0
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

; fire_enemy(): random starting slot followed by an eligibility scan.
; Upper-row shooters are skipped while their lower-row ally is alive.
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
 cmp dword [edx+T_SHOOT],0
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

; Higher waves move farther on each randomly timed horizontal step.
random_enemy_horizontal_step:
 mov eax,1
 mov ecx,3
 cmp dword [current_wave],3
 jb .roll
 mov ecx,4
.roll:
 call random_in_range
 ret

; Higher waves also vary the size of vertical movement.
random_enemy_vertical_step:
 mov eax,1
 mov ecx,2
 cmp dword [current_wave],3
 jb .roll
 mov ecx,3
.roll:
 call random_in_range
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
 call next_random
 shr eax,16
 test al,1
 jz .move_x
 jmp .move_y
.move_x:
 movzx edi,byte [enemy_target_x+ebx]
 mov eax,[esi+E_X]
 cmp eax,edi
 je .move_y
 jb .x_right
 call random_enemy_horizontal_step
 mov edx,[esi+E_X]
 sub edx,eax
 jc .x_left_target
 cmp edx,edi
 jae .x_left_store
.x_left_target:
 mov edx,edi
.x_left_store:
 mov [esi+E_X],edx
 jmp .reschedule
.x_right:
 call random_enemy_horizontal_step
 mov edx,[esi+E_X]
 add edx,eax
 cmp edx,edi
 jbe .x_right_store
 mov edx,edi
.x_right_store:
 mov [esi+E_X],edx
 jmp .reschedule
.move_y:
 movzx edi,byte [enemy_target_y+ebx]
 mov eax,[esi+E_Y]
 cmp eax,edi
 je .choose_target
 jb .y_down
 call random_enemy_vertical_step
 mov edx,[esi+E_Y]
 sub edx,eax
 jc .y_up_target
 cmp edx,edi
 jae .y_up_store
.y_up_target:
 mov edx,edi
.y_up_store:
 mov [esi+E_Y],edx
 jmp .reschedule
.y_down:
 call random_enemy_vertical_step
 mov edx,[esi+E_Y]
 add edx,eax
 cmp edx,edi
 jbe .y_down_store
 mov edx,edi
.y_down_store:
 mov [esi+E_Y],edx
 jmp .reschedule
.choose_target:
 movzx eax,byte [enemy_target_x+ebx]
 cmp eax,[esi+E_X]
 jne .reschedule
 movzx eax,byte [enemy_target_y+ebx]
 cmp eax,[esi+E_Y]
 jne .reschedule
 call choose_enemy_target
.reschedule:
 call random_enemy_move_interval
 mov [enemy_move_intervals+ebx*4],eax
.fire_timer:
 mov eax,[esi+E_TYPE]
 imul eax,T_SIZE
 cmp dword [type_table+eax+T_SHOOT],0
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
 jmp .lane_descent
.lane_descent:
 ; Lane pairs descend on separate timers, so the formation never steps down
 ; as one synchronized block.
 cmp dword [boss_mode],0
 jne .done
 xor ebx,ebx
.lane:
 mov eax,[enemy_lane_drop_timers+ebx*4]
 add eax,50
 cmp eax,[enemy_lane_drop_intervals+ebx*4]
 jb .store_lane_timer
 sub eax,[enemy_lane_drop_intervals+ebx*4]
 mov [enemy_lane_drop_timers+ebx*4],eax
 inc byte [enemy_lane_descent+ebx]

 mov esi,enemies
 mov eax,ebx
 imul eax,E_SIZE
 add esi,eax
 cmp dword [esi+E_ACTIVE],0
 je .rear_lane
 inc dword [esi+E_Y]
 inc byte [enemy_target_y+ebx]
.rear_lane:
 mov esi,enemies
 mov eax,ebx
 add eax,ENEMY_LANE_COUNT
 imul eax,E_SIZE
 add esi,eax
 cmp dword [esi+E_ACTIVE],0
 je .reschedule_lane
 inc dword [esi+E_Y]
 inc byte [enemy_target_y+ebx+ENEMY_LANE_COUNT]
.reschedule_lane:
 call random_enemy_lane_drop_interval
 mov [enemy_lane_drop_intervals+ebx*4],eax
 jmp .next_lane
.store_lane_timer:
 mov [enemy_lane_drop_timers+ebx*4],eax
.next_lane:
 inc ebx
 cmp ebx,ENEMY_LANE_COUNT
 jb .lane
.done:
 popad
 ret
