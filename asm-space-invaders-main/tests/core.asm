section .data
test_count dd 0
written dd 0
output_buffer times 160 db 0
result_format db 'PASS: %u assertions (32-bit NASM simulation)',13,10,0
stress_remaining dd 0
campaign_stage dd 1
campaign_slot dd 0

section .text
; Assertions exercise compiled game routines, not a reimplementation/model.
%macro check 3
 cmp %1,%2
 je %%ok
 section .data
 %%message db 'FAIL: ',%3,13,10
 %%length equ $-%%message
 section .text
 mov ecx,%%message
 mov edx,%%length
 jmp test_failed
%%ok:
 inc dword [test_count]
%endmacro

tests_start:
 mov ax,cs
 mov ds,ax
 mov es,ax
 movzx esp,sp
 cld
 call initialize_game
 check byte [game_state],PLAYING,'new game state'
 check dword [alive_count],10,'formation count'
 check byte [player_lives],3,'starting lives'
 check dword [enemies+2*E_SIZE+E_HP],2,'burger HP'
 check dword [enemies+4*E_SIZE+E_HP],2,'pizza HP'
 ; Movement timing: five ticks do not move, sixth tick moves one cell.
 mov ebx,5
.wait:
 push dword 50
 call update_enemies
 add esp,4
 dec ebx
 jnz .wait
 check dword [enemies+E_X],10,'movement cooldown'
 push dword 50
 call update_enemies
 add esp,4
 check dword [enemies+E_X],11,'timed horizontal movement'
 ; Both edges, and no repeated descent on the following horizontal tick.
 call solo
 mov dword [enemies+E_X],75
 mov dword [enemies+E_Y],3
 call move_enemies
 check dword [direction],-1,'right edge reverses'
 check dword [enemies+E_X],75,'edge tick no horizontal step'
 check dword [enemies+E_Y],4,'edge descent once'
 call move_enemies
 check dword [enemies+E_X],74,'next tick moves away'
 check dword [enemies+E_Y],4,'no repeated descent'
 mov dword [enemies+E_X],0
 call move_enemies
 check dword [direction],1,'left edge reverses'
 check dword [enemies+E_X],0,'no x underflow'
 check dword [enemies+E_Y],5,'left edge descent'
 ; A dead rightmost slot must not influence movement.
 mov dword [enemies+E_X],10
 mov dword [enemies+E_SIZE+E_X],10000
 call move_enemies
 check dword [enemies+E_X],11,'dead bounds ignored'
 ; Different type width (burger=7) controls the right limit.
 mov dword [enemies+E_TYPE],2
 mov dword [enemies+E_X],73
 call move_enemies
 check dword [enemies+E_X],73,'actual type width used'
 check dword [direction],-1,'wide sprite edge turn'
 ; Breach is atomic and latched, no y=23 stored for height 3.
 mov dword [enemies+E_X],0
 mov dword [enemies+E_Y],22
 call move_enemies
 check dword [enemies+E_Y],22,'breach keeps legal y'
 check dword [enemy_events],EV_BREACH,'breach event'
 call move_enemies
 check dword [enemy_events],EV_BREACH,'one latched breach'
 ; HP, invalid indices, nonpositive damage, one death and reward.
 call solo
 mov dword [enemies+E_TYPE],2
 mov dword [enemies+E_HP],2
 push dword 1
 push dword 0
 call apply_enemy_damage
 add esp,8
 check eax,0,'partial damage no kill'
 check edx,0,'partial damage no reward'
 check dword [enemies+E_HP],1,'partial HP'
 push dword 99
 push dword 0
 call apply_enemy_damage
 add esp,8
 check eax,1,'new death'
 check edx,20,'type reward'
 check dword [enemies+E_HP],0,'HP saturation'
 check dword [alive_count],0,'alive count once'
 push dword 1
 push dword 0
 call apply_enemy_damage
 add esp,8
 check edx,0,'dead target no second reward'
 check dword [alive_count],0,'no alive underflow'
 call consume_enemy_events
 check eax,EV_CLEAR,'clear event'
 call consume_enemy_events
 check eax,0,'events consumed once'
 push dword 50
 call update_enemies
 add esp,4
 check dword [enemy_events],0,'empty update no repeated clear'
 push dword 1
 push dword -1
 call apply_enemy_damage
 add esp,8
 check eax,0,'invalid negative index'
 push dword 1
 push dword MAX_ENEMIES
 call apply_enemy_damage
 add esp,8
 check eax,0,'invalid capacity index'
 call solo
 push dword -1
 push dword 0
 call apply_enemy_damage
 add esp,8
 check dword [enemies+E_HP],1,'negative damage ignored'
 ; Half-open bullet rectangle: x=right and y=bottom miss, last cell hits.
 mov byte [bullet_active],1
 mov byte [bullet_x],15
 mov byte [bullet_y],3
 call check_bullet_enemy
 check byte [bullet_active],1,'right edge excluded'
 mov byte [bullet_x],14
 mov byte [bullet_y],6
 call check_bullet_enemy
 check byte [bullet_active],1,'bottom edge excluded'
 mov byte [bullet_y],5
 call check_bullet_enemy
 check byte [bullet_active],0,'last interior cell hits'
 check dword [score],10,'collision awards once'
 call check_bullet_enemy
 check dword [score],10,'collision not double awarded'
 ; Point moving from below an enemy is caught by per-cell stepping.
 call solo
 mov byte [bullet_active],1
 mov byte [bullet_x],12
 mov byte [bullet_y],6
 call update_bullets
 check dword [alive_count],0,'player projectile path hit'
 ; Rectangle player contact: touching edge is not overlap.
 call solo
 mov dword [enemies+E_X],33
 mov dword [enemies+E_Y],22
 call check_enemy_player
 check dword [loss_pending],0,'AABB touching edge excluded'
 mov dword [enemies+E_X],34
 call check_enemy_player
 check dword [loss_pending],1,'AABB overlap hits'
 ; Pool full, boundary validation and no overwrite of active slots.
 call initialize_game
 mov ebx,MAX_SHOTS
.fill:
 push dword 5
 push dword 10
 call spawn_enemy_projectile
 add esp,8
 check eax,1,'pool allocation'
 dec ebx
 jnz .fill
 push dword 5
 push dword 30
 call spawn_enemy_projectile
 add esp,8
 check eax,0,'pool saturation'
 check dword [shots+S_X],10,'pool full no overwrite'
 call clear_projectiles
 push dword 25
 push dword 10
 call spawn_enemy_projectile
 add esp,8
 check eax,0,'out of bounds spawn rejected'
 push dword 5
 push dword -1
 call spawn_enemy_projectile
 add esp,8
 check eax,0,'negative projectile rejected'
 ; Shooter selection blocks upper slots behind living allies.
 call initialize_game
 call fire_enemy
 check dword [shots+S_X],51,'bottom hotdog shoots first'
 check dword [shots+S_Y],11,'shot starts below sprite'
 call fire_enemy
 check dword [shots+S_SIZE+S_X],65,'round robin pizza second'
 ; Single life loss when multiple sources coincide; preserve survivors HP.
 call solo
 mov dword [enemies+E_X],38
 mov dword [enemies+E_Y],22
 mov dword [enemy_events],EV_BREACH
 push dword 22
 push dword 38
 call spawn_enemy_projectile
 add esp,8
 call simulate_tick
 check byte [player_lives],2,'aggregate one life loss'
 check dword [invulnerable],1000,'invulnerability starts'
 check dword [enemies+E_Y],3,'survivor position reset'
 check dword [enemies+E_HP],1,'survivor HP preserved'
 check dword [shots+S_ACTIVE],0,'hostile shots cleared'
 check dword [enemy_events],0,'breach cleared'
 mov dword [loss_pending],1
 call resolve_game_events
 check byte [player_lives],2,'invulnerable no repeated hit'
 mov dword [invulnerable],0
 mov byte [player_lives],1
 mov dword [loss_pending],1
 call resolve_game_events
 check byte [game_state],GAME_OVER,'last life game over'
 mov dword [loss_pending],1
 call resolve_game_events
 check byte [player_lives],0,'lives never underflow'
 ; Simultaneous final kill and player hit: loss first, progression next tick.
 call solo
 mov byte [bullet_active],1
 mov byte [bullet_x],12
 mov byte [bullet_y],4
 push dword 22
 push dword 38
 call spawn_enemy_projectile
 add esp,8
 call simulate_tick
 check dword [current_wave],1,'loss defers wave transition'
 check byte [player_lives],2,'simultaneous hit loses one life'
 call simulate_tick
 check dword [current_wave],2,'deferred clear progresses'
 check dword [alive_count],10,'new formation initialized'
 ; Boss mechanics, actual width, no descending, full HP and final victory.
 mov dword [current_wave],5
 call initialize_enemies
 check dword [alive_count],1,'boss alone'
 check dword [boss_mode],1,'boss encounter'
 check dword [enemies+E_HP],20,'boss health'
 mov dword [enemies+E_X],69
 call move_enemies
 check dword [direction],-1,'boss wall reversal'
 check dword [enemies+E_Y],2,'boss no descent'
 call fire_enemy
 check dword [shots+S_X],74,'boss shot centered'
 check dword [shots+S_Y],6,'boss shot below rectangle'
 push dword 20
 push dword 0
 call apply_enemy_damage
 add esp,8
 check edx,500,'boss reward'
 check dword [enemy_events],EV_CLEAR|EV_BOSS,'boss death event'
 call simulate_tick
 check byte [game_state],VICTORY,'final boss victory'
 ; Restart clears encounter/projectile/timing state and resets player bounds.
 call initialize_game
 check dword [boss_mode],0,'restart removes boss'
 check dword [score],0,'restart resets score'
 check dword [invulnerable],0,'restart resets invulnerability'
 check dword [shooter_cursor],0,'restart resets shooter cursor'
 mov byte [player_x],0
 call move_player_left
 check byte [player_x],0,'player left bound'
 mov byte [player_x],75
 call move_player_right
 check byte [player_x],75,'player right bound'
 ; Callee-save and stack balance on a representative complete simulation tick.
 mov ebx,0x12345678
 mov esi,0x23456789
 mov edi,0x34567890
 mov ebp,esp
 call simulate_tick
 check ebx,0x12345678,'EBX preserved'
 check esi,0x23456789,'ESI preserved'
 check edi,0x34567890,'EDI preserved'
 check esp,ebp,'stack balanced'
 ; Full campaign through the collision + game-loop interfaces, including
 ; nineteen nonfatal boss hits, exact scoring, transition and final victory.
 call initialize_game
 mov dword [campaign_stage],1
.campaign:
 mov dword [campaign_slot],0
.campaign_slot:
 mov eax,[campaign_slot]
 imul eax,E_SIZE
 add eax,enemies
 cmp dword [eax+E_ACTIVE],0
 je .campaign_next
 mov edx,[eax+E_X]
 mov [bullet_x],dl
 mov edx,[eax+E_Y]
 mov [bullet_y],dl
 mov byte [bullet_active],1
 call simulate_tick
 call assert_invariants
 mov eax,[campaign_stage]
 cmp [current_wave],eax
 jne .campaign_advanced
 cmp byte [game_state],VICTORY
 je .campaign_done
 jmp .campaign_slot
.campaign_next:
 inc dword [campaign_slot]
 cmp dword [campaign_slot],MAX_ENEMIES
 jb .campaign_slot
 ; Reaching the end without advancing is a regression.
 check dword [alive_count],0,'campaign stage completed'
.campaign_advanced:
 inc dword [campaign_stage]
 mov eax,[campaign_stage]
 check eax,[current_wave],'campaign stage order'
 jmp .campaign
.campaign_done:
 check dword [current_wave],5,'campaign ends at stage five'
 check dword [score],1220,'campaign exact score'
 check byte [player_lives],3,'campaign no unintended damage'
 check dword [enemies+E_HP],0,'campaign boss defeated through collision'
 ; Actual DOS/BIOS integration: keyboard polling and VGA back-buffer output.
 call initialize_program
 call initialize_game
 mov ah,05h
 mov cx,2064h                 ; BIOS enqueue 'd'.
 int 16h
 check al,0,'BIOS keyboard enqueue'
 call read_input
 check byte [player_x],39,'original input right movement'
 mov ah,05h
 mov cx,3920h                 ; Space: fire one cleaver.
 int 16h
 call read_input
 check byte [bullet_active],1,'original input fires player shot'
 mov ah,05h
 mov cx,011Bh                 ; Escape: quit flag, no accidental simulation.
 int 16h
 call read_input
 check byte [game_state],QUIT,'original escape quit interface'
 call initialize_game
 call show_main_menu
 check word [back_buffer+(4*80+24)*2],0A46h,'Food Invaders menu title'
 call draw_game
 check word [back_buffer+(4*80+10)*2],0D28h,'cupcake drawn with color'
 check word [back_buffer+(22*80+39)*2],0B5Fh,'chef drawn in player area'
 push es
 mov ax,0B800h
 mov es,ax
 mov ax,[es:(4*80+10)*2]
 pop es
 check ax,0D28h,'VGA memory contains rendered cupcake'
 mov eax,0FFFFFFFFh
 mov edx,5
 mov bx,0F58h
 call draw_cell
 mov eax,79
 mov edx,25
 call draw_cell
 check dword [buffer_guard_before],0A5C33C5Ah,'negative x clipped'
 check dword [buffer_guard_after],05AC33CA5h,'outside bottom clipped'
 mov eax,4294967295
 mov dx,1000h
 mov bl,0Fh
 call print_number32
 check word [back_buffer+(16*80)*2],0F34h,'DWORD score first digit'
 check word [back_buffer+(16*80+9)*2],0F35h,'DWORD score last digit'
 push dword 21
 push dword 38
 call spawn_enemy_projectile
 add esp,8
 call draw_game
 check word [back_buffer+(21*80+38)*2],0C21h,'enemy projectile visible'
 mov dword [current_wave],5
 call initialize_enemies
 call draw_game
 check word [back_buffer+(3*80+34)*2],0F28h,'Ratatouille distinct sprite'
 call show_game_over
 check word [back_buffer+(7*80+30)*2],0C47h,'game over renders'
 call show_victory
 check word [back_buffer+(7*80+22)*2],0A4Bh,'victory renders'
 ; Check full register preservation around the rendering boundary.
 mov eax,0F1234567h
 mov ebx,0E2345678h
 mov ecx,0D3456789h
 mov edx,0C456789Ah
 call draw_game
 check eax,0F1234567h,'renderer preserves full EAX'
 check ebx,0E2345678h,'renderer preserves full EBX'
 check ecx,0D3456789h,'renderer preserves full ECX'
 check edx,0C456789Ah,'renderer preserves full EDX'
 ; Deterministic integration stress: 20,000 live simulation ticks.
 call initialize_game
 mov dword [stress_remaining],20000
.stress:
 cmp byte [game_state],PLAYING
 je .run
 call initialize_game
.run:
 mov eax,[stress_remaining]
 and eax,32
 jz .go_right
 mov eax,5
 jmp .tick
.go_right:
 mov eax,6
.tick:
 test eax,1
 jz .stress_right
 call move_player_left
 jmp .stress_sim
.stress_right:
 call move_player_right
.stress_sim:
 call simulate_tick
 call assert_invariants
 dec dword [stress_remaining]
 jnz .stress
 mov ecx,pass_prefix
 mov edx,pass_length
 call print_result
 mov eax,[test_count]
 call print_test_number
 mov ecx,pass_suffix
 mov edx,pass_suffix_length
 call print_result
 mov ax,4C00h
 int 21h

; Test setup helper: only cupcake slot zero at (10,3), fresh game state.
solo:
 call initialize_game
 mov edi,enemies+E_SIZE
 xor eax,eax
 mov ecx,(MAX_ENEMIES-1)*E_SIZE/4
 a32 rep stosd
 mov dword [alive_count],1
 ret

; Stress checks independently count living slots and verify geometry/HP/state.
assert_invariants:
 push ebx
 push esi
 push edi
 xor ebx,ebx
 mov esi,enemies
 mov edi,MAX_ENEMIES
.enemy:
 cmp dword [esi+E_ACTIVE],0
 je .next
 inc ebx
 mov eax,[esi+E_TYPE]
 cmp eax,5
 ja .bad
 imul eax,T_SIZE
 mov edx,[esi+E_X]
 cmp edx,LEFT
 jl .bad
 add edx,[type_table+eax+T_W]
 cmp edx,RIGHT
 jg .bad
 mov edx,[esi+E_Y]
 cmp edx,TOP
 jl .bad
 add edx,[type_table+eax+T_H]
 cmp edx,BOTTOM
 jg .bad
 cmp dword [esi+E_HP],0
 jle .bad
 mov eax,[type_table+eax+T_HP]
 cmp [esi+E_HP],eax
 jg .bad
.next:
 add esi,E_SIZE
 dec edi
 jnz .enemy
 check ebx,[alive_count],'stress alive count matches slots'
 mov esi,shots
 mov ecx,MAX_SHOTS
.shot:
 cmp dword [esi+S_ACTIVE],0
 je .snext
 mov eax,[esi+S_X]
 cmp eax,LEFT
 jl .bad
 cmp eax,RIGHT
 jge .bad
 mov eax,[esi+S_Y]
 cmp eax,TOP
 jl .bad
 cmp eax,BOTTOM
 jge .bad
.snext:
 add esi,S_SIZE
 loop .shot
 cmp byte [player_x],LEFT
 jl .bad
 cmp byte [player_x],RIGHT-5
 jg .bad
 cmp byte [player_lives],0
 jl .bad
 cmp byte [player_lives],3
 jg .bad
 inc dword [test_count]
 pop edi
 pop esi
 pop ebx
 ret
.bad:
 section .data
 .invariant_message db 'FAIL: stress geometry / health / player invariant',13,10
 .invariant_length equ $-.invariant_message
 section .text
 mov ecx,.invariant_message
 mov edx,.invariant_length
 jmp test_failed

test_failed:
 call print_result
 mov ax,4C01h
 int 21h

; ECX=DS-relative string offset, EDX=length. DOS stdout, supports redirection.
print_result:
 pushad
 mov ebx,ecx
 mov ecx,edx
 mov edx,ebx
 mov bx,1
 mov ah,40h
 int 21h
 popad
 ret

print_test_number:
 pushad
 mov esi,output_buffer+20
 mov ecx,10
 xor edi,edi
.digit:
 xor edx,edx
 div ecx
 add dl,'0'
 dec esi
 mov [esi],dl
 inc edi
 test eax,eax
 jnz .digit
 mov ecx,esi
 mov edx,edi
 call print_result
 popad
 ret

section .data
pass_prefix db 'PASS: '
pass_length equ $-pass_prefix
pass_suffix db ' assertions (DOSBox, real mode, 32-bit calculations)',13,10
pass_suffix_length equ $-pass_suffix
section .text

