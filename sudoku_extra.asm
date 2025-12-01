# extra credit functions
# save/load, hints, win animation, backtracking solver

.text

# EC FUNCTIONS

setWinBoard:
	addi $sp, $sp, -24
	sw $ra, 0($sp)
	sw $s0, 4($sp) # CColor
	sw $s1, 8($sp) # row counter
	sw $s2, 12($sp) #col conter
	sw $s3, 16($sp) #star color (byte 1)
	sw $s4, 20($sp) # diagonal color(byte 0)
	
	move $s0, $a0 # save CColor
	
	# get colors
	# byte 1 = star color for row 4q,column E
	srl $s3, $s0, 8
	andi $s3, $s3, 0xFF
	
	#byte 0 =diagonal
	andi $s4, $s0, 0xFF
	
	#set all cells in ro4 to star color
	li $s1, 4
	li $s2, 0
setWinBoard_row4_loop:
	bge $s2, 9, setWinBoard_row4_done
	
	move $a0, $s1 
	move $a1, $s2 
	li $a2, -1 
	move $a3, $s3 
	jal setCell
	
	addi $s2, $s2, 1
	j setWinBoard_row4_loop
	
setWinBoard_row4_done:
	# set all cells in E
	li $s1, 0
	li $s2, 4
setWinBoard_colE_loop:
	bge $s1, 9, setWinBoard_colE_done
	
	move $a0, $s1
	move $a1, $s2
	li $a2, -1
	move $a3, $s3
	jal setCell
	
	addi $s1, $s1, 1
	j setWinBoard_colE_loop
	
setWinBoard_colE_done:
	#set main diagonals (avoid corners and cneter)
	#1,1), (2,2), (3,3), (5,5), (6,6), (7,7)
	li $s1, 1
setWinBoard_mainDiag_loop:
	bge $s1, 8, setWinBoard_antiDiag
	beq $s1, 4, setWinBoard_mainDiag_skip #skip the center
	
	move $a0, $s1
	move $a1, $s1
	li $a2, -1
	move $a3, $s4
	jal setCell
	
setWinBoard_mainDiag_skip:
	addi $s1, $s1, 1
	j setWinBoard_mainDiag_loop
	
setWinBoard_antiDiag:
	#antidiagonal
	#(1,7), (2,6), (3,5), (5,3), (6,2),(7,1)
	li $s1, 1
	li $s2, 7
setWinBoard_antiDiag_loop:
	bge $s1, 8, setWinBoard_done
	beq $s1, 4, setWinBoard_antiDiag_skip
	
	move $a0, $s1
	move $a1, $s2
	li $a2, -1
	move $a3, $s4
	jal setCell
	
setWinBoard_antiDiag_skip:
	addi $s1, $s1, 1
	addi $s2, $s2, -1
	j setWinBoard_antiDiag_loop
	
setWinBoard_done:
	lw $ra, 0($sp)
	lw $s0, 4($sp)
	lw $s1, 8($sp)
	lw $s2, 12($sp)
	lw $s3, 16($sp)
	lw $s4, 20($sp)
	addi $sp, $sp, 24
	jr $ra

saveBoard:
	addi $sp, $sp, -52
	sw $ra, 0($sp)
	sw $s0, 4($sp) #desciptor
	sw $s1, 8($sp) #playerColors
