.data
.align 2
temp_board: .space 36    # Space for temporary board state

.text
.globl computer_move

computer_move:
    addi $sp, $sp, -24
    sw   $ra, 20($sp)
    sw   $s4, 16($sp)
    sw   $s3, 12($sp)
    sw   $s2, 8($sp)
    sw   $s1, 4($sp)
    sw   $s0, 0($sp)

    # Load player's last numbers
    la   $t0, last_first
    lw   $s3, 0($t0)          # player's last first number
    la   $t0, last_second
    lw   $s4, 0($t0)          # player's last second number

    # First check if any valid moves exist
    jal  check_valid_moves_exist
    beqz $v0, signal_tie      # If no valid moves exist, signal tie immediately

    # Save current board state
    jal  save_board_state

    # First priority: Look for winning move
    move $s0, $s3             # Try keeping first number
    li   $s1, 1               # Start with 1
check_win_first:
    move $a0, $s0
    move $a1, $s1
    jal  isValidMove
    beqz $v0, next_win_first

    # Try move
    move $a0, $s0
    move $a1, $s1
    li   $a2, 2               # Computer's mark (O)
    jal  makeMove
    
    # Check if wins
    jal  checkWinner
    li   $t0, 50              # ASCII '2' (O)
    beq  $v0, $t0, winning_move_found

    # Undo move
    jal  restore_board_state

next_win_first:
    addi $s1, $s1, 1
    ble  $s1, 9, check_win_first

    # Try keeping second number for win
    move $s1, $s4             # Keep second number
    li   $s0, 1               # Start with 1
check_win_second:
    move $a0, $s0
    move $a1, $s1
    jal  isValidMove
    beqz $v0, next_win_second

    # Try move
    move $a0, $s0
    move $a1, $s1
    li   $a2, 2               # Computer's mark (O)
    jal  makeMove
    
    # Check if wins
    jal  checkWinner
    li   $t0, 50              # ASCII '2' (O)
    beq  $v0, $t0, winning_move_found

    # Undo move
    jal  restore_board_state

next_win_second:
    addi $s0, $s0, 1
    ble  $s0, 9, check_win_second

    # Second priority: Block player's winning moves
    move $s0, $s3             # Try keeping first number
    li   $s1, 1               # Start with 1
check_block_first:
    move $a0, $s0
    move $a1, $s1
    jal  isValidMove
    beqz $v0, next_block_first

    # Try player's move here
    move $a0, $s0
    move $a1, $s1
    li   $a2, 1               # Player's mark (X)
    jal  makeMove
    
    # Check if would win
    jal  checkWinner
    li   $t0, 49              # ASCII '1' (X)
    beq  $v0, $t0, blocking_move_found

    # Undo move
    jal  restore_board_state

next_block_first:
    addi $s1, $s1, 1
    ble  $s1, 9, check_block_first

    # Try keeping second number for blocking
    move $s1, $s4             # Keep second number
    li   $s0, 1               # Start with 1
check_block_second:
    move $a0, $s0
    move $a1, $s1
    jal  isValidMove
    beqz $v0, next_block_second

    # Try player's move
    move $a0, $s0
    move $a1, $s1
    li   $a2, 1               # Player's mark (X)
    jal  makeMove
    
    # Check if would win
    jal  checkWinner
    li   $t0, 49              # ASCII '1' (X)
    beq  $v0, $t0, blocking_move_found

    # Undo move
    jal  restore_board_state

next_block_second:
    addi $s0, $s0, 1
    ble  $s0, 9, check_block_second

    # Third priority: Make strategic move avoiding dangerous combinations
    move $s0, $s3             # Try keeping first number
    li   $s1, 1               # Start with 1
check_strategic_first:
    move $a0, $s0
    move $a1, $s1
    jal  isValidMove
    beqz $v0, next_strategic_first

    # Check if move is safe
    move $a0, $s0
    move $a1, $s1
    jal  is_safe_move
    beqz $v0, next_strategic_first  # Skip if not safe

    # Found safe move
    j    make_strategic_move

next_strategic_first:
    addi $s1, $s1, 1
    ble  $s1, 9, check_strategic_first

    # Try keeping second number for strategic move
    move $s1, $s4             # Keep second number
    li   $s0, 1               # Start with 1
check_strategic_second:
    move $a0, $s0
    move $a1, $s1
    jal  isValidMove
    beqz $v0, next_strategic_second

    # Check if move is safe
    move $a0, $s0
    move $a1, $s1
    jal  is_safe_move
    beqz $v0, next_strategic_second  # Skip if not safe

    # Found safe move
    j    make_strategic_move

next_strategic_second:
    addi $s0, $s0, 1
    ble  $s0, 9, check_strategic_second

    # If no safe moves, try any valid move with first number
    move $s0, $s3             # Try keeping first number
    li   $s1, 1               # Start with 1
try_any_first:
    move $a0, $s0
    move $a1, $s1
    jal  isValidMove
    bnez $v0, make_move       # Use first valid move found
    addi $s1, $s1, 1
    ble  $s1, 9, try_any_first

    # Try any move with second number
    move $s1, $s4             # Keep second number
    li   $s0, 1               # Start with 1
try_any_second:
    move $a0, $s0
    move $a1, $s1
    jal  isValidMove
    bnez $v0, make_move       # Use first valid move found
    addi $s0, $s0, 1
    ble  $s0, 9, try_any_second

signal_tie:
    # Signal tie by returning -1, -1
    li   $v0, -1
    li   $v1, -1
    j    computer_move_end

winning_move_found:
blocking_move_found:
make_strategic_move:
make_move:
    # Make the final move
    move $a0, $s0
    move $a1, $s1
    li   $a2, 2               # Computer's mark (O)
    jal  makeMove
    
    # Return move made
    move $v0, $s0
    move $v1, $s1

computer_move_end:
    lw   $s0, 0($sp)
    lw   $s1, 4($sp)
    lw   $s2, 8($sp)
    lw   $s3, 12($sp)
    lw   $s4, 16($sp)
    lw   $ra, 20($sp)
    addi $sp, $sp, 24
    jr   $ra

# Check if any valid moves exist
check_valid_moves_exist:
    addi $sp, $sp, -16
    sw   $ra, 12($sp)
    sw   $s2, 8($sp)
    sw   $s1, 4($sp)
    sw   $s0, 0($sp)

    # Try keeping first number
    move $s0, $s3             # Keep first number
    li   $s1, 1               # Start with 1
check_first_loop:
    move $a0, $s0
    move $a1, $s1
    jal  isValidMove
    bnez $v0, moves_exist     # If valid move found, return true

    addi $s1, $s1, 1
    ble  $s1, 9, check_first_loop

    # Try keeping second number
    move $s1, $s4             # Keep second number
    li   $s0, 1               # Start with 1
check_second_loop:
    move $a0, $s0
    move $a1, $s1
    jal  isValidMove
    bnez $v0, moves_exist     # If valid move found, return true

    addi $s0, $s0, 1
    ble  $s0, 9, check_second_loop

    # No valid moves found
    li   $v0, 0
    j    check_valid_moves_end

moves_exist:
    li   $v0, 1

check_valid_moves_end:
    lw   $s0, 0($sp)
    lw   $s1, 4($sp)
    lw   $s2, 8($sp)
    lw   $ra, 12($sp)
    addi $sp, $sp, 16
    jr   $ra

# Check if a move is safe
is_safe_move:
    addi $sp, $sp, -28
    sw   $ra, 24($sp)
    sw   $s4, 20($sp)
    sw   $s3, 16($sp)
    sw   $s2, 12($sp)
    sw   $s1, 8($sp)
    sw   $s0, 4($sp)
    sw   $fp, 0($sp)

    move $s0, $a0             # Save first number
    move $s1, $a1             # Save second number

    # Don't give same numbers (avoid squares)
    beq  $s0, $s1, not_safe

    # First check: Calculate immediate product
    mult $s0, $s1
    mflo $s2                  # Current product

    # Check if this immediate product exists on board
    jal  check_product_exists
    bnez $v0, not_safe       # If product exists, move is not safe

    # Second check: Check all possible combinations with numbers 1-9
    li   $s3, 1              # Counter for 1-9
check_combinations:
    beq  $s3, 10, move_safe  # If we checked all numbers and found no dangers

    # Skip if it's the same as our numbers
    beq  $s3, $s0, next_number
    beq  $s3, $s1, next_number

    # Check product with first number
    move $a0, $s0
    move $a1, $s3
    jal  check_dangerous_product
    bnez $v0, not_safe

    # Check product with second number
    move $a0, $s1
    move $a1, $s3
    jal  check_dangerous_product
    bnez $v0, not_safe

next_number:
    addi $s3, $s3, 1
    j    check_combinations

move_safe:
    li   $v0, 1
    j    is_safe_end

not_safe:
    li   $v0, 0

is_safe_end:
    lw   $fp, 0($sp)
    lw   $s0, 4($sp)
    lw   $s1, 8($sp)
    lw   $s2, 12($sp)
    lw   $s3, 16($sp)
    lw   $s4, 20($sp)
    lw   $ra, 24($sp)
    addi $sp, $sp, 28
    jr   $ra

# Check if a product would be dangerous
check_dangerous_product:
    addi $sp, $sp, -20
    sw   $ra, 16($sp)
    sw   $s2, 12($sp)
    sw   $s1, 8($sp)
    sw   $s0, 4($sp)
    sw   $fp, 0($sp)

    move $s0, $a0
    move $s1, $a1

    # Calculate product
    mult $s0, $s1
    mflo $s2

    # Check if product exists on board
    move $a0, $s2
    jal  check_product_exists
    
    # Restore and return
    lw   $fp, 0($sp)
    lw   $s0, 4($sp)
    lw   $s1, 8($sp)
    lw   $s2, 12($sp)
    lw   $ra, 16($sp)
    addi $sp, $sp, 20
    jr   $ra

# Check if a product exists on the board
check_product_exists:
    addi $sp, $sp, -8
    sw   $ra, 4($sp)
    sw   $fp, 0($sp)

    move $t0, $a0            # Product to check
    la   $t1, products       # Load products array
    li   $t2, 0             # Counter
    li   $t3, 36            # Board size

product_check_loop:
    beq  $t2, $t3, product_not_found
    lw   $t4, ($t1)         # Load product value
    beq  $t0, $t4, product_found
    addi $t1, $t1, 4        # Next product
    addi $t2, $t2, 1
    j    product_check_loop

product_found:
    li   $v0, 1
    j    check_product_end

product_not_found:
    li   $v0, 0

check_product_end:
    lw   $fp, 0($sp)
    lw   $ra, 4($sp)
    addi $sp, $sp, 8
    jr   $ra

# Save current board state
save_board_state:
    la   $t0, board           # Source
    la   $t1, temp_board      # Destination
    li   $t2, 36              # Board size

save_loop:
    lb   $t3, ($t0)
    sb   $t3, ($t1)
    addi $t0, $t0, 1
    addi $t1, $t1, 1
    addi $t2, $t2, -1
    bnez $t2, save_loop
    jr   $ra

# Restore board state
restore_board_state:
    la   $t0, temp_board      # Source
    la   $t1, board           # Destination
    li   $t2, 36              # Board size

restore_loop:
    lb   $t3, ($t0)
    sb   $t3, ($t1)
    addi $t0, $t0, 1
    addi $t1, $t1, 1
    addi $t2, $t2, -1
    bnez $t2, restore_loop
    jr   $ra