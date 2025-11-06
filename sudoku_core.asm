# sudoku core functions

.text

# basic cell functions
checkColors:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	# todo: implement
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra
