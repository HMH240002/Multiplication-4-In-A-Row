# Multiplication-4-In-A-Row


Table of Contents
1. Program Description
2. Technical Implementation
3. Algorithms and Techniques
4. Winning Strategy
5. User Manual
   

1. Program Description
Multiplication Four is an innovative twist on the classic Connect Four game, implemented entirely in MIPS assembly language. It challenges players to combine arithmetic and strategy: on each turn, a player selects two digits (1–9) whose product determines the target cell on a 6×6 board. The user plays as 'X' and the computer as 'O'. On the very first move, any two digits may be chosen; thereafter, each move must retain one factor from the opponent’s previous move and select a new partner digit. The objective is to align four markers in a row—horizontally, vertically, or diagonally. The game ends when either player achieves this alignment or when no further valid moves exist, resulting in a tie.


2. Technical Implementation
The project comprises three modular assembly files:
- **main.asm**: Manages the overall game loop, user I/O, and turn sequencing.
- **board.asm**: Implements the 6×6 board representation, product lookup, move validation, and display routines.
- **ai.asm**: Contains the computer's decision logic, including win detection, blocking, and strategic move selection using board-state simulations.

These modules interact via well-defined function calls and shared data (e.g., the `board` array and factor storage). System calls (syscall) are used for console I/O, while the stack is managed carefully to preserve registers across function calls.


3. Algorithms and Techniques
- Board Representation: 6×6 byte array with corresponding products table.
- Display Logic: Iterates rows/columns, prints borders, products, or markers with alignment.
- Move Validation: lookupProduct maps factors to an index; isValidMove checks occupancy.
- makeMove stores ASCII markers, maintaining board integrity.
- Game State Checks: checkWinner scans for lines; check_valid_moves_exist handles tie conditions


4. Winning Strategy
The AI employs a robust lookahead-based algorithm:
1. **Immediate Win Detection**: The AI first simulates all possible moves for itself (O); if any produces four in a row, it executes that move instantly.
2. **Immediate Blocking**: Next, it simulates the player's possible moves (X) and blocks any that would allow the player to win on their next turn.
3. **Strategic Safe Move Selection**: The AI saves the board state, simulates each candidate move, and then simulates all possible player replies (keeping either factor). If any reply leads to an immediate player win, that candidate is discarded as unsafe.
4. **Fallback Move**: If no safe strategic option is found, the AI selects the first available valid move, ensuring uninterrupted gameplay.
This multi-layered approach ensures that the AI not only reacts to immediate threats but also avoids setting up future traps for the player.


5. User Manual
   
**Setup and Execution**
1. Install the MARS MIPS simulator.
2. Place `main.asm`, `board.asm`, and `ai.asm` in the same project directory.
3. Open MARS and assemble all three files (use 'Assemble All' in project settings).
4. Run the program; the console will display a welcome message and prompt you to start.
   
**Game Rules and Controls**
- You are 'X'; the computer is 'O'.
- On the first turn, choose any two digits (1–9).
- On subsequent turns, keep one factor from the opponent’s last move and choose a new factor.
- Enter '1' to keep the first factor, '2' to keep the second, then input the new digit (1-9).
- The product of your chosen factors determines which cell will be marked.
- Win by getting four in a row; if no valid moves remain or the board is full without a winner, the game is a tie.

