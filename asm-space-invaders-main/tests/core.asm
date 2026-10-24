section .data
%include "assets/source_art.inc"
source_enemy_art_pointers dd source_cupcake_art,source_fries_art,source_burger_art
                         dd source_hotdog_art,source_pizza_art,source_rat_art
test_art_width dd 0
test_art_type dd 0
test_spawn_min_y dd 0
test_spawn_max_y dd 0
test_count dd 0
written dd 0
output_buffer times 160 db 0
result_format db 'PASS: %u assertions (32-bit NASM simulation)',13,10,0
stress_remaining dd 0
campaign_stage dd 1
campaign_slot dd 0

section .text
TEST_PLAYER_X equ (SCREEN_WIDTH-PLAYER_WIDTH)/2
TEST_PLAYER_Y equ SCREEN_HEIGHT-PLAYER_HEIGHT-1
TEST_MENU_X equ (SCREEN_WIDTH-80)/2
TEST_MENU_Y equ (SCREEN_HEIGHT-25)/2
TEST_MENU_TITLE_X equ (SCREEN_WIDTH-title_art_width)/2
TEST_MENU_DIFFICULTY_X equ (SCREEN_WIDTH-difficulty_text_width)/2
TEST_GAMEOVER_TITLE_X equ (SCREEN_WIDTH-gameover_art_width)/2
TEST_VICTORY_TITLE_X equ (SCREEN_WIDTH-victory_text_width)/2
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
 check dword [alive_count],10,'wave enemy count'
 check byte [player_lives],3,'starting lives'
 check dword [enemies+2*E_SIZE+E_HP],2,'burger HP'
 check dword [enemies+4*E_SIZE+E_HP],2,'pizza HP'
 ; Each wave scatters the field and gives all monsters independent fire timers.
 mov dword [random_state],0x12345678
 call initialize_enemies
 call verify_enemy_scatter
 call get_test_shooter_count
 check eax,10,'stage 1 enables firing for every monster'
 check dword [attack_min_interval],2600,'stage 1 attack cadence'
 check dword [enemy_move_min_interval],120,'stage 1 movement cadence'
 check dword [enemy_shot_step_ms],80,'stage 1 hostile-shot speed'
 push dword 10
 push dword 10
 call spawn_enemy_projectile
 add esp,8
 call update_hostile_bullets
 check dword [shots+S_Y],10,'patrol projectile waits for its configured interval'
 call update_hostile_bullets
 check dword [shots+S_Y],11,'patrol projectile advances after two game ticks'
 mov dword [current_wave],2
 call initialize_enemies
 call verify_enemy_scatter
 call get_test_shooter_count
 check eax,10,'stage 2 keeps every monster armed'
 check dword [attack_min_interval],2250,'stage 2 attack cadence increases'
 check dword [enemy_move_min_interval],100,'stage 2 movement cadence increases'
 check dword [enemy_shot_step_ms],65,'stage 2 hostile shots speed up'
 push dword 10
 push dword 10
 call spawn_enemy_projectile
 add esp,8
 call update_hostile_bullets
 check dword [shots+S_Y],10,'flankers projectile waits one tick'
 call update_hostile_bullets
 check dword [shots+S_Y],11,'flankers projectile advances on the next tick'
 call draw_game
 check word [back_buffer+(SCREEN_WIDTH+7)*2],0E46h,'stage 2 profile name appears in the HUD'
 mov dword [current_wave],3
 call initialize_enemies
 call verify_enemy_scatter
 call get_test_shooter_count
 check eax,10,'stage 3 keeps every monster armed'
 check dword [attack_min_interval],1900,'stage 3 attack cadence increases'
 check dword [enemy_move_min_interval],80,'stage 3 movement cadence increases'
 check dword [enemy_shot_step_ms],50,'stage 3 hostile shots speed up'
 push dword 10
 push dword 10
 call spawn_enemy_projectile
 add esp,8
 call update_hostile_bullets
 check dword [shots+S_Y],11,'crossfire projectile advances every game tick'
 mov dword [current_wave],4
 call initialize_enemies
 call verify_enemy_scatter
 call get_test_shooter_count
 check eax,10,'stage 4 keeps every monster armed'
 check dword [attack_min_interval],1550,'stage 4 attack cadence increases'
 check dword [enemy_move_min_interval],60,'stage 4 movement cadence increases'
 check dword [enemy_shot_step_ms],35,'stage 4 hostile shots speed up'
 push dword 10
 push dword 10
 call spawn_enemy_projectile
 add esp,8
 call update_hostile_bullets
 check dword [shots+S_Y],11,'last stand projectile advances every game tick'
 call initialize_game
 ; A cleared wave must not inherit elapsed movement or firing time.
 mov dword [enemy_move_timers],0A1B2C3D4h
 mov dword [enemy_move_timers+(MAX_ENEMIES-1)*4],012345678h
 mov dword [enemy_fire_timers],0A1B2C3D4h
 mov dword [enemy_fire_timers+(MAX_ENEMIES-1)*4],012345678h
 call initialize_enemies
 check dword [enemy_move_timers],0,'new stage clears first movement timer'
 check dword [enemy_move_timers+(MAX_ENEMIES-1)*4],0,'new stage clears last movement timer'
 check dword [enemy_fire_timers],0,'new stage clears first firing timer'
 check dword [enemy_fire_timers+(MAX_ENEMIES-1)*4],0,'new stage clears last firing timer'
 call solo
 mov dword [random_state],1
 ; Isolate the randomized per-enemy timer with a deterministic fixture.
 ; Five 50 ms ticks must not move; the sixth expires the 300 ms interval.
 mov dword [enemies+E_X],10
 mov dword [enemies+E_Y],3
 mov dword [enemy_move_intervals],300
 mov dword [enemy_move_timers],0
 mov ebx,5
.wait:
 push dword 50
 call update_enemies
 add esp,4
 dec ebx
 jnz .wait
 check dword [enemies+E_X],10,'movement cooldown x'
 check dword [enemies+E_Y],3,'movement cooldown y'
 check dword [enemy_move_timers],250,'movement timer accumulates elapsed time'
 push dword 50
 call update_enemies
 add esp,4
 cmp dword [enemies+E_X],10
 jne .timed_step_moved
 mov eax,[enemies+E_Y]
 check eax,3,'timed random step changes at least one axis'
.timed_step_moved:
 check dword [enemy_move_timers],0,'movement timer consumes elapsed interval'
 ; Fixed seeds exercise independent random directions on both axes.
 call solo
 mov dword [enemy_x],20
 mov dword [enemy_y],20
 call verify_random_wandering
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
 mov dword [enemy_x],40
 mov dword [enemy_y],30
 mov byte [bullet_active],1
 mov byte [bullets_damage],1
 mov byte [bullet_x],40+ENEMY_WIDTH
 mov byte [bullet_y],30
 call check_bullet_enemy
 check byte [bullet_active],1,'right edge excluded'
 mov byte [bullet_x],40
 mov byte [bullet_y],30+ENEMY_HEIGHT
 call check_bullet_enemy
 check byte [bullet_active],1,'bottom edge excluded'
 mov byte [bullet_y],30+ENEMY_HEIGHT-1
 call check_bullet_enemy
 check byte [bullet_active],0,'last interior cell hits'
 check dword [score],10,'collision awards once'
 call check_bullet_enemy
 check dword [score],10,'collision not double awarded'
 ; A fast rectangular weapon cannot skip a target between updates.
 call solo
 mov byte [bullet_active],1
 mov byte [bullets_damage],1
 mov byte [bullet_x],12
 mov byte [bullet_y],6
 call update_bullets
 check dword [alive_count],0,'player projectile path hit'
 ; Rectangle player contact: touching edge is not overlap.
 call solo
 mov dword [enemies+E_X],TEST_PLAYER_X-ENEMY_WIDTH
 mov dword [enemies+E_Y],TEST_PLAYER_Y
 call check_enemy_player
 check dword [loss_pending],0,'AABB touching edge excluded'
 mov dword [enemies+E_X],TEST_PLAYER_X-ENEMY_WIDTH+1
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
 push dword BOTTOM
 push dword 10
 call spawn_enemy_projectile
 add esp,8
 check eax,0,'out of bounds spawn rejected'
 push dword 5
 push dword -1
 call spawn_enemy_projectile
 add esp,8
 check eax,0,'negative projectile rejected'
 ; A type that previously could not shoot can now fire from its random position.
 call initialize_game
 mov ebx,0
 call fire_enemy_slot
 check dword [shots+S_ACTIVE],1,'cupcake can fire a hostile shot'
 mov esi,shots
 call test_shot_matches_attacker
 setc al
 check al,0,'cupcake shot starts at its current position'
 call clear_projectiles
 check byte [enemy_shoot_enabled],1,'cupcake has an enabled firing timer'
 mov eax,[enemy_fire_intervals]
 cmp eax,2600
 jae .cupcake_delay_min
 check eax,2600,'cupcake receives a randomized firing delay'
.cupcake_delay_min:
 cmp eax,5001
 jb .cupcake_delay_ok
 check eax,5000,'cupcake randomized firing delay stays in range'
.cupcake_delay_ok:
 sub eax,50
 mov [enemy_fire_timers],eax
 call update_enemies
 check dword [shots+S_ACTIVE],1,'cupcake timer expiration fires a shot'
 mov esi,shots
 call test_shot_matches_attacker
 setc al
 check al,0,'timed cupcake shot matches its source monster'
 call clear_projectiles
 mov ebx,3
 call fire_enemy_slot
 check dword [shots+S_ACTIVE],1,'first randomized attacker fires'
 mov esi,shots
 call test_shot_matches_attacker
 setc al
 check al,0,'first shot starts at an active attacker'
 call clear_projectiles
 mov ebx,4
 call fire_enemy_slot
 check dword [shots+S_ACTIVE],1,'second randomized attacker fires'
 mov esi,shots
 call test_shot_matches_attacker
 setc al
 check al,0,'second shot starts at an active attacker'
 call clear_projectiles
 call fire_enemy
 check dword [shots+S_ACTIVE],1,'fire selection creates a hostile shot'
 mov esi,shots
 call test_shot_matches_attacker
 setc al
 check al,0,'random shot matches an active attacker'
 call fire_enemy
 check dword [shots+S_SIZE+S_ACTIVE],1,'second random attacker can fire'
 mov esi,shots+S_SIZE
 call test_shot_matches_attacker
 setc al
 check al,0,'second random shot matches an active attacker'
 ; Single life loss when multiple sources coincide; preserve survivors HP.
 call solo
 mov dword [enemies+E_X],TEST_PLAYER_X
 mov dword [enemies+E_Y],BOTTOM-3
 mov dword [enemy_events],EV_BREACH
 push dword TEST_PLAYER_Y
 push dword TEST_PLAYER_X
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
 ; Simultaneous final kill and player hit: aim at the top-left of the Chef's
 ; full sprite hitbox; loss is resolved before progression on the next tick.
 call solo
 mov byte [bullet_active],1
 mov byte [bullets_damage],1
 mov byte [bullet_x],12
 mov byte [bullet_y],4
 push dword TEST_PLAYER_Y+PLAYER_HITBOX_Y
 push dword TEST_PLAYER_X+PLAYER_HITBOX_X
 call spawn_enemy_projectile
 add esp,8
 call simulate_tick
 check dword [current_wave],1,'loss defers wave transition'
 check byte [player_lives],2,'simultaneous hit loses one life'
 call simulate_tick
 check dword [current_wave],2,'deferred clear progresses'
 check dword [alive_count],10,'new wave enemies initialized'
 ; Boss health, fast attacks, and final victory.
 mov dword [current_wave],5
 call initialize_enemies
 check dword [alive_count],1,'boss alone'
 check dword [boss_mode],1,'boss encounter'
 check dword [enemies+E_HP],20,'boss health'
 check dword [attack_min_interval],1000,'boss fires faster than the final regular wave'
 check dword [enemy_move_min_interval],50,'boss movement is the fastest stage profile'
 check dword [enemy_shot_step_ms],35,'boss shots use the fastest hostile-shot profile'
 mov dword [enemies+E_X],RIGHT-15
 mov dword [enemies+E_Y],TOP
 call fire_enemy
 check dword [shots+S_X],RIGHT-8,'boss shot centered'
 check dword [shots+S_Y],TOP+ENEMY_HEIGHT,'boss shot below source-size art'
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
 mov byte [player_x],SCREEN_WIDTH-PLAYER_WIDTH
 call move_player_right
 check byte [player_x],SCREEN_WIDTH-PLAYER_WIDTH,'player right bound'
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
 mov byte [bullets_damage],1
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
 check byte [player_x],TEST_PLAYER_X+PLAYER_MOVE_STEP,'original input right movement'
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
 check word [back_buffer+(MENU_TITLE_ROW*SCREEN_WIDTH+TEST_MENU_TITLE_X)*2],0A46h,'Food Invaders menu title'
 check word [back_buffer+(MENU_DIFFICULTY_ROW*SCREEN_WIDTH+TEST_MENU_DIFFICULTY_X)*2],0E44h,'menu explains selectable difficulty'
 check word [back_buffer+(MENU_ENEMY_ROW*SCREEN_WIDTH+10)*2],0D23h,'menu previews cupcake ASCII art'
 check word [back_buffer+(MENU_ENEMY_ROW*SCREEN_WIDTH+35)*2],0E23h,'menu previews fries ASCII art'
 check word [back_buffer+((MENU_ENEMY_ROW+(16-11)/2)*SCREEN_WIDTH+59)*2],0B23h,'menu previews burger ASCII art'
 check word [back_buffer+(MENU_ENEMY_ROW*SCREEN_WIDTH+87)*2],0C23h,'menu previews hotdog ASCII art'
 check word [back_buffer+(MENU_ENEMY_ROW*SCREEN_WIDTH+111)*2],0A23h,'menu previews pizza ASCII art'
 check word [back_buffer+(MENU_SHOWCASE_ROW*SCREEN_WIDTH+16)*2],0F23h,'menu previews Ratatouille ASCII art'
 check word [back_buffer+(MENU_SHOWCASE_ROW*SCREEN_WIDTH+44)*2],0B23h,'menu previews cleaver ASCII art'
 check word [back_buffer+(MENU_SHOWCASE_ROW*SCREEN_WIDTH+62)*2],0F23h,'menu previews Chef ASCII art'
 check word [back_buffer+(MENU_SHOWCASE_ROW*SCREEN_WIDTH+85)*2],0E23h,'menu previews rolling pin ASCII art'
 check word [back_buffer+((MENU_SHOWCASE_ROW-1)*SCREEN_WIDTH+109)*2],0E23h,'menu previews fireball ASCII art'
 mov ah,05h
 mov cx,0231h                 ; BIOS enqueue '1': Easy.
 int 16h
 call wait_for_menu_input
 check al,DIFFICULTY_EASY,'menu selects Easy difficulty'
 mov [difficulty_level],al
 call initialize_game
 check byte [player_lives],5,'Easy starts with five lives'
 mov ah,05h
 mov cx,0433h                 ; BIOS enqueue '3': Hard.
 int 16h
 call wait_for_result_input
 check al,1,'result screen accepts difficulty restart'
 check byte [difficulty_level],DIFFICULTY_HARD,'result screen selects Hard'
 call initialize_game
 check byte [player_lives],2,'Hard starts with two lives'
 mov byte [difficulty_level],DIFFICULTY_EASY
 mov eax,400
 call scale_difficulty_interval
 check eax,600,'Easy slows enemy timers by one half'
 mov byte [difficulty_level],DIFFICULTY_NORMAL
 mov eax,400
 call scale_difficulty_interval
 check eax,400,'Normal keeps the base enemy timer'
 mov byte [difficulty_level],DIFFICULTY_HARD
 mov eax,400
 call scale_difficulty_interval
 check eax,300,'Hard speeds enemy timers by one quarter'
 mov byte [difficulty_level],DIFFICULTY_NORMAL
 call initialize_game
 call verify_enemy_art_collection
 call solo
 mov dword [enemy_x],0
 mov dword [enemy_y],5
 mov dword [enemies+E_SX],0
 mov dword [enemies+E_SY],5
 call draw_game
 check word [back_buffer+(5*SCREEN_WIDTH+7)*2],0D23h,'exact cupcake art drawn at an arbitrary position'
 check word [back_buffer+(TEST_PLAYER_Y*SCREEN_WIDTH+TEST_PLAYER_X+2)*2],0F23h,'chef drawn in player area'
 push es
 mov ax,0B800h
 mov es,ax
 mov ax,[es:(5*SCREEN_WIDTH+7)*2]
 pop es
 check ax,0D23h,'VGA memory contains rendered cupcake artwork'
 mov byte [pickup_active],1
 mov byte [pickup_kind],POWERUP_SPEED
 mov byte [pickup_x],40
 mov byte [pickup_y],50
 call clear_screen
 call draw_pickup
 mov esi,source_fireball_art
 mov edi,back_buffer+(50*SCREEN_WIDTH+40)*2
 mov ecx,PICKUP_WIDTH
 mov ebp,PICKUP_HEIGHT
 mov bl,0Ah
 call verify_art_rows
 inc dword [test_count]
 mov eax,0FFFFFFFFh
 mov edx,5
 mov bx,0F58h
 call draw_cell
 mov eax,SCREEN_WIDTH-1
 mov edx,SCREEN_HEIGHT
 call draw_cell
 check dword [buffer_guard_before],0A5C33C5Ah,'negative x clipped'
 check dword [buffer_guard_after],05AC33CA5h,'outside bottom clipped'
 mov eax,4294967295
 mov dx,1000h
 mov bl,0Fh
 call print_number32
 check word [back_buffer+(16*SCREEN_WIDTH)*2],0F34h,'DWORD score first digit'
 check word [back_buffer+(16*SCREEN_WIDTH+9)*2],0F35h,'DWORD score last digit'
 push dword 21
 push dword TEST_PLAYER_X
 call spawn_enemy_projectile
 add esp,8
 call draw_game
 check word [back_buffer+(21*SCREEN_WIDTH+TEST_PLAYER_X)*2],0CDBh,'enemy projectile visible'
 mov dword [current_wave],5
 call initialize_enemies
 call draw_game
 mov eax,[enemies+E_Y]
 imul eax,SCREEN_WIDTH
 add eax,[enemies+E_X]
 shl eax,1
 mov dx,[back_buffer+eax]
 check dx,0F23h,'document Ratatouille art renders at its randomized position'
 call show_game_over
 check word [back_buffer+(RESULT_TITLE_ROW*SCREEN_WIDTH+TEST_GAMEOVER_TITLE_X)*2],0C47h,'game over title is centered'
 check word [back_buffer+(RESULT_ART_ROW*SCREEN_WIDTH+36)*2],0F23h,'game over previews Ratatouille art'
 check word [back_buffer+(RESULT_ART_ROW*SCREEN_WIDTH+62)*2],0F23h,'game over previews Chef art'
 check word [back_buffer+((RESULT_ART_ROW-1)*SCREEN_WIDTH+89)*2],0E23h,'game over previews fireball art'
 mov dword [score],1220
 call show_victory
 check word [back_buffer+(RESULT_TITLE_ROW*SCREEN_WIDTH+TEST_VICTORY_TITLE_X)*2],0A4Bh,'victory title is centered'
 check word [back_buffer+(RESULT_SCORE_VALUE_ROW*SCREEN_WIDTH+64)*2],0F31h,'victory score starts centered'
 check word [back_buffer+(RESULT_SCORE_VALUE_ROW*SCREEN_WIDTH+67)*2],0F30h,'victory score ends centered'
%ifdef VISUAL_TEST
 ; Optional manual capture mode: the normal self-test has already completed
 ; the full campaign simulation and verified VICTORY before reaching here.
 mov dword [score],1220
 call show_victory
 mov ah,00h
 int 16h
%endif
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
 mov eax,[stress_remaining]
 test al,63
 jnz .spacing_checked
 call assert_enemy_spacing
.spacing_checked:
 dec dword [stress_remaining]
 jnz .stress
 mov ax,3
 int 10h                     ; Return DOSBox to readable text before reporting.
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
 mov dword [enemies+E_X],10
 mov dword [enemies+E_Y],3
 mov dword [enemies+E_SX],10
 mov dword [enemies+E_SY],3
 ret

; Compare all six active enemy designs against independent document rows.
verify_enemy_art_collection:
 pushad
 mov esi,enemies
 mov ecx,MAX_ENEMIES
.clear:
 mov dword [esi+E_ACTIVE],0
 add esi,E_SIZE
 loop .clear
 mov dword [alive_count],1
 xor ebx,ebx
.art:
 mov [test_art_type],ebx
 mov dword [enemies+E_ACTIVE],1
 mov [enemies+E_TYPE],ebx
 mov dword [enemies+E_X],10
 mov dword [enemies+E_Y],20
 call clear_screen
 call draw_enemy
 mov eax,ebx
 imul eax,T_SIZE
 mov ecx,[type_table+eax+T_W]
 mov ebp,[type_table+eax+T_H]
 mov esi,[source_enemy_art_pointers+ebx*4]
 mov bl,[type_table+eax+T_COLOR]
 mov edi,back_buffer+(20*SCREEN_WIDTH+10)*2
 call verify_art_rows
 inc dword [test_count]
 mov ebx,[test_art_type]
 inc ebx
 cmp ebx,6
 jb .art
 popad
 ret

; Return the number of active attackers in EAX.
get_test_shooter_count:
 push ebx
 xor eax,eax
 xor ebx,ebx
.loop:
 cmp byte [enemy_shoot_enabled+ebx],0
 je .skip
 inc eax
.skip:
 inc ebx
 cmp ebx,MAX_ENEMIES
 jb .loop
 pop ebx
 ret

; Repeated deterministic vectors must explore both directions on both axes.
verify_random_wandering:
 pushad
 mov esi,enemies
 mov ebx,0
 mov edi,1
 xor ebp,ebp
.sample:
 mov dword [enemy_x],60
 mov dword [enemy_y],30
 mov [random_state],edi
 call random_enemy_step
 mov eax,[enemy_x]
 cmp eax,60
 jb .x_negative
 ja .x_positive
 jmp .y_check
.x_negative:
 or ebp,1
 jmp .y_check
.x_positive:
 or ebp,2
.y_check:
 mov eax,[enemy_y]
 cmp eax,30
 jb .y_negative
 ja .y_positive
 jmp .next
.y_negative:
 or ebp,4
 jmp .next
.y_positive:
 or ebp,8
.next:
 inc edi
 cmp edi,129
 jb .sample
 check ebp,15,'random wandering moves both ways on each axis'

 ; Test repeated attempts beside the Chef boundary; a valid step never crosses it.
 mov ebx,0
 mov edi,1
.safe_line:
 mov dword [enemy_x],60
 mov dword [enemy_y],ENEMY_BREACH_LINE-ENEMY_HEIGHT-1
 mov [random_state],edi
 call random_enemy_step
 mov eax,[enemy_y]
 mov edx,[enemies+E_TYPE]
 imul edx,T_SIZE
 add eax,[type_table+edx+T_H]
 cmp eax,ENEMY_BREACH_LINE
 jb .safe
 check eax,ENEMY_BREACH_LINE-1,'random movement stays above the Chef safe line'
.safe:
 inc edi
 cmp edi,33
 jb .safe_line
 popad
 ret

; Verify randomized spawn bounds, separation, and coverage for a fixed seed.
verify_enemy_scatter:
 pushad
 mov ebp,SCREEN_WIDTH
 xor edi,edi
 mov dword [test_spawn_min_y],SCREEN_HEIGHT
 mov dword [test_spawn_max_y],0
 xor ebx,ebx
.enemy:
 mov eax,ebx
 imul eax,E_SIZE
 add eax,enemies
 mov esi,eax
 check dword [esi+E_ACTIVE],1,'random spawn initializes every enemy'
 mov eax,[esi+E_X]
 mov [enemy_candidate_x],al
 mov eax,[esi+E_Y]
 mov [enemy_candidate_y],al
 call enemy_position_is_clear
 setc al
 check al,0,'random spawn keeps enemies separated'

 mov eax,[esi+E_TYPE]
 imul eax,T_SIZE
 mov edx,[esi+E_Y]
 add edx,[type_table+eax+T_H]
 cmp edx,ENEMY_BREACH_LINE
 jb .safe_y
 check edx,ENEMY_BREACH_LINE-1,'spawn stays above the Chef safety line'
.safe_y:
 mov edx,[esi+E_X]
 mov ecx,[type_table+eax+T_W]
 shr ecx,1
 add edx,ecx
 cmp edx,ebp
 jae .min_x_ready
 mov ebp,edx
.min_x_ready:
 cmp edx,edi
 jbe .max_x_ready
 mov edi,edx
.max_x_ready:
 mov edx,[esi+E_Y]
 mov ecx,[type_table+eax+T_H]
 shr ecx,1
 add edx,ecx
 cmp edx,[test_spawn_min_y]
 jae .min_y_ready
 mov [test_spawn_min_y],edx
.min_y_ready:
 cmp edx,[test_spawn_max_y]
 jbe .next
 mov [test_spawn_max_y],edx
.next:
 inc ebx
 cmp ebx,MAX_ENEMIES
 jb .enemy
 mov eax,edi
 sub eax,ebp
 cmp eax,SCREEN_WIDTH/3
 jae .wide_x
 check eax,SCREEN_WIDTH/3-1,'random spawns cover a broad part of the screen width'
.wide_x:
 mov eax,[test_spawn_max_y]
 sub eax,[test_spawn_min_y]
 cmp eax,(ENEMY_BREACH_LINE-TOP)/3
 jae .wide_y
 check eax,(ENEMY_BREACH_LINE-TOP)/3-1,'random spawns cover a broad part of the safe height'
.wide_y:
 popad
 ret

; Sample every active pair during the campaign stress loop.
assert_enemy_spacing:
 pushad
 xor ebx,ebx
.loop:
 mov eax,ebx
 imul eax,E_SIZE
 add eax,enemies
 mov esi,eax
 cmp dword [esi+E_ACTIVE],0
 je .next
 mov eax,[esi+E_X]
 mov [enemy_candidate_x],al
 mov eax,[esi+E_Y]
 mov [enemy_candidate_y],al
 call enemy_position_is_clear
 setc al
 check al,0,'roaming enemies maintain their clearance'
.next:
 inc ebx
 cmp ebx,MAX_ENEMIES
 jb .loop
 popad
 ret

; CF=0 when a shot's coordinates match an active enemy shooter.
test_shot_matches_attacker:
 pushad
 mov ebp,esi
 xor edi,edi
.enemy:
 mov eax,edi
 imul eax,E_SIZE
 add eax,enemies
 cmp dword [eax+E_ACTIVE],0
 je .next
 cmp byte [enemy_shoot_enabled+edi],0
 je .next
 mov edx,[eax+E_TYPE]
 imul edx,T_SIZE
 mov ecx,[eax+E_X]
 mov ebx,[type_table+edx+T_W]
 shr ebx,1
 add ecx,ebx
 sub ecx,HOSTILE_SHOT_WIDTH/2
 cmp ecx,[ebp+S_X]
 jne .next
 mov ecx,[eax+E_Y]
 add ecx,[type_table+edx+T_H]
 cmp ecx,[ebp+S_Y]
 je .found
.next:
 inc edi
 cmp edi,MAX_ENEMIES
 jb .enemy
 popad
 stc
 ret
.found:
 popad
 clc
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
 cmp edx,ENEMY_BREACH_LINE
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
 cmp byte [player_x],RIGHT-PLAYER_WIDTH
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
 mov ax,3
 int 10h
 call print_result
 mov ax,4C01h
 int 21h

; Compare a source ASCII sprite from DS:ESI with rendered words at ES:EDI.
; ECX/EBP are the rendered width and height; BL is the expected color.
verify_art_rows:
 pushad
 mov [test_art_width],ecx
.row:
 mov ecx,[test_art_width]
.cell:
 lodsb
 mov ah,bl
 cmp word [edi],ax
 jne .bad
 add edi,2
 dec ecx
 jnz .cell
 mov eax,[test_art_width]
 shl eax,1
 mov edx,SCREEN_WIDTH*2
 sub edx,eax
 add edi,edx
 dec ebp
 jnz .row
 popad
 ret
.bad:
 mov ecx,art_failure_text
 mov edx,art_failure_length
 jmp test_failed

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
pass_suffix db ' assertions (real mode, 32-bit calculations)',13,10
pass_suffix_length equ $-pass_suffix
art_failure_text db 'FAIL: rendered ASCII art differs from the team document',13,10
art_failure_length equ $-art_failure_text
section .text

