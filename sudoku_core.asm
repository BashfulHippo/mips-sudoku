# sudoku core functions
# cell management, validation, and game logic

.text

# Part #1 Functions
checkColors:
	# save registers conventions
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	#load frm stack (err
	lw $t0, 4($sp)
#cannot be the same as any color
	beq $t0, $a0, checkColors_error 
	beq $t0, $a1, checkColors_error  
	beq $t0, $a2, checkColors_error
	beq $t0, $a3, checkColors_error
	
	beq $a1, $a3, checkColors_error
	beq $a1, $a0, checkColors_error
	beq $a2, $a3, checkColors_error
	
	sll $t1, $a0, 4 
	or $t1, $t1, $a1
	
	sll $t2, $a2, 4 
	or $t2, $t2, $a3 
	
	#preset left 8) or game
	sll $v0, $t1, 8
	or $v0, $v0, $t2
	
	move $v1, $t0
	j checkColors_done
	
checkColors_error:
	li $v0, 0xFFFF
	li $v1, 0xFF
	
checkColors_done:
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra


# Function B:setCell
setCell:
	bltz $a0, setCell_error
	bge $a0, 9, setCell_error
	
	bltz $a1, setCell_error
	bge $a1, 9, setCell_error
	
	blt $a2, -1, setCell_error
	bgt $a2, 9, setCell_error
	
#calculate address
	li $t0, 0xffff0000 #base
	li $t1, 18 # 9 columns*2 bytes (each cell)
	mul $t2, $a0, $t1 #row
	sll $t3, $a1, 1 #col*2(colls offset)
	add $t0, $t0, $t2 #add row
	add $t0, $t0, $t3
	
	beq $a2, -1, setCell_colorOnly
	
#set asciip
	beqz $a2, setCell_clearChar
	
#convert
	addi $t4, $a2, 48
	sb $t4, 0($t0)
	sb $a3, 1($t0)
	j setCell_success
	
setCell_clearChar:
	sb $zero, 0($t0)
	sb $a3, 1($t0)
	j setCell_success
	
setCell_colorOnly:
	sb $a3, 1($t0)
	j setCell_success
	
setCell_success:
	li $v0, 0
	jr $ra
	
setCell_error:
	li $v0, -1
	jr $ra


# function C: getCell
getCell:
	bltz $a0, getCell_error
	bge $a0, 9, getCell_error
	
	bltz $a1, getCell_error
	bge $a1, 9, getCell_error
	
	li $t0, 0xffff0000
	li $t1, 18
	mul $t2, $a0, $t1
	sll $t3, $a1, 1
	add $t0, $t0, $t2
	add $t0, $t0, $t3
	lbu $v0, 1($t0)
	lbu $t4, 0($t0)
	beqz $t4, getCell_empty
	blt $t4, 49, getCell_error
	bgt $t4, 57, getCell_error
	addi $v1, $t4, -48
	jr $ra
	
getCell_empty:
	li $v1, 0
	jr $ra
	
getCell_error:
	li $v0, 0xFF
	li $v1, -1
	jr $ra

#Function D: reset
reset:
    addi $sp, $sp, -28
    sw $ra, 0($sp)
    sw $s0, 4($sp)
    sw $s1, 8($sp)
    sw $s2, 12($sp)
    sw $s3, 16($sp)
    sw $s4, 20($sp)
    sw $s5, 24($sp)
    move $s0, $a0
    move $s1, $a1
    move $s2, $a2
    bgez $s2, reset_skip_errcheck
    j reset_clearAll
    
reset_skip_errcheck:
    bgt $s1, 0xF, reset_error
    beqz $s2, reset_presetOnly
    j reset_findConflicts

reset_clearAll:
    li $s3, 0
reset_clearAll_rowLoop:
    bge $s3, 9, reset_success
    li $s4, 0
reset_clearAll_colLoop:
    bge $s4, 9, reset_clearAll_nextRow
    
    move $a0, $s3
    move $a1, $s4
    li $a2, 0
    li $a3, 0xF0 #white, black
    jal setCell
    bltz $v0, reset_error
    
    addi $s4, $s4, 1
    j reset_clearAll_colLoop
    
reset_clearAll_nextRow:
    addi $s3, $s3, 1     # row++
    j reset_clearAll_rowLoop

reset_presetOnly:
    #reset to prset colors only
    #sudoku gui bugged(mars)
    srl $t0, $s0, 8 #preset
    andi $t0, $t0, 0xFF
    andi $t1, $s0, 0xFF  #game
    
    li $s3, 0
reset_preset_rowLoop:
    bge $s3, 9, reset_success
    li $s4, 0
    
reset_preset_colLoop:
    bge $s4, 9, reset_preset_nextRow
    move $a0, $s3
    move $a1, $s4
    jal isPresetCell
    bltz $v0, reset_error
    bnez $v0, reset_preset_ispreset
    move $a0, $s3
    move $a1, $s4
    jal getCell
    li $t2, 0xFF
    beq $v0, $t2, reset_error
    beqz $v1, reset_preset_nextCell
    move $a0, $s3
    move $a1, $s4
    li $a2, 0
    move $a3, $t1
    jal setCell
    bltz $v0, reset_error
    j reset_preset_nextCell
