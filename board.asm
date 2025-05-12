#board.asm

.data
# Ensure all data is word-aligned
.align 2
.globl board, products
board:      .space 36     # 6×6 board (byte array)
.align 2
products:   .word 1,2,3,4,5,6
           .word 7,8,9,10,12,14
           .word 15,16,18,20,21,24
           .word 25,27,28,30,32,35
           .word 36,40,42,45,48,49
           .word 54,56,63,64,72,81
.align 2
border:     .asciiz "+-----+-----+-----+-----+-----+-----+\n"
cellBorder: .asciiz "|"        # Simple border
cellEnd:    .asciiz "|\n"      # Simple end
playerMark: .asciiz "X  "
compMark:   .asciiz "O  "
space:      .asciiz " "

.text
.globl initBoard, makeMove, isValidMove, displayBoard, lookupProduct, cellFree, checkWinner, isBoardFull

# Initialize the board
initBoard:
    addi $sp, $sp, -4
    sw   $ra, 0($sp)
    
    la   $t0, board       # Get board address
    li   $t1, 36          # Board size
    li   $t2, 0           # Counter
init_loop:
    sb   $zero, ($t0)     # Initialize cell to 0
    addi $t0, $t0, 1      # Next cell
    addi $t2, $t2, 1      # Increment counter
    bne  $t2, $t1, init_loop
    
    lw   $ra, 0($sp)
    addi $sp, $sp, 4
    jr   $ra

# Check if board is full
isBoardFull:
    addi $sp, $sp, -4
    sw   $ra, 0($sp)
    
    la   $t0, board       # Get board address
    li   $t1, 36          # Board size
    li   $t2, 0           # Counter
    
check_full_cells:
    lb   $t3, ($t0)      # Load cell value
    li   $t4, 49         # ASCII '1'
    beq  $t3, $t4, next_full_cell
    li   $t4, 50         # ASCII '2'
    beq  $t3, $t4, next_full_cell
    
    # Found empty cell
    li   $v0, 0          # Return false
    j    board_full_done
    
next_full_cell:
    addi $t0, $t0, 1     # Next cell
    addi $t2, $t2, 1     # Increment counter
    bne  $t2, $t1, check_full_cells
    
    # All cells checked and filled
    li   $v0, 1          # Return true
    
board_full_done:
    lw   $ra, 0($sp)
    addi $sp, $sp, 4
    jr   $ra

# Make a move
makeMove:
    addi $sp, $sp, -16     # Save registers
    sw   $ra, 12($sp)
    sw   $s2, 8($sp)
    sw   $s1, 4($sp)
    sw   $s0, 0($sp)
    
    move $s0, $a0          # Save factor1
    move $s1, $a1          # Save factor2
    move $s2, $a2          # Save player marker
    
    # Get product location
    jal lookupProduct
    bltz $v0, make_move_fail
    
    # Verify index is valid
    move $t0, $v0          # Save product index
    li   $t1, 36
    bge  $t0, $t1, make_move_fail
    
    # Get board location
    la   $t1, board
    add  $t1, $t1, $t0
    
    # Store marker (1=X, 2=O)
    li   $t2,1
    beq  $s2,$t2,storeX   # if $s2==1 → player
    # else → computer
    li   $t3,50           # ASCII '2'
    j    doStore

storeX:
    li   $t3,49           # ASCII '1'

doStore:
    sb   $t3,($t1)
    
make_move_success:
    li   $v0, 1            # Success
    j    make_move_return
    
make_move_fail:
    li   $v0, 0            # Failure
    
make_move_return:
    lw   $s0, 0($sp)       # Restore registers
    lw   $s1, 4($sp)
    lw   $s2, 8($sp)
    lw   $ra, 12($sp)
    addi $sp, $sp, 16
    jr   $ra

# Check if move is valid
isValidMove:
    addi $sp, $sp, -8
    sw   $ra, 4($sp)
    sw   $s0, 0($sp)
    
    jal  lookupProduct
    bltz $v0, invalid_move
    move $s0, $v0
    
    # Check if cell is available
    la   $t0, board
    add  $t0, $t0, $s0
    lb   $t1, ($t0)
    li   $t2, 49           # ASCII '1'
    beq  $t1, $t2, invalid_move
    li   $t2, 50           # ASCII '2'
    beq  $t1, $t2, invalid_move
    
    li   $v0, 1            # Valid move
    j    is_valid_return
    
invalid_move:
    li   $v0, 0            # Invalid move
    
is_valid_return:
    lw   $s0, 0($sp)
    lw   $ra, 4($sp)
    addi $sp, $sp, 8
    jr   $ra


# Display the board
displayBoard:
    addi $sp, $sp, -4
    sw   $ra, 0($sp)
    
    li   $t0, 0           # Row counter
display_row:
    li   $v0, 4
    la   $a0, border
    syscall
    
    li   $t1, 0           # Column counter
display_col:
    li   $v0, 4
    la   $a0, cellBorder
    syscall
    
    # Calculate index
    li   $t2, 6
    mult $t0, $t2
    mflo $t2
    add  $t2, $t2, $t1
    
    # Get board value
    la   $t3, board
    add  $t3, $t3, $t2
    lb   $t4, ($t3)
    
    # Get product value
    la   $t3, products
    sll  $t5, $t2, 2
    add  $t3, $t3, $t5
    lw   $t5, ($t3)
    
    # Check for X or O
    li   $t6, 49          # ASCII '1'
    beq  $t4, $t6, print_x
    li   $t6, 50          # ASCII '2'
    beq  $t4, $t6, print_o
    
    # Print product number
    move $a0, $t5
    li   $t6, 10
    blt  $a0, $t6, print_single_digit
    li   $t6, 100
    blt  $a0, $t6, print_double_digit
    
    # Print triple digit number
    move $a0, $t5
    li   $v0, 1
    syscall
    li   $v0, 4
    la   $a0, space
    syscall
    j    end_cell
    
print_single_digit:
    li   $v0, 4
    la   $a0, space
    syscall
    syscall    # Two spaces before single digit
    
    move $a0, $t5
    li   $v0, 1
    syscall
    
    li   $v0, 4
    la   $a0, space
    syscall
    syscall    # Two spaces after single digit
    j    end_cell
    
print_double_digit:
    li   $v0, 4
    la   $a0, space
    syscall    # One space before double digit
    
    move $a0, $t5
    li   $v0, 1
    syscall
    
    li   $v0, 4
    la   $a0, space
    syscall
    syscall    # Two spaces after double digit
    j    end_cell
    
print_x:
    li   $v0, 4
    la   $a0, space
    syscall
    syscall    # Two spaces before X
    la   $a0, playerMark
    syscall
    j    end_cell
    
print_o:
    li   $v0, 4
    la   $a0, space
    syscall
    syscall    # Two spaces before O
    la   $a0, compMark
    syscall
    
end_cell:
    addi $t1, $t1, 1      # Next column
    li   $t6, 6
    bne  $t1, $t6, display_col
    
    li   $v0, 4
    la   $a0, cellEnd
    syscall
    
    addi $t0, $t0, 1      # Next row
    li   $t6, 6
    bne  $t0, $t6, display_row
    
    li   $v0, 4
    la   $a0, border
    syscall
    
    lw   $ra, 0($sp)
    addi $sp, $sp, 4
    jr   $ra

# Look up product in table
lookupProduct:
    mult $a0, $a1          # Calculate product
    mflo $t0               # Get product result
    
    la   $t1, products     # Get products array
    li   $t2, 0           # Index counter
    li   $t3, 36          # Array size
    
lookup_loop:
    beq  $t2, $t3, lookup_fail
    lw   $t4, ($t1)       # Load product value
    beq  $t0, $t4, lookup_found
    addi $t1, $t1, 4      # Next product
    addi $t2, $t2, 1      # Increment counter
    j    lookup_loop
    
lookup_found:
    move $v0, $t2         # Return index
    jr   $ra
    
lookup_fail:
    li   $v0, -1          # Not found
    jr   $ra

# Check if cell is free
cellFree:
    # Validate index
    li   $t0, 36
    bgeu $a0, $t0, cell_taken
    
    # Get cell value
    la   $t0, board
    add  $t0, $t0, $a0
    lb   $t1, ($t0)
    
    # Check if cell has X or O
    li   $t2, 49           # ASCII '1'
    beq  $t1, $t2, cell_taken
    li   $t2, 50           # ASCII '2'
    beq  $t1, $t2, cell_taken
    
    li   $v0, 1            # Cell is free
    jr   $ra
    
cell_taken:
    li   $v0, 0            # Cell is taken
    jr   $ra

# Check for winner
checkWinner:
    li   $t0, 0           # cell index 0..35
    li   $v0, 0           # default: no winner

check_cell:
    li   $t1, 36
    bge  $t0, $t1, cw_done
    
    # Get row and column
    li   $t2, 6
    div  $t0, $t2
    mflo $t2          # row = index / 6
    mfhi $t3          # col = index % 6
    
    # Get current cell value
    la   $t4, board
    add  $t4, $t4, $t0
    lb   $t5, ($t4)
    
    # Skip if not X or O
    li   $t6, 49          # ASCII '1' (X)
    beq  $t5, $t6, check_directions
    li   $t6, 50          # ASCII '2' (O)
    beq  $t5, $t6, check_directions
    j    skipCell

check_directions:
    # Check horizontal (need col <= 2)
    li   $t6, 2
    bgt  $t3, $t6, checkVertical
    move $t7, $t5
    
    # Check next 3 cells right
    addi $t8, $t0, 1
    la   $t9, board
    add  $t9, $t9, $t8
    lb   $t8, ($t9)
    bne  $t7, $t8, checkVertical
    
    addi $t8, $t0, 2
    la   $t9, board
    add  $t9, $t9, $t8
    lb   $t8, ($t9)
    bne  $t7, $t8, checkVertical
    
    addi $t8, $t0, 3
    la   $t9, board
    add  $t9, $t9, $t8
    lb   $t8, ($t9)
    beq  $t7, $t8, winnerFound

checkVertical:
    # Check vertical (need row <= 2)
    li   $t6, 2
    bgt  $t2, $t6, checkDiagRight
    move $t7, $t5
    
    # Check next 3 cells down
    addi $t8, $t0, 6
    la   $t9, board
    add  $t9, $t9, $t8
    lb   $t8, ($t9)
    bne  $t7, $t8, checkDiagRight
    
    addi $t8, $t0, 12
    la   $t9, board
    add  $t9, $t9, $t8
    lb   $t8, ($t9)
    bne  $t7, $t8, checkDiagRight
    
    addi $t8, $t0, 18
    la   $t9, board
    add  $t9, $t9, $t8
    lb   $t8, ($t9)
    beq  $t7, $t8, winnerFound

checkDiagRight:
    # Check diagonal right (need col <= 2 and row <= 2)
    li   $t6, 2
    bgt  $t3, $t6, checkDiagLeft
    bgt  $t2, $t6, checkDiagLeft
    move $t7, $t5
    
    # Check next 3 cells diagonally right
    addi $t8, $t0, 7
    la   $t9, board
    add  $t9, $t9, $t8
    lb   $t8, ($t9)
    bne  $t7, $t8, checkDiagLeft
    
    addi $t8, $t0, 14
    la   $t9, board
    add  $t9, $t9, $t8
    lb   $t8, ($t9)
    bne  $t7, $t8, checkDiagLeft
    
    addi $t8, $t0, 21
    la   $t9, board
    add  $t9, $t9, $t8
    lb   $t8, ($t9)
    beq  $t7, $t8, winnerFound

checkDiagLeft:
    # Check diagonal left (need col >= 3 and row <= 2)
    li   $t6, 3
    blt  $t3, $t6, skipCell
    li   $t6, 2
    bgt  $t2, $t6, skipCell
    move $t7, $t5
    
    # Check next 3 cells diagonally left
    addi $t8, $t0, 5
    la   $t9, board
    add  $t9, $t9, $t8
    lb   $t8, ($t9)
    bne  $t7, $t8, skipCell
    
    addi $t8, $t0, 10
    la   $t9, board
    add  $t9, $t9, $t8
    lb   $t8, ($t9)
    bne  $t7, $t8, skipCell
    
    addi $t8, $t0, 15
    la   $t9, board
    add  $t9, $t9, $t8
    lb   $t8, ($t9)
    beq  $t7, $t8, winnerFound

skipCell:
    addi $t0, $t0, 1
    j    check_cell

winnerFound:
    move $v0, $t5         # return the winning marker (49 for X, 50 for O)

cw_done:
    jr   $ra
