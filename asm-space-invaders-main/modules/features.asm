; Catchable power-ups. State stays here, player effects stay in player.asm,
; and the renderer draws the pickup from display.asm.

; initialize_features(): clear the falling pickup for a fresh game.
initialize_features:
    mov byte [pickup_active], 0
    mov byte [pickup_kind], POWERUP_SPEED
    mov byte [pickup_x], 0
    mov byte [pickup_y], 0
    mov byte [pickup_move_timer], 0
    ret

; maybe_drop_powerup(): ESI points to an enemy just defeated.
; A 1-in-4 roll creates one falling speed, damage, or rapid-fire pickup.
; Preserves all general-purpose registers. Flags are unspecified.
maybe_drop_powerup:
    pushad
    cmp byte [game_state], PLAYING
    jne .done
    cmp byte [pickup_active], 0
    jne .done
    call next_random
    and al, 3
    jnz .done

    mov eax, POWERUP_SPEED
    mov ecx, 3
    call random_in_range
    mov [pickup_kind], al

    mov eax, [esi+E_TYPE]
    imul eax, T_SIZE
    mov eax, [type_table+eax+T_W]
    shr eax, 1
    add eax, [esi+E_X]
    sub eax, PICKUP_WIDTH/2
    test eax,eax
    jns .check_right
    xor eax,eax
.check_right:
    cmp eax, SCREEN_WIDTH-PICKUP_WIDTH
    jbe .store_x
    mov eax, SCREEN_WIDTH-PICKUP_WIDTH
.store_x:
    mov [pickup_x], al

    mov eax, [esi+E_TYPE]
    imul eax, T_SIZE
    mov eax, [type_table+eax+T_H]
    add eax, [esi+E_Y]
    cmp eax, SCREEN_HEIGHT-PICKUP_HEIGHT
    jbe .store_y
    mov eax, SCREEN_HEIGHT-PICKUP_HEIGHT
.store_y:
    mov [pickup_y], al
    mov byte [pickup_move_timer], 0
    mov byte [pickup_active], 1
.done:
    popad
    ret

; update_features(): advance and collect the current pickup once per game tick.
; The pickup falls one row every PICKUP_STEP_TICKS (200 ms).
update_features:
    pushad
    cmp byte [game_state], PLAYING
    jne .done
    cmp byte [pickup_active], 0
    je .done

    inc byte [pickup_move_timer]
    cmp byte [pickup_move_timer], PICKUP_STEP_TICKS
    jb .collision
    mov byte [pickup_move_timer], 0
    inc byte [pickup_y]
    cmp byte [pickup_y], SCREEN_HEIGHT
    jb .collision
    mov byte [pickup_active], 0
    jmp .done

.collision:
    movzx eax, byte [pickup_x]
    add eax, PICKUP_WIDTH
    movzx edx, byte [player_x]
    cmp eax, edx
    jbe .done
    movzx eax, byte [pickup_x]
    movzx edx, byte [player_x]
    add edx, PLAYER_WIDTH
    cmp eax, edx
    jae .done

    movzx eax, byte [pickup_y]
    add eax, PICKUP_HEIGHT
    movzx edx, byte [player_y]
    cmp eax, edx
    jbe .done
    movzx eax, byte [pickup_y]
    movzx edx, byte [player_y]
    add edx, PLAYER_HEIGHT
    cmp eax, edx
    jae .done

    mov al, [pickup_kind]
    mov byte [pickup_active], 0
    call activate_powerup_type
.done:
    popad
    ret
