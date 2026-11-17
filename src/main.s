
# Two-player Pong for RARS 1.6 Bitmap Display (64 x 32, 4 bytes/pixel).
# Keyboard input uses the Keyboard and Display MMIO receiver at 0xffff0000.
.text
.globl main

main:
    li s0, 0x10010000       # Bitmap Display base address
    li s1, 12                # Left paddle top (8 cells high, centred)
    li s2, 12                # Right paddle top (centred)
    li s3, 31                # Ball column
    li s4, 15                # Ball row
    li s5, 1                 # Horizontal velocity: +1 right, -1 left
    li s6, 1                 # Vertical velocity: +1 down, -1 up
    li s7, 0                 # Left score
    li s8, 0                 # Right score
    li s9, 0                 # Game state: 0 ready, 1 playing, 2 paused
    li s10, 31               # Previous ball column
    li s11, 15               # Previous ball row
    li t0, 1
    la t1, redraw_needed
    sw t0, 0(t1)
    la t1, ball_speed
    sw t0, 0(t1)

game_loop:
    jal ra, read_keyboard
    la t0, redraw_needed
    lw t1, 0(t0)
    beqz t1, check_playing
    jal ra, draw_frame
    la t0, redraw_needed    # draw_frame reuses temporary registers
    sw zero, 0(t0)
    j frame_delay
check_playing:
    li t0, 1
    bne s9, t0, frame_delay  # Ball/paddles freeze until started or while paused
    jal ra, move_paddles
    jal ra, move_ball
    jal ra, draw_dynamic_frame

    # First player to five points wins.
    li t0, 5
    bge s7, t0, left_wins
    bge s8, t0, right_wins

frame_delay:
    # Speed tiers shorten the delay modestly without skipping collision cells.
    la t1, ball_speed
    lw t1, 0(t1)
    li t0, 2
    beq t1, t0, medium_frame_delay
    li t0, 3
    beq t1, t0, fast_frame_delay
    li t0, 16000
    j frame_delay_ready
medium_frame_delay:
    li t0, 14500
    j frame_delay_ready
fast_frame_delay:
    li t0, 13000
frame_delay_ready:
delay_loop:
    addi t0, t0, -1
    bnez t0, delay_loop
    j game_loop

read_keyboard:
    li t0, 0xffff0000       # Receiver control; bit 0 means character ready
    lw t1, 0(t0)
    andi t1, t1, 1
    beqz t1, keyboard_done
    li t0, 0xffff0004       # Receiver data
    lw t2, 0(t0)
    li t3, 32               # Space starts from the ready screen
    beq t2, t3, start_game
    li t3, 112              # p
    beq t2, t3, toggle_pause
    li t3, 80               # P
    beq t2, t3, toggle_pause
    li t3, 119              # w
    beq t2, t3, left_up
    li t3, 87               # W
    beq t2, t3, left_up
    li t3, 115              # s
    beq t2, t3, left_down
    li t3, 83               # S
    beq t2, t3, left_down
    li t3, 105              # i
    beq t2, t3, right_up
    li t3, 73               # I
    beq t2, t3, right_up
    li t3, 107              # k
    beq t2, t3, right_down
    li t3, 75               # K
    beq t2, t3, right_down
keyboard_done:
    jalr zero, 0(ra)
left_up:
    li t0, 1
    bne s9, t0, keyboard_done
    addi s1, s1, -1
    j keyboard_done
left_down:
    li t0, 1
    bne s9, t0, keyboard_done
    addi s1, s1, 1
    j keyboard_done
right_up:
    li t0, 1
    bne s9, t0, keyboard_done
    addi s2, s2, -1
    j keyboard_done
right_down:
    li t0, 1
    bne s9, t0, keyboard_done
    addi s2, s2, 1
    j keyboard_done
start_game:
    li t0, 3
    beq s9, t0, start_game_after_win
    li t0, 4
    beq s9, t0, start_game_after_win
    li s9, 1
    j request_redraw
start_game_after_win:
    addi sp, sp, -4
    sw ra, 0(sp)
    jal ra, reset_match
    lw ra, 0(sp)
    addi sp, sp, 4
    li s9, 1
    j request_redraw
request_redraw:
    li t0, 1
    la t1, redraw_needed
    sw t0, 0(t1)
    j keyboard_done
toggle_pause:
    beqz s9, keyboard_done  # P does not skip the initial start screen
    li t0, 1
    beq s9, t0, pause_game
    li t0, 2
    beq s9, t0, resume_game
    li t0, 3
    beq s9, t0, keyboard_done
    li t0, 4
    beq s9, t0, keyboard_done
    li s9, 1
    j request_redraw
resume_game:
    li s9, 1
    j request_redraw
pause_game:
    li s9, 2
    j request_redraw
//Person 2
increase_ball_speed:
    # Only advance a tier every second point; cap the increase at two tiers.
    add t0, s7, s8
    andi t0, t0, 1
    bnez t0, speed_scale_done
    la t0, ball_speed
    lw t1, 0(t0)
    li t2, 3
    bge t1, t2, speed_scale_done
    addi t1, t1, 1
    sw t1, 0(t0)
speed_scale_done:
    jalr zero, 0(ra)

reset_match:
    li s1, 12
    li s2, 12
    li s3, 31
    li s4, 15
    li s5, 1
    li s6, 1
    li s7, 0
    li s8, 0
    li s9, 0
    li t0, 1
    la t1, ball_speed
    sw t0, 0(t1)
    li t0, 1
    la t1, redraw_needed
    sw t0, 0(t1)
    jalr zero, 0(ra)
    
move_paddles:
    bgez s1, left_top_ok
    li s1, 0
left_top_ok:
    li t0, 24                # 32 rows - 8 paddle cells
    ble s1, t0, right_top_check
    mv s1, t0
right_top_check:
    bgez s2, right_top_ok
    li s2, 0
right_top_ok:
    li t0, 24
    ble s2, t0, paddles_done
    mv s2, t0
paddles_done:
    jalr zero, 0(ra)

move_ball:
    addi sp, sp, -4
    sw ra, 0(sp)
    add s3, s3, s5
    add s4, s4, s6

    # Bounce from the top and bottom rows.
    bltz s4, bounce_top
    li t0, 31
    bgt s4, t0, bounce_bottom
    j check_paddle_collision
bounce_top:
    li s4, 0
    li s6, 1
    j check_paddle_collision
bounce_bottom:
    li s4, 31
    li s6, -1

check_paddle_collision:
    # Ball moving left reaches the left paddle column (2).
    li t0, 2
    bne s3, t0, check_right_paddle
    bltz s5, left_collision_test
    j check_right_paddle
left_collision_test:
    blt s4, s1, score_right
    addi t1, s1, 8
    bge s4, t1, score_right
    li s5, 1
    j ball_done

check_right_paddle:
    li t0, 61
    bne s3, t0, check_goal
    bgez s5, right_collision_test
    j check_goal
right_collision_test:
    blt s4, s2, score_left
    addi t1, s2, 8
    bge s4, t1, score_left
    li s5, -1
    j ball_done

check_goal:
    bltz s3, score_right
    li t0, 63
    bgt s3, t0, score_left
    j ball_done

score_left:
    addi s7, s7, 1
    j score_reset
score_right:
    addi s8, s8, 1
score_reset:
    jal ra, increase_ball_speed
    li t0, 1
    la t1, redraw_needed
    sw t0, 0(t1)
reset_ball:
    li s3, 31
    li s4, 15
    neg s5, s5
    neg s6, s6
ball_done:
    lw ra, 0(sp)
    addi sp, sp, 4
    jalr zero, 0(ra)
//person 3
draw_frame:
    addi sp, sp, -4
    sw ra, 0(sp)
    # Fill all 2048 cells light green to prevent trails and set the court background.
    mv t0, s0
    li t1, 2048
    li t2, 0x0090ee90       # Light green (RGB 144, 238, 144)
clear_loop:
    sw t2, 0(t0)
    addi t0, t0, 4
    addi t1, t1, -1
    bnez t1, clear_loop

    # Black dashed center line at column 32: two cells on, two cells off.
    addi t0, s0, 128        # 32 columns * 4 bytes per cell
    li t1, 32
    li t2, 256              # 64 columns * 4 bytes per row
    li t3, 0
divider_loop:
    li t4, 2
    bge t3, t4, divider_skip
    sw zero, 0(t0)
divider_skip:
    add t0, t0, t2
    addi t1, t1, -1
    addi t3, t3, 1
    li t4, 4
    blt t3, t4, divider_continue
    li t3, 0
divider_continue:
    bnez t1, divider_loop

    # Dark-blue paddles at columns 2 and 61.
    li a0, 2
    mv a1, s1
    jal ra, draw_paddle
    li a0, 61
    mv a1, s2
    jal ra, draw_paddle

    # Bright-orange ball.
    li t0, 64
    mul t1, s4, t0
    add t1, t1, s3
    slli t1, t1, 2
    add t1, s0, t1
    li t2, 0x00ff8c00       # Bright orange (RGB 255, 140, 0)
    sw t2, 0(t1)
    # Draw last so the scoreboard survives the frame clear and overlays the ball.
    jal ra, draw_scoreboard
    jal ra, draw_status
    mv s10, s3
    mv s11, s4
    la t0, previous_paddle_tops
    sw s1, 0(t0)
    sw s2, 4(t0)
    lw ra, 0(sp)
    addi sp, sp, 4
    jalr zero, 0(ra)

# Redraw only moving objects during normal play to reduce display jitter.
draw_dynamic_frame:
    addi sp, sp, -4
    sw ra, 0(sp)

    # Erase the old ball, restoring a divider dash when it was on column 32.
    li t0, 64
    mul t1, s11, t0
    add t1, t1, s10
    slli t1, t1, 2
    add t1, s0, t1
    li t2, 0x0090ee90       # Light green background
    li t3, 32
    bne s10, t3, erase_old_ball
    andi t3, s11, 3
    li t4, 2
    bge t3, t4, erase_old_ball
    li t2, 0                # Restore a black divider dash
erase_old_ball:
    sw t2, 0(t1)

    # Erase both old paddles, then draw their current positions.
    la t0, previous_paddle_tops
    lw a1, 0(t0)
    li a0, 2
    jal ra, erase_paddle
    la t0, previous_paddle_tops
    lw a1, 4(t0)
    li a0, 61
    jal ra, erase_paddle
    li a0, 2
    mv a1, s1
    jal ra, draw_paddle
    li a0, 61
    mv a1, s2
    jal ra, draw_paddle

    # Draw the ball at its current position.
    li t0, 64
    mul t1, s4, t0
    add t1, t1, s3
    slli t1, t1, 2
    add t1, s0, t1
    li t2, 0x00ff8c00
    sw t2, 0(t1)
    mv s10, s3
    mv s11, s4
    la t0, previous_paddle_tops
    sw s1, 0(t0)
    sw s2, 4(t0)
    lw ra, 0(sp)
    addi sp, sp, 4
    jalr zero, 0(ra)

# a0 = column, a1 = top row; erase eight cells with the court background.
erase_paddle:
    li t0, 8
    li t2, 64
    li t3, 0x0090ee90
erase_paddle_loop:
    mul t1, a1, t2
    add t1, t1, a0
    slli t1, t1, 2
    add t1, s0, t1
    sw t3, 0(t1)
    addi a1, a1, 1
    addi t0, t0, -1
    bnez t0, erase_paddle_loop
    jalr zero, 0(ra)

# a0 = column, a1 = top row; leaf routine draws eight dark-blue cells.
draw_paddle:
    li t0, 8
    li t2, 64
    li t3, 0x0000008b       # Dark blue (RGB 0, 0, 139)
paddle_loop:
    mul t1, a1, t2
    add t1, t1, a0
    slli t1, t1, 2
    add t1, s0, t1
    sw t3, 0(t1)
    addi a1, a1, 1
    addi t0, t0, -1
    bnez t0, paddle_loop
    jalr zero, 0(ra)

# Draw P1 <score>   P2 <score> in a black 5x7 pixel font at the top.
draw_scoreboard:
    addi sp, sp, -4
    sw ra, 0(sp)
    li a0, 2
    li a1, 1
    li a2, 0                 # P
    jal ra, draw_glyph
    li a0, 8
    li a1, 1
    li a2, 1                 # 1
    jal ra, draw_glyph
    li a0, 20
    li a1, 1
    addi a2, s7, 3            # Digit glyphs start at index 3
    jal ra, draw_glyph
    li a0, 34
    li a1, 1
    li a2, 0                 # P
    jal ra, draw_glyph
    li a0, 40
    li a1, 1
    li a2, 2                 # 2
    jal ra, draw_glyph
    li a0, 52
    li a1, 1
    addi a2, s8, 3
    jal ra, draw_glyph
    lw ra, 0(sp)
    addi sp, sp, 4
    jalr zero, 0(ra)

# a0 = column, a1 = top row, a2 = glyph index; draw a 5x7 black glyph.
draw_glyph:
    li t0, 7
    mul t0, a2, t0
    la t1, glyph_rows
    add t0, t0, t1
    li t1, 0
glyph_row:
    lbu t2, 0(t0)
    addi t0, t0, 1
    li t3, 0
    li t4, 16
glyph_column:
    and t5, t2, t4
    beqz t5, glyph_skip_pixel
    li t5, 64
    mul t5, a1, t5
    add t5, t5, a0
    add t5, t5, t3
    slli t5, t5, 2
    add t5, s0, t5
    li t6, 0x00000000
    sw t6, 0(t5)
glyph_skip_pixel:
    addi t3, t3, 1
    srli t4, t4, 1
    li t5, 5
    blt t3, t5, glyph_column
    addi a1, a1, 1
    addi t1, t1, 1
    li t5, 7
    blt t1, t5, glyph_row
    jalr zero, 0(ra)

# Show start instructions before play and a pause label while paused.
draw_status:
    beqz s9, show_ready
    li t0, 2
    beq s9, t0, show_paused
    li t0, 3
    beq s9, t0, show_left_win
    li t0, 4
    beq s9, t0, show_right_win
    jalr zero, 0(ra)
show_ready:
    addi sp, sp, -4
    sw ra, 0(sp)
    li a0, 17
    li a1, 9
    la a2, press_word
    li a3, 5
    jal ra, draw_word
    li a0, 17
    li a1, 16
    la a2, start_word
    li a3, 5
    jal ra, draw_word
    li a0, 17
    li a1, 23
    la a2, space_word
    li a3, 5
    jal ra, draw_word
    lw ra, 0(sp)
    addi sp, sp, 4
    jalr zero, 0(ra)
show_paused:
    addi sp, sp, -4
    sw ra, 0(sp)
    li a0, 17
    li a1, 14
    la a2, pause_word
    li a3, 5
    jal ra, draw_word
    lw ra, 0(sp)
    addi sp, sp, 4
    jalr zero, 0(ra)
show_left_win:
    addi sp, sp, -4
    sw ra, 0(sp)
    li a0, 16
    li a1, 14
    la a2, left_banner_prefix
    li a3, 2
    jal ra, draw_word
    li a0, 31
    li a1, 14
    la a2, win_word
    li a3, 4
    jal ra, draw_word
    li a0, 1
    li a1, 23
    la a2, press_word
    li a3, 5
    jal ra, draw_word
    li a0, 33
    li a1, 23
    la a2, space_word
    li a3, 5
    jal ra, draw_word
    lw ra, 0(sp)
    addi sp, sp, 4
    jalr zero, 0(ra)
show_right_win:
    addi sp, sp, -4
    sw ra, 0(sp)
    li a0, 16
    li a1, 14
    la a2, right_banner_prefix
    li a3, 2
    jal ra, draw_word
    li a0, 31
    li a1, 14
    la a2, win_word
    li a3, 4
    jal ra, draw_word
    li a0, 1
    li a1, 23
    la a2, press_word
    li a3, 5
    jal ra, draw_word
    li a0, 33
    li a1, 23
    la a2, space_word
    li a3, 5
    jal ra, draw_word
    lw ra, 0(sp)
    addi sp, sp, 4
    jalr zero, 0(ra)

# a0 = x, a1 = y, a2 = glyph-index array, a3 = number of characters.
draw_word:
    addi sp, sp, -20
    sw a0, 0(sp)
    sw a1, 4(sp)
    sw a2, 8(sp)
    sw a3, 12(sp)
    sw ra, 16(sp)
word_loop:
    lw t0, 12(sp)
    beqz t0, word_done
    lw a0, 0(sp)
    lw a1, 4(sp)
    lw t1, 8(sp)
    lbu a2, 0(t1)
    jal ra, draw_glyph
    lw t0, 0(sp)
    addi t0, t0, 6
    sw t0, 0(sp)
    lw t0, 8(sp)
    addi t0, t0, 1
    sw t0, 8(sp)
    lw t0, 12(sp)
    addi t0, t0, -1
    sw t0, 12(sp)
    j word_loop
word_done:
    lw ra, 16(sp)
    addi sp, sp, 20
    jalr zero, 0(ra)

left_wins:
    li s9, 3
    li t0, 1
    la t1, redraw_needed
    sw t0, 0(t1)
    j game_loop
right_wins:
    li s9, 4
    li t0, 1
    la t1, redraw_needed
    sw t0, 0(t1)
    j game_loop

.data 0x10012000          # After 64 * 32 * 4 framebuffer bytes
.align 2
redraw_needed:         .word 0
ball_speed:            .word 1
previous_paddle_tops:  .word 12, 12
# Seven 5-bit rows per glyph: P, 1, 2, 0, 1, 2, 3, 4, 5, S, T, A, R, C, E, U.
glyph_rows:
    .byte 30, 17, 17, 30, 16, 16, 16  # P
    .byte 31, 4, 4, 4, 4, 4, 14      # 1: flat top cap, straight stem, base
    .byte 30, 1, 1, 2, 4, 8, 31       # 2
    .byte 14, 17, 19, 21, 25, 17, 14  # 0
    .byte 31, 4, 4, 4, 4, 4, 14      # 1: flat top cap, straight stem, base
    .byte 30, 1, 1, 2, 4, 8, 31       # 2
    .byte 30, 1, 1, 14, 1, 1, 30      # 3
    .byte 2, 6, 10, 18, 31, 2, 2      # 4
    .byte 31, 16, 16, 30, 1, 1, 30    # 5
    .byte 15, 16, 16, 14, 1, 1, 30    # S
    .byte 31, 4, 4, 4, 4, 4, 4        # T
    .byte 14, 17, 17, 31, 17, 17, 17  # A
    .byte 30, 17, 17, 30, 20, 18, 17  # R
    .byte 14, 17, 16, 16, 16, 17, 14  # C
    .byte 31, 16, 16, 30, 16, 16, 31  # E
    .byte 17, 17, 17, 17, 17, 17, 14  # U
    .byte 17, 17, 17, 21, 21, 21, 10  # W
    .byte 31, 4, 4, 4, 4, 4, 31       # I
    .byte 17, 25, 21, 19, 17, 17, 17  # N
press_word: .byte 0, 12, 14, 9, 9  # PRESS
start_word: .byte 9, 10, 11, 12, 10 # START
space_word: .byte 9, 0, 11, 13, 14 # SPACE
pause_word: .byte 0, 11, 15, 9, 14 # PAUSE
left_banner_prefix: .byte 0, 1      # P1
right_banner_prefix: .byte 0, 2     # P2
win_word: .byte 16, 17, 18, 9      # WINS
left_win_text:  .asciz "Left player wins!\n"
right_win_text: .asciz "Right player wins!\n"
