.include "sudoku_core.asm"
.include "sudoku_extra.asm"
.include "helpers.asm"
.data
welcome: .asciiz "===============================\nWelcome to Sudoku\n===============================\n"

fg_preset_str: .asciiz "\nEnter a number [0-15] for the preset cell foreground color: "
bg_preset_str: .asciiz "\nEnter a number [0-15] for the preset cell background color: "
bg_error_str: .asciiz "\nEnter a number [0-15] for the error background color: "
enter_move_str: .asciiz "\nEnter move (RCV), 'R' reset, 'S' save, 'H' hint, 'A' auto-solve, 'Q' quit: "
solve_start_str: .asciiz "\nSolving puzzle...\n"
solve_done_str: .asciiz "Solved!\n"
solve_fail_str: .asciiz "No solution exists.\n"
invalid_color_str: .asciiz "\nInvalid color! Try again.\n"
invalid_colorSet_str: .asciiz "\nColor combinations can't be used! Try again.\n"
main_filename_str: .asciiz "\nLoad Game - Enter the name of the file (max 47 chars): "
main_filename_error_str: .asciiz "Error with loading board from file! Try again\n"
main_save_str: .asciiz "\nSave Game - Enter the name of the file (max 47 chars): "
main_save_game_str: .asciiz "\nGame Saved!\n"
main_save_error_str: .asciiz "Error with saving board to file!\n"
main_hint_str: .asciiz "Enter board position for hint (RC): "
main_hint_response: .asciiz "The following values can be placed: "
game_won_str: .asciiz "\nYou Won!!!!\nGAME OVER\n"
main_game_error_str: .asciiz "\nGameboard error! GOODBYE\n"
invalid_move_str: .asciiz "Move is invalid. Try again.\n"
conflicts_str: .asciiz "Conflict! Value can not be placed in board. Try again.\n"
.text 
.globl main

# $a0: address of string
__replaceNewline:
	lb $t0, 0($a0)
	beqz $t0, __replaceNewline_done
    li $t1, '\n'
	beq $t0, $t1, __replaceNewline_found
	addi $a0, $a0, 1
	j __replaceNewline
__replaceNewline_found:
	sb $0, 0($a0)
__replaceNewline_done:
	jr $ra


# $a0, string to print
# $v0, return color
__inputColor:
	move $t1, $a0 
	li $v0, 4
	syscall

	li $v0, 5
	syscall

	bltz $v0, __inputColor_err
    li $t0, 15
	bgt $v0, $t0, __inputColor_err
    jr $ra

__inputColor_err:
    li $v0, 4
    la $a0, invalid_color_str
	syscall
	move $a0, $t1
	j __inputColor


main:
	# print welcome message
	li $v0, 4
	la $a0, welcome
	syscall

main_enterColors:
	# Prompt and get the colors by user
    la $a0, bg_preset_str
    jal __inputColor
    move $s2, $v0

    la $a0, fg_preset_str
    jal __inputColor
    move $s3, $v0

    la $a0, bg_error_str
    jal __inputColor
    move $s4, $v0

	# Check the colors inputted by users
	move $a0, $s2   # pc_bg
	move $a1, $s3   # pc_fg
	li $a2, 0xF	# gc_bg  always white bg (to work with reset)
	li $a3, 0   # gc_fg  always black fg (to work with reset)
	addi $sp, $sp, -4   # load 5th argument on the stack
	sw $s4, 0($sp)
	jal checkColors   
	addi $sp, $sp, 4    # remove 5th argument on the stack
	li $t8, 0xFFFF
	bne $v0, $t8, main_colors_done
	# print error message
	li $v0, 4
	la $a0, invalid_colorSet_str
