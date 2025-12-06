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
	sw $s2, 12($sp) # prest count
	sw $s3, 16($sp) #ame count
	sw $s4, 20($sp) # row counter
	sw $s5, 24($sp) # col counter
	sw $s6, 28($sp) # preset fg color
	sw $s7, 32($sp) # game fg color
	#8byt es for output lines
	
	move $t9, $a0 # save filename
	move $s1, $a1 #save playerColors
	
	srl $t0, $s1, 8 #preset color
	andi $s6, $t0, 0x0F # pfg
	andi $s7, $s1, 0x0F #gamefg
	
	#open file for writing
	move $a0, $t9
	li $a1, 1 #write only
	li $a2, 0 # mode
	li $v0, 13 # 13 is open file
	syscall
	
	bltz $v0, saveBoard_error
	move $s0, $v0 #save fil
	
	#counters
	li $s2, 0 #preset counts
	li $s3, 0 # game count
	
	#loop through board
	li $s4, 0
saveBoard_row_loop:
	bge $s4, 9, saveBoard_close
	li $s5, 0
	
saveBoard_col_loop:
	bge $s5, 9, saveBoard_next_row
	
	#cell info
	move $a0, $s4
	move $a1, $s5
	jal getCell
	li $t0, 0xFF
	beq $v0, $t0, saveBoard_file_error
	
	#1-9
	beqz $v1, saveBoard_next_col  #skip empty
	blt $v1, 1, saveBoard_file_error
	bgt $v1, 9, saveBoard_file_error
	
	#preset/gamecell by fg color
	andi $t1, $v0, 0x0F
	
	addi $a1, $sp, 36
	
	#0-8
	addi $t2, $s4, 48
	sb $t2, 0($a1)
	
	#A-I
	addi $t2, $s5, 65
	sb $t2, 1($a1)
	
	#1-9
	addi $t2, $v1, 48
	sb $t2, 2($a1)
	
	#P or G
	beq $t1, $s6, saveBoard_preset_cell
	beq $t1, $s7, saveBoard_game_cell
	j saveBoard_file_error
	
saveBoard_preset_cell:
	li $t2, 'P'
	sb $t2, 3($a1)
	addi $s2, $s2, 1 #increment
	j saveBoard_write_line
	
saveBoard_game_cell:
	li $t2, 'G'
	sb $t2, 3($a1)
	addi $s3, $s3, 1 #increment
	
saveBoard_write_line:
	li $t2, '\n'
	sb $t2, 4($a1)
	
	move $a0, $s0
	addi $a1, $sp, 36
	li $a2, 5
	li $v0, 15 #write to file 
	syscall
	
	bltz $v0, saveBoard_file_error
	
saveBoard_next_col:
	addi $s5, $s5, 1
	j saveBoard_col_loop
	
saveBoard_next_row:
	addi $s4, $s4, 1
	j saveBoard_row_loop
	
saveBoard_close:
	move $a0, $s0
	li $v0, 16 # close file (16)
	syscall
	
	move $v0, $s2  
	move $v1, $s3
	j saveBoard_done
	
saveBoard_file_error:
	move $a0, $s0
	li $v0, 16
	syscall
	
saveBoard_error:
	li $v0, -1
	li $v1, -1
	
saveBoard_done:
	lw $ra, 0($sp)
	lw $s0, 4($sp)
	lw $s1, 8($sp)
	lw $s2, 12($sp)
	lw $s3, 16($sp)
	lw $s4, 20($sp)
	lw $s5, 24($sp)
	lw $s6, 28($sp)
	lw $s7, 32($sp)
	addi $sp, $sp, 52
	jr $ra


#function L (hint)
hint:
    addi $sp, $sp, -32
    sw $ra, 0($sp)
    sw $s0, 4($sp)
    sw $s1, 8($sp)
    sw $s2, 12($sp)
    sw $s3, 16($sp)
    sw $s4, 20($sp)
    sw $s5, 24($sp)
    sw $s6, 28($sp)
    
    #temp
    li $s4, 0
    li $s5, 1
    
hint_debug_loop:
    bgt $s5, 9, hint_debug_done
    li $t1, 1
    sllv $t0, $t1, $s5
    or $s4, $s4, $t0
    addi $s5, $s5, 1
    j hint_debug_loop
    
hint_debug_done:
    move $v0, $s4
    j hint_return
hint_test_loop:
	bgt $s5, 9, hint_done
	move $a0, $s2 # row
	move $a1, $s3 # col
	move $a2, $s5 # test valyee
	li $a3, 0
	addi $sp, $sp, -4
	sw $zero, 0($sp)
	jal check
	addi $sp, $sp, 4
	
	bnez $v0, hint_conflict
	
	li $t1, 1
	sllv $t0, $t1, $s5  #sllv (variable shift)
	or $s4, $s4, $t0 #set the bit
hint_conflict:
	addi $s5, $s5, 1
	j hint_test_loop
	
hint_done:
	move $v0, $s4
	j hint_return
	
hint_error:
	li $v0, 0xFFFF
	
hint_return:
	lw $ra, 0($sp)
	lw $s0, 4($sp)
	lw $s1, 8($sp)
	lw $s2, 12($sp)
	lw $s3, 16($sp)
	lw $s4, 20($sp)
	lw $s5, 24($sp)
	lw $s6, 28($sp)
	addi $sp, $sp, 32
	jr $ra


# ============================================
# BACKTRACKING SOLVER
# recursive constraint-based sudoku solver
# ============================================

# findEmpty: find first empty cell on board
# returns: $v0 = row (0-8), $v1 = col (0-8)
#          $v0 = -1 if no empty cells (solved)
findEmpty:
	addi $sp, $sp, -12
	sw $ra, 0($sp)
	sw $s0, 4($sp)
	sw $s1, 8($sp)

	li $s0, 0              # row = 0
findEmpty_rowLoop:
	bge $s0, 9, findEmpty_notFound
	li $s1, 0              # col = 0

findEmpty_colLoop:
	bge $s1, 9, findEmpty_nextRow

	move $a0, $s0
	move $a1, $s1
	jal getCell

	beqz $v1, findEmpty_found    # if value == 0, found empty

	addi $s1, $s1, 1
	j findEmpty_colLoop

findEmpty_nextRow:
	addi $s0, $s0, 1
	j findEmpty_rowLoop

findEmpty_found:
	move $v0, $s0          # return row
	move $v1, $s1          # return col
	j findEmpty_done

findEmpty_notFound:
	li $v0, -1             # no empty cells
	li $v1, -1

findEmpty_done:
	lw $ra, 0($sp)
	lw $s0, 4($sp)
	lw $s1, 8($sp)
	addi $sp, $sp, 12
	jr $ra


# isValid: check if value can be placed at (row, col)
