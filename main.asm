#main.asm

.data
welcome:        .asciiz "Welcome to Multiplication Four!\nYou are X, computer is O.\nFour in a row wins!\nPress Enter to start..."
newline:        .asciiz "\n"
prompt_first:   .asciiz "Choose your FIRST number (1-9): "
prompt_second:  .asciiz "Choose your SECOND number (1-9): "
prompt_keep:    .asciiz "Which factor do you want to keep? (Enter 1 for FIRST, 2 for SECOND): "
prompt_new:     .asciiz "Enter the NEW number (1-9): "
invalid:        .asciiz "Invalid input or cell taken. Try again.\n"
player_win:     .asciiz "You win!\n"
comp_win:       .asciiz "Computer wins!\n"
tie_msg:        .asciiz "It's a tie!\n"
your_turn:      .asciiz "=== Your turn (X) ===\n"
comp_turn:      .asciiz "=== Computer's turn (O) ===\n"
game_over:      .asciiz "=== Game Over ===\n"
current_first_msg:  .asciiz "Your FIRST number was: "
current_second_msg: .asciiz "Your SECOND number was: "
comp_thinking:  .asciiz "Computer Thinking...\n"
comp_first:     .asciiz "Computer's FIRST number: "
comp_second:    .asciiz "Computer's SECOND number: "

# Variables to store the current pair of factors (initialized to 0)
.align 2
.globl last_first
.globl last_second
last_first:     .word 0
last_second:    .word 0

.text
.globl main

main:
    # Welcome
    li $v0, 4
    la $a0, welcome
    syscall
    # Wait for Enter
    li $v0, 12
    syscall

    jal initBoard
    jal displayBoard
    j first_move

first_move:
    li   $v0, 4
    la   $a0, your_turn
    syscall

    # Check for full board first
    jal  isBoardFull
    bnez $v0, tie_game

    # Prompt and read first factor
    li   $v0, 4
    la   $a0, prompt_first
    syscall
    li   $v0, 5
    syscall
    move $t0, $v0         # first factor in $t0
    blt  $t0, 1, first_move_retry
    bgt  $t0, 9, first_move_retry

    # Prompt and read second factor
    li   $v0, 4
    la   $a0, prompt_second
    syscall
    li   $v0, 5
    syscall
    move $t1, $v0         # second factor in $t1
    blt  $t1, 1, first_move_retry
    bgt  $t1, 9, first_move_retry

    # Store the values before validation
    la   $t2, last_first
    sw   $t0, 0($t2)      # Store first number
    la   $t3, last_second
    sw   $t1, 0($t3)      # Store second number

    # Make the move first
    move $a0, $t0        
    move $a1, $t1        
    li   $a2, 1          # player's mark (X)
    jal  makeMove
    beqz $v0, first_move_retry  # If move failed, retry

    # Display the updated board
    jal  displayBoard

    # Computer's turn
    li   $v0, 4
    la   $a0, comp_turn
    syscall
    
    li   $v0, 4
    la   $a0, comp_thinking
    syscall
    
    jal  computer_move
    
    # Check if computer signaled a tie
    li   $t0, -1
    beq  $v0, $t0, check_comp_tie
    j    continue_comp_move

check_comp_tie:
    beq  $v1, $t0, tie_game    # If both v0 and v1 are -1, it's a tie

continue_comp_move:
    # Save computer's chosen numbers
    move $s6, $v0        # first number
    move $s7, $v1        # second number
    
    # Display first number
    li   $v0, 4
    la   $a0, comp_first
    syscall
    
    move $a0, $s6
    li   $v0, 1
    syscall
    
    li   $v0, 4
    la   $a0, newline
    syscall
    
    # Display second number
    li   $v0, 4
    la   $a0, comp_second
    syscall
    
    move $a0, $s7
    li   $v0, 1
    syscall
    
    li   $v0, 4
    la   $a0, newline
    syscall

    # Store computer's numbers as last numbers for player's next turn
    la   $t0, last_first
    sw   $s6, 0($t0)      # Store computer's first number
    la   $t0, last_second
    sw   $s7, 0($t0)      # Store computer's second number
    
    jal  displayBoard

    # Check for win
    jal  checkWinner
    li   $t2, 49      # if checkWinner returns ASCII '1'
    beq  $v0, $t2, player_won
    li   $t2, 50      # if returns ASCII '2'
    beq  $v0, $t2, comp_won

    j    game_loop

first_move_retry:
    li $v0, 4
    la $a0, invalid
    syscall
    j first_move

game_loop:
    # Check for full board first
    jal  isBoardFull
    bnez $v0, tie_game

    li   $v0, 4
    la   $a0, your_turn
    syscall

    # Display current factors with proper loading
    li   $v0, 4
    la   $a0, current_first_msg
    syscall
    
    la   $t0, last_first
    lw   $a0, 0($t0)      # Load first number
    li   $v0, 1
    syscall
    
    li   $v0, 4
    la   $a0, newline
    syscall
    
    li   $v0, 4
    la   $a0, current_second_msg
    syscall
    
    la   $t0, last_second
    lw   $a0, 0($t0)      # Load second number
    li   $v0, 1
    syscall
    
    li   $v0, 4
    la   $a0, newline
    syscall

    # Ask which factor to keep
    li   $v0, 4
    la   $a0, prompt_keep
    syscall
    li   $v0, 5
    syscall
    move $t4, $v0    # 1 means keep FIRST; 2 means keep SECOND
    li   $t5, 1
    beq  $t4, $t5, keep_first
    li   $t5, 2
    beq  $t4, $t5, keep_second
    j    game_loop  # re-prompt if invalid choice

keep_first:
    # Load current first factor (to be kept)
    la   $t2, last_first
    lw   $t7, 0($t2)

    # Prompt for new second factor
    li   $v0, 4
    la   $a0, prompt_new
    syscall
    li   $v0, 5
    syscall
    move $t6, $v0    # new factor
    blt  $t6, 1, game_loop
    bgt  $t6, 9, game_loop

    # Try to make the move before updating last_second
    move $a0, $t7    # first factor (kept)
    move $a1, $t6    # second factor (new)
    jal  isValidMove
    beqz $v0, invalid_move_player

    # Only update last_second if move is valid
    la   $t3, last_second
    sw   $t6, 0($t3)

    # Make the move
    move $a0, $t7
    move $a1, $t6
    li   $a2, 1      # player's mark
    jal  makeMove
    j    after_player_move

keep_second:
    # Load current second factor (to be kept)
    la   $t3, last_second
    lw   $t7, 0($t3)

    # Prompt for new first factor
    li   $v0, 4
    la   $a0, prompt_new
    syscall
    li   $v0, 5
    syscall
    move $t6, $v0    # new factor
    blt  $t6, 1, game_loop
    bgt  $t6, 9, game_loop

    # Try to make the move before updating last_first
    move $a0, $t6    # first factor (new)
    move $a1, $t7    # second factor (kept)
    jal  isValidMove
    beqz $v0, invalid_move_player

    # Only update last_first if move is valid
    la   $t2, last_first
    sw   $t6, 0($t2)

    # Make the move
    move $a0, $t6
    move $a1, $t7
    li   $a2, 1      # player's mark
    jal  makeMove

after_player_move:
    jal  displayBoard
    jal  checkWinner
    li   $t2, 49     # ASCII '1' for player
    beq  $v0, $t2, player_won
    li   $t2, 50     # ASCII '2' for computer
    beq  $v0, $t2, comp_won

    # Computer's turn
    li   $v0, 4
    la   $a0, comp_turn
    syscall
    
    li   $v0, 4
    la   $a0, comp_thinking
    syscall
    
    jal  computer_move
    
    # Check if computer signaled a tie
    li   $t0, -1
    beq  $v0, $t0, check_comp_tie_loop
    j    continue_comp_move_loop

check_comp_tie_loop:
    beq  $v1, $t0, tie_game    # If both v0 and v1 are -1, it's a tie

continue_comp_move_loop:
    # Save computer's chosen numbers
    move $s6, $v0        # first number
    move $s7, $v1        # second number
    
    # Display first number
    li   $v0, 4
    la   $a0, comp_first
    syscall
    
    move $a0, $s6
    li   $v0, 1
    syscall
    
    li   $v0, 4
    la   $a0, newline
    syscall
    
    # Display second number
    li   $v0, 4
    la   $a0, comp_second
    syscall
    
    move $a0, $s7
    li   $v0, 1
    syscall
    
    li   $v0, 4
    la   $a0, newline
    syscall

    # Store computer's numbers as last numbers for player's next turn
    la   $t0, last_first
    sw   $s6, 0($t0)      # Store computer's first number
    la   $t0, last_second
    sw   $s7, 0($t0)      # Store computer's second number
    
    jal  displayBoard
    jal  checkWinner
    li   $t2, 49
    beq  $v0, $t2, player_won
    li   $t2, 50
    beq  $v0, $t2, comp_won

    j    game_loop

invalid_move_player:
    li   $v0, 4
    la   $a0, invalid
    syscall
    j    game_loop

player_won:
    li   $v0, 4
    la   $a0, game_over
    syscall
    li   $v0, 4
    la   $a0, player_win
    syscall
    j    end_game

comp_won:
    li   $v0, 4
    la   $a0, game_over
    syscall
    li   $v0, 4
    la   $a0, comp_win
    syscall
    j    end_game

tie_game:
    li   $v0, 4
    la   $a0, game_over
    syscall
    li   $v0, 4
    la   $a0, tie_msg
    syscall
    j    end_game

end_game:
    li   $v0, 10
    syscall