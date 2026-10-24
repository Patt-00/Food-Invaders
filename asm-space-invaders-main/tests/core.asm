section .data
%include "assets/source_art.inc"
source_enemy_art_pointers dd source_cupcake_art,source_fries_art,source_burger_art
                         dd source_hotdog_art,source_pizza_art,source_rat_art
test_art_width dd 0
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
TEST_CUPCAKE_Y equ ENEMY_FRONT_TOP+(ENEMY_FRONT_BAND_HEIGHT-SOURCE_ART_HEIGHT)/2
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
 check dword [enemies+E_Y],ENEMY_FRONT_TOP+(ENEMY_FRONT_BAND_HEIGHT-SOURCE_ART_HEIGHT)/2,'front enemies fit the 3:2 viewport'
 check dword [enemies+5*E_SIZE+E_Y],ENEMY_REAR_TOP+(ENEMY_REAR_BAND_HEIGHT-SOURCE_ART_HEIGHT)/2,'rear enemies stay clear of the front band'
 ; Each wave spreads shooter types and tightens its timing profile.
 call get_test_shooter_lane_mask
 check eax,29,'stage 1 shooters cover left middle and right lanes'
 check dword [attack_min_interval],2600,'stage 1 attack cadence'
 check dword [enemy_move_min_interval],180,'stage 1 movement cadence'
 check dword [enemy_lane_drop_min_interval],4000,'stage 1 descent cadence'
 check dword [enemy_shot_step_ms],170,'stage 1 hostile-shot speed'
 mov dword [current_wave],2
 call initialize_enemies
 call get_test_shooter_lane_mask
 check eax,23,'stage 2 shooters cover left middle and right lanes'
 check dword [attack_min_interval],2250,'stage 2 attack cadence increases'
 check dword [enemy_move_min_interval],155,'stage 2 movement cadence increases'
 check dword [enemy_lane_drop_min_interval],3600,'stage 2 descent cadence increases'
 check dword [enemy_shot_step_ms],150,'stage 2 hostile shots speed up'
 check dword [enemies+2*E_SIZE+E_Y],ENEMY_FRONT_TOP+2,'stage 2 uses a V formation'
 call draw_game
 check word [back_buffer+(SCREEN_WIDTH+7)*2],0E46h,'stage 2 formation name appears in the HUD'
 mov dword [current_wave],3
 call initialize_enemies
 call get_test_shooter_lane_mask
 check eax,23,'stage 3 shooters cover left middle and right lanes'
 check dword [attack_min_interval],1900,'stage 3 attack cadence increases'
 check dword [enemy_move_min_interval],130,'stage 3 movement cadence increases'
 check dword [enemy_lane_drop_min_interval],3200,'stage 3 descent cadence increases'
 check dword [enemy_shot_step_ms],130,'stage 3 hostile shots speed up'
 check dword [enemies+E_Y],ENEMY_FRONT_TOP+3,'stage 3 uses an inverted V formation'
 mov dword [current_wave],4
 call initialize_enemies
 call get_test_shooter_lane_mask
 check eax,15,'stage 4 shooters cover left middle and right lanes'
 check dword [attack_min_interval],1550,'stage 4 attack cadence increases'
 check dword [enemy_move_min_interval],105,'stage 4 movement cadence increases'
 check dword [enemy_lane_drop_min_interval],2800,'stage 4 descent cadence increases'
 check dword [enemy_shot_step_ms],110,'stage 4 hostile shots speed up'
 check dword [enemies+E_SIZE+E_Y],ENEMY_FRONT_TOP+3,'stage 4 uses a zigzag formation'
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
 ; Isolate the randomized per-enemy timer with a deterministic fixture.
 ; Five 50 ms ticks must not move; the sixth expires the 300 ms interval.
 mov dword [enemies+E_X],10
 mov dword [enemies+E_Y],3
 mov dword [enemy_move_intervals],300
 mov dword [enemy_move_timers],0
 mov byte [enemy_target_x],11
 mov byte [enemy_target_y],4
 mov ebx,5
.wait:
 push dword 50
 call update_enemies
 add esp,4
 dec ebx
 jnz .wait
 check dword [enemies+E_X],10,'movement cooldown'
 check dword [enemies+E_Y],3,'movement y cooldown'
 check dword [enemy_move_timers],250,'movement timer accumulates elapsed time'
 push dword 50
 call update_enemies
 add esp,4
 cmp dword [enemies+E_X],11
 je .timed_x_step
 check dword [enemies+E_X],10,'timed vertical step keeps x'
 check dword [enemies+E_Y],4,'randomized timer permits vertical step'
 jmp .timed_step_done
.timed_x_step:
 check dword [enemies+E_X],11,'randomized timer permits horizontal x step'
 check dword [enemies+E_Y],3,'randomized timer permits horizontal step'
.timed_step_done:
 check dword [enemy_move_timers],0,'movement timer consumes elapsed interval'
 ; Fixed seeds exercise independent horizontal and vertical target movement.
 call solo
 mov dword [enemy_x],20
 mov dword [enemy_y],20
 mov byte [enemy_target_x],40
 mov byte [enemy_target_y],30
 mov dword [enemy_move_intervals],50
 mov dword [enemy_move_timers],0
 mov dword [random_state],1
 call update_enemies
 cmp dword [enemy_x],20
 ja .random_horizontal_moved
 check dword [enemy_x],21,'random movement selects horizontal axis'
.random_horizontal_moved:
 mov eax,[enemy_x]
 cmp eax,23
 jbe .random_horizontal_in_range
 check eax,23,'horizontal random step stays within wave one limit'
.random_horizontal_in_range:
 check dword [enemy_y],20,'horizontal movement preserves the other axis'
 call solo
 mov dword [enemy_x],20
 mov dword [enemy_y],20
 mov byte [enemy_target_x],40
 mov byte [enemy_target_y],30
 mov dword [enemy_move_intervals],50
 mov dword [enemy_move_timers],0
 mov dword [random_state],2
 call update_enemies
 check dword [enemy_x],20,'vertical movement preserves the other axis'
 mov eax,[enemy_y]
 cmp eax,20
 ja .random_vertical_moved
 check eax,21,'random movement selects vertical axis'
.random_vertical_moved:
 cmp eax,22
 jbe .random_vertical_in_range
 check eax,22,'vertical random step stays within wave one limit'
.random_vertical_in_range:
 ; Both edges, and no repeated descent on the following horizontal tick.
 call solo
 mov dword [enemies+E_X],RIGHT-ENEMY_WIDTH
 mov dword [enemies+E_Y],3
 call move_enemies
 check dword [direction],-1,'right edge reverses'
 check dword [enemies+E_X],RIGHT-ENEMY_WIDTH,'edge tick no horizontal step'
 check dword [enemies+E_Y],4,'edge descent once'
 call move_enemies
 check dword [enemies+E_X],RIGHT-ENEMY_WIDTH-1,'next tick moves away'
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
 ; The burger's own source width controls its right limit.
 mov dword [enemies+E_TYPE],2
 mov dword [enemies+E_X],RIGHT-14
 call move_enemies
 check dword [enemies+E_X],RIGHT-14,'actual type width used'
 check dword [direction],-1,'wide sprite edge turn'
 ; Breach is atomic and latched for the full-height source artwork.
 mov dword [enemies+E_TYPE],0
 mov dword [enemies+E_X],0
 mov dword [enemies+E_Y],BOTTOM-ENEMY_HEIGHT
 call move_enemies
 check dword [enemies+E_Y],BOTTOM-ENEMY_HEIGHT,'breach keeps legal y'
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
 ; Randomized shooter selection blocks upper slots behind living allies.
 call initialize_game
 mov ebx,5
 call fire_enemy_slot
 check dword [shots+S_X],13,'stage 1 hotdog shoots from the left lane'
 call clear_projectiles
 mov ebx,7
 call fire_enemy_slot
 check dword [shots+S_X],65,'stage 1 pizza shoots from the middle lane'
 call clear_projectiles
 call fire_enemy
 check dword [shots+S_ACTIVE],1,'fire selection creates a hostile shot'
 mov eax,[shots+S_X]
 cmp eax,13
 je .first_bottom_shooter_ok
 cmp eax,65
 jne .first_check_failure
.first_bottom_shooter_ok:
 inc dword [test_count]
 jmp .first_shooter_done
.first_check_failure:
 check eax,13,'first random shooter is an unblocked bottom enemy'
.first_shooter_done:
 mov eax,ENEMY_REAR_TOP+((ENEMY_REAR_BAND_HEIGHT-SOURCE_ART_HEIGHT)/2)+SOURCE_ART_HEIGHT
 check dword [shots+S_Y],eax,'shot starts below full-size source sprite'
 call fire_enemy
 mov eax,[shots+S_SIZE+S_X]
 cmp eax,13
 je .second_bottom_shooter_ok
 cmp eax,65
 jne .second_check_failure
.second_bottom_shooter_ok:
 inc dword [test_count]
 jmp .second_shooter_done
.second_check_failure:
 check eax,13,'second random shooter is an unblocked bottom enemy'
.second_shooter_done:
 mov eax,ENEMY_REAR_TOP+((ENEMY_REAR_BAND_HEIGHT-SOURCE_ART_HEIGHT)/2)+SOURCE_ART_HEIGHT
 check dword [shots+S_SIZE+S_Y],eax,'second bottom shot starts below full-size source sprite'
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
 check dword [alive_count],10,'new formation initialized'
 ; Boss mechanics, actual width, no descending, full HP and final victory.
 mov dword [current_wave],5
 call initialize_enemies
 check dword [alive_count],1,'boss alone'
 check dword [boss_mode],1,'boss encounter'
 check dword [enemies+E_HP],20,'boss health'
 check dword [attack_min_interval],1200,'boss fires faster than the final regular wave'
 check dword [enemy_move_min_interval],90,'boss movement is the fastest stage profile'
 check dword [enemy_shot_step_ms],90,'boss shots use the fastest hostile-shot profile'
 mov dword [enemies+E_X],RIGHT-15
 call move_enemies
 check dword [direction],-1,'boss wall reversal'
 check dword [enemies+E_Y],TOP,'boss no descent'
 call fire_enemy
 check dword [shots+S_X],RIGHT-9,'boss shot centered'
 check dword [shots+S_Y],TOP+ENEMY_HEIGHT,'boss shot below full-size art'
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
 call initialize_game
 call draw_game
 check word [back_buffer+(TEST_CUPCAKE_Y*SCREEN_WIDTH+10)*2],0D23h,'full-size cupcake art drawn with color'
 check word [back_buffer+(TEST_PLAYER_Y*SCREEN_WIDTH+TEST_PLAYER_X+2)*2],0F23h,'chef drawn in player area'
 push es
 mov ax,0B800h
 mov es,ax
 mov ax,[es:(TEST_CUPCAKE_Y*SCREEN_WIDTH+10)*2]
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
 check word [back_buffer+(TOP*SCREEN_WIDTH+34)*2],0F23h,'full-size Ratatouille art renders'
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
 inc ebx
 cmp ebx,6
 jb .art
 popad
 ret

; Return one bit per lane containing an active shooter in the current wave.
get_test_shooter_lane_mask:
 push ebx
 push ecx
 push edx
 push esi
 push edi
 push ebp
 xor ebp,ebp
 xor edi,edi
.loop:
 mov eax,edi
 imul eax,E_SIZE
 add eax,enemies
 mov esi,eax
 mov eax,[esi+E_TYPE]
 imul eax,T_SIZE
 cmp dword [type_table+eax+T_SHOOT],0
 je .next
 mov eax,edi
 xor edx,edx
 mov ecx,ENEMY_LANE_COUNT
 div ecx
 mov ebx,1
 mov cl,dl
 shl ebx,cl
 or ebp,ebx
.next:
 inc edi
 cmp edi,MAX_ENEMIES
 jb .loop
 mov eax,ebp
 pop ebp
 pop edi
 pop esi
 pop edx
 pop ecx
 pop ebx
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

; Compare ECX by EBP cells from DS:ESI with rendered words at ES:EDI.
; BL is the expected color. A mismatch names the complete-art check.
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

