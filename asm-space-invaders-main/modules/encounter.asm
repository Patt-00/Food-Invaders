; Supporting integration: life loss and stages. No args; all registers saved.
; Used by both the live game and the DOS regression harness.
simulate_tick:
 pushad
 cmp byte [game_state],PLAYING
 jne .done
 call update_player
 call update_combat_timers
 call check_collisions
 call update_bullets
 call update_enemies
 call check_collisions
 call resolve_game_events
.done:
 popad
 ret

resolve_game_events:
 pushad
 cmp byte [game_state],PLAYING
 jne .done
 cmp dword [loss_pending],0
 je .progress
 cmp dword [invulnerable],0
 jne .progress
 call player_hit             ; Original player.asm damage interface, unchanged.
 cmp byte [game_state],GAME_OVER
 je .clear
 call reset_enemy_positions
 mov dword [invulnerable],1000
.clear:
 call clear_projectiles
 jmp .done                  ; Life loss takes priority over progression.
.progress:
 cmp dword [alive_count],0
 jne .done
 call consume_enemy_events
 test eax,EV_CLEAR
 jz .done
 cmp dword [current_wave],FINAL_STAGE
 jae .victory
 inc dword [current_wave]
 call initialize_enemies
 jmp .done
.victory:
 mov byte [game_state],VICTORY
 call clear_projectiles
.done:
 popad
 ret
