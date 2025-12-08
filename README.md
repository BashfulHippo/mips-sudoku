# mips sudoku

a constraint-based sudoku solver and game written entirely in mips assembly. features recursive backtracking with proper stack management.

## features

- **recursive backtracking solver** - automatically solves any valid puzzle using depth-first search with backtracking
- **constraint validation** - checks row, column, and 3x3 box constraints before placing values
- **stack-based recursion** - demonstrates proper register preservation and state restoration at the assembly level
- **memory-mapped display** - real-time visual board updates at 0xFFFF0000
- **file i/o** - load puzzles from files and save game progress
- **color system** - distinguishes preset cells, player moves, and conflicts
- **hint system** - suggests valid values for empty cells

## solver algorithm

the backtracking solver works as follows:
1. find the first empty cell
2. try values 1-9, checking constraints for each
3. if valid, place value and recursively solve remaining cells
4. if stuck, backtrack by clearing the cell and trying next value
5. repeat until solved or proven unsolvable

implemented in ~120 lines of mips assembly with proper callee-saved register conventions.

## files

```
main.asm          - game loop and user input handling
sudoku_core.asm   - core validation and cell management
sudoku_extra.asm  - save/load, hints, backtracking solver
helpers.asm       - input parsing utilities
boards/           - puzzle files (easy, medium, hard, complete)
```

## running

requires [mars mips simulator](http://courses.missouristate.edu/kenvollmar/mars/)

1. open mars
2. file > open > main.asm
3. tools > bitmap display (set base address to 0xFFFF0000)
4. assemble (f3)
5. run (f5)

## controls

- enter moves as `RCV` (row 0-8, column A-I, value 1-9)
- `A` - auto-solve (backtracking)
- `R` - reset board
- `S` - save game
- `H` - get hint
- `Q` - quit

## board format

puzzles use `RCVT` format per line:
- R = row (0-8)
- C = column (A-I)
- V = value (1-9)
- T = type (P=preset, G=game)

example: `0A2P` = row 0, column A, value 2, preset cell
