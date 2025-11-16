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
    
reset_preset_ispreset:
#keep value
    move $a0, $s3
    move $a1, $s4
    li $a2, -1
    move $a3, $t0
    jal setCell
    bltz $v0, reset_error
    
reset_preset_nextCell:
    addi $s4, $s4, 1
    j reset_preset_colLoop
    
reset_preset_nextRow:
    addi $s3, $s3, 1 
    j reset_preset_rowLoop

reset_findConflicts:
    srl $t0, $s0, 8
    andi $t0, $t0, 0xFF
    andi $t1, $s0, 0xFF
    
    srl  $t2, $t0, 4
    andi $t2, $t2, 0x0F
    srl  $t3, $t1, 4
    andi $t3, $t3, 0x0F
    
    beq  $s1, $t2, reset_error
    beq  $s1, $t3, reset_error
    
    li $s5, 0
    li $s4, 0

reset_conflict_colLoop:
    bge $s4, 9, reset_conflict_checkCount
    li $s3, 0
    
reset_conflict_rowLoop:
    bge $s3, 9, reset_conflict_nextCol
    
    move $a0, $s3
    move $a1, $s4
    jal getCell
    
    li $t2, 0xFF
    beq $v0, $t2, reset_error
    
    beqz $v1, reset_conflict_nextCell
    
    srl $t3, $v0, 4
    andi $t3, $t3, 0x0F
    
    bne $t3, $s1, reset_conflict_nextCell

    andi $t4, $v0, 0x0F
    
    srl $t5, $s0, 8
    andi $t5, $t5, 0xFF
    andi $t6, $t5, 0x0F
    
    andi $t7, $s0, 0xFF
    andi $t8, $t7, 0x0F
    
    beq $t4, $t6, reset_conflict_isPreset
    beq $t4, $t8, reset_conflict_isGame
    
    j reset_error
    
reset_conflict_isPreset:
    move $a0, $s3
    move $a1, $s4
    li $a2, -1
    move $a3, $t5
    jal setCell
    bltz $v0, reset_error
    
    addi $s5, $s5, 1
    j reset_conflict_nextCell
    
reset_conflict_isGame:
    move $a0, $s3
    move $a1, $s4
    li $a2, -1
    move $a3, $t7
    jal setCell
    bltz $v0, reset_error
    
    addi $s5, $s5, 1
    
reset_conflict_nextCell:
    addi $s3, $s3, 1
    j reset_conflict_rowLoop
    
reset_conflict_nextCol:
    addi $s4, $s4, 1
    j reset_conflict_colLoop

reset_conflict_checkCount:
    blt $s5, $s2, reset_error
    j reset_success
    
reset_success:
    li $v0, 0
    j reset_done
    
reset_error:
    li $v0, -1
    
reset_done:
    lw $ra, 0($sp)
    lw $s0, 4($sp)
    lw $s1, 8($sp)
    lw $s2, 12($sp)
    lw $s3, 16($sp)
    lw $s4, 20($sp)
    lw $s5, 24($sp)
    addi $sp, $sp, 28
    jr $ra
    
#function E
isPresetCell:
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    
    #0<=row<9
    bltz $a0, isPresetCell_error
    bge $a0, 9, isPresetCell_error
    
    #0<=col<9
    bltz $a1, isPresetCell_error
    bge $a1, 9, isPresetCell_error
    
    #save row n col
    move $t0, $a0
    move $t1, $a1
    
    move $a0, $t0
    move $a1, $t1
    jal getCell
    
    li $t2, 0xFF
    beq $v0, $t2, isPresetCell_error
   
    beqz $v1, isPresetCell_notPreset
    
    srl $t3, $v0, 4
    andi $t3, $t3, 0x0F
    
#white not preset
    li $t4, 0xF
    beq $t3, $t4, isPresetCell_notPreset
    
#value, nonwhite - preset
    li $v0, 1
    j isPresetCell_done

isPresetCell_notPreset:
    li $v0, 0
    j isPresetCell_done

isPresetCell_error:
    li $v0, -1

isPresetCell_done:
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra


# Function E: readFile
readFile:
#stack 52 bytes
#0-35 saved (9 x 4)
#36-43 
#44 value, 48 type
    addi $sp, $sp, -52
    sw $ra, 0($sp)
    sw $s0, 4($sp)
    sw $s1, 8($sp)
    sw $s2, 12($sp)
    sw $s3, 16($sp)
    sw $s4, 20($sp)
    sw $s5, 24($sp)
    sw $s6, 28($sp)
    sw $s7, 32($sp)
    
    move $t9, $a0
    move $s1, $a1
    
    li $s0, 0
    srl $s2, $s1, 8
    andi $s2, $s2, 0xFF
    andi $s3, $s1, 0xFF
    
    move $a0, $s1
    li $a1, 0
    li $a2, -1
    jal reset
    bltz $v0, readFile_error
    
#open file for reading
    move $a0, $t9 
    li $a1, 0
    li $a2, 0
    li $v0, 13 #13 open file
    syscall
    
#successful
    bltz $v0, readFile_error
    move $s0, $v0 #save the descriptor
    li $s4, 0

readFile_loop:
#read 5 chars
    move $a0, $s0
    addi $a1, $sp, 36
    li $a2, 5
    li $v0, 14
    syscall
    
    blez $v0, readFile_close
    
    addi $a0, $sp, 36
    li $a1, 0
    jal getBoardInfo
    li $t0, -1
    beq $v0, $t0, readFile_error
    beq $v1, $t0, readFile_error
    move $s5, $v0
    move $s6, $v1
    
#get value , type
    addi $a0, $sp, 36
    li $a1, 1
    jal getBoardInfo
    li $t0, -1
    beq $v0, $t0, readFile_error
    beq $v1, $t0, readFile_error
    sw $v0, 44($sp)
    sw $v1, 48($sp)
    
    move $a0, $s5
    move $a1, $s6
    jal getCell
    li $t0, 0xFF
    beq $v0, $t0, readFile_error
    move $s7, $v1
    
    lw $t6, 44($sp) #restore value
    lw $t5, 48($sp) #restore type
    li $t0, 'P'
    beq $t5, $t0, readFile_preset
    
#game cell color
    move $t4, $s3 
    j readFile_setCell

readFile_preset:
    move $t4, $s2 #preset color

readFile_setCell:
    move $a0, $s5
    move $a1, $s6
    move $a2, $t6
    move $a3, $t4
    jal setCell
    bltz $v0, readFile_error

    bnez $s7, readFile_loop
    addi $s4, $s4, 1
    j readFile_loop

readFile_close:
    #close the file
    move $a0, $s0
    li $v0, 16
    syscall
    
    move $v0, $s4
    j readFile_done

readFile_error:
    beqz $s0, readfile_skip_close
    move $a0, $s0
    li $v0, 16
    syscall

readfile_skip_close:
    li $v0, -1

readFile_done:
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


# Part #3 Functions
rowColCheck:
    addi $sp, $sp, -20
    sw $ra, 0($sp)
    sw $s0, 4($sp)
    sw $s1, 8($sp)
    sw $s2, 12($sp)
    sw $s3, 16($sp)
    
    bltz $a0, rowColCheck_error
    bge $a0, 9, rowColCheck_error
    bltz $a1, rowColCheck_error
    bge $a1, 9, rowColCheck_error
    blt $a2, -1, rowColCheck_error
    bgt $a2, 9, rowColCheck_error
    
    move $s0, $a0
    move $s1, $a1
    move $s2, $a2
    move $s3, $a3
    
    beqz $s3, rowColCheck_row
    
rowColCheck_col:
    li $t0, 0
rowColCheck_col_loop:
    bge $t0, 9, rowColCheck_noConflict
    beq $t0, $s0, rowColCheck_col_skip
    move $a0, $t0
    move $a1, $s1
    jal getCell
    li $t1, 0xFF
    beq $v0, $t1, rowColCheck_error
    beqz $v1, rowColCheck_col_skip
    bne $v1, $s2, rowColCheck_col_skip
    move $v0, $t0    
    move $v1, $s1
    j rowColCheck_done

rowColCheck_col_skip:
    addi $t0, $t0, 1
    j rowColCheck_col_loop

rowColCheck_row:
    li $t0, 0
rowColCheck_row_loop:
    bge $t0, 9, rowColCheck_noConflict
    beq $t0, $s1, rowColCheck_row_skip
    
    move $a0, $s0
    move $a1, $t0
    jal getCell
    
    li $t1, 0xFF
    beq $v0, $t1, rowColCheck_error
    
    beqz $v1, rowColCheck_row_skip
    
    bne $v1, $s2, rowColCheck_row_skip
    
    move $v0, $s0
    move $v1, $t0
    j rowColCheck_done

rowColCheck_row_skip:
    addi $t0, $t0, 1
    j rowColCheck_row_loop

rowColCheck_noConflict:
    li $v0, -1
    li $v1, -1
    j rowColCheck_done

rowColCheck_error:
    li $v0, -1
    li $v1, -1

rowColCheck_done:
    lw $ra, 0($sp)
    lw $s0, 4($sp)
    lw $s1, 8($sp)
    lw $s2, 12($sp)
    lw $s3, 16($sp)
    addi $sp, $sp, 20
    jr $ra

# Function G squareCheck
squareCheck:
    addi $sp, $sp, -28
    sw $ra, 0($sp)
    sw $s0, 4($sp)
    sw $s1, 8($sp)
    sw $s2, 12($sp)
    sw $s3, 16($sp)
    sw $s4, 20($sp)
    sw $s5, 24($sp)
    
    bltz $a0, squareCheck_error
    bge $a0, 9, squareCheck_error
    bltz $a1, squareCheck_error
    bge $a1, 9, squareCheck_error
    blt $a2, -1, squareCheck_error
    bgt $a2, 9, squareCheck_error
    
    move $s0, $a0
    move $s1, $a1
    move $s2, $a2
    
    li $t0, 3
    div $s0, $t0
    mflo $t1
    mul $s3, $t1, $t0
    
    div $s1, $t0
    mflo $t1
    mul $s4, $t1, $t0
    
    move $t0, $s3
    addi $t5, $s3, 3
    
squareCheck_row_loop:
    bge $t0, $t5, squareCheck_noConflict
    
    move $t1, $s4
    addi $t6, $s4, 3
    
squareCheck_col_loop:
    bge $t1, $t6, squareCheck_row_next
    
    bne $t0, $s0, squareCheck_checkCell
    beq $t1, $s1, squareCheck_col_next
    
squareCheck_checkCell:
    move $a0, $t0
    move $a1, $t1
    jal getCell
    
    li $t2, 0xFF
    beq $v0, $t2, squareCheck_error
    
    beqz $v1, squareCheck_col_next
    
    bne $v1, $s2, squareCheck_col_next
    
    move $v0, $t0
    move $v1, $t1
    j squareCheck_done
    
squareCheck_col_next:
    addi $t1, $t1, 1
    j squareCheck_col_loop
    
squareCheck_row_next:
    addi $t0, $t0, 1
    j squareCheck_row_loop

squareCheck_noConflict:
    li $v0, -1
    li $v1, -1
    j squareCheck_done

squareCheck_error:
    li $v0, -1
    li $v1, -1

squareCheck_done:
    lw $ra, 0($sp)
    lw $s0, 4($sp)
    lw $s1, 8($sp)
    lw $s2, 12($sp)
    lw $s3, 16($sp)
    lw $s4, 20($sp)
    lw $s5, 24($sp)
    addi $sp, $sp, 28
    jr $ra

# Function H: check
check:
    addi $sp, $sp, -36
    sw $ra, 0($sp)
    sw $s0, 4($sp)
    sw $s1, 8($sp)
    sw $s2, 12($sp)
    sw $s3, 16($sp)
    sw $s4, 20($sp)
    sw $s5, 24($sp)
    sw $s6, 28($sp)
    sw $s7, 32($sp)
    
    lw $s4, 36($sp)   # C36 AFTEr stack
    
    bltz $a0, check_error
    bge $a0, 9, check_error
    bltz $a1, check_error
    bge $a1, 9, check_error
    blt $a2, -1, check_error
    bgt $a2, 9, check_error
    bgt $a3, 0xF, check_error
  
    move $s0, $a0
    move $s1, $a1
    move $s2, $a2
    move $s3, $a3
    
    li $s5, 0
    
    move $a0, $s0
    move $a1, $s1
    move $a2, $s2
    li $a3, 0
    jal rowColCheck
    
    li $t0, -1
    beq $v0, $t0, check_rowDone
    
    addi $s5, $s5, 1
    
    beqz $s4, check_rowDone
    
    move $s6, $v0
    move $s7, $v1
    
    move $a0, $s6
    move $a1, $s7
    jal getCell
    li $t0, 0xFF
    beq $v0, $t0, check_error
    
    andi $t1, $v0, 0x0F
    sll $t2, $s3, 4
    or $t2, $t2, $t1
    
    move $a0, $s6
    move $a1, $s7
    li $a2, -1
    move $a3, $t2
    jal setCell
    bltz $v0, check_error
    
check_rowDone:
    move $a0, $s0
    move $a1, $s1
    move $a2, $s2
    li $a3, 1
    jal rowColCheck
    
    li $t0, -1
    beq $v0, $t0, check_colDone
    
    addi $s5, $s5, 1
    
    beqz $s4, check_colDone
    
    move $s6, $v0
    move $s7, $v1
    
    move $a0, $s6
    move $a1, $s7
    jal getCell
    li $t0, 0xFF
    beq $v0, $t0, check_error
    
    andi $t1, $v0, 0x0F
    sll $t2, $s3, 4
    or $t2, $t2, $t1
    
    move $a0, $s6
    move $a1, $s7
    li $a2, -1
    move $a3, $t2
    jal setCell
    bltz $v0, check_error
    
check_colDone:
    move $a0, $s0
    move $a1, $s1
    move $a2, $s2
    jal squareCheck
    
    li $t0, -1
    beq $v0, $t0, check_squareDone
    
    addi $s5, $s5, 1
    
    beqz $s4, check_squareDone
    
    move $s6, $v0
    move $s7, $v1
    
    move $a0, $s6
    move $a1, $s7
    jal getCell
    li $t0, 0xFF
    beq $v0, $t0, check_error
    
    andi $t1, $v0, 0x0F
    sll $t2, $s3, 4
    or $t2, $t2, $t1
    
    move $a0, $s6
    move $a1, $s7
    li $a2, -1
    move $a3, $t2
    jal setCell
    bltz $v0, check_error
    
check_squareDone:
    move $v0, $s5
    j check_done
    
check_error:
    li $v0, -1
    
check_done:
    lw $ra, 0($sp)
    lw $s0, 4($sp)
    lw $s1, 8($sp)
    lw $s2, 12($sp)
    lw $s3, 16($sp)
    lw $s4, 20($sp)
    lw $s5, 24($sp)
    lw $s6, 28($sp)
    lw $s7, 32($sp)
    addi $sp, $sp, 36
    jr $ra

# function I: makeMove
makeMove:
	addi $sp, $sp, -40
	sw $ra, 0($sp)
	sw $s0, 4($sp) # move string
	sw $s1, 8($sp) # layerColors
	sw $s2, 12($sp) #err color
	sw $s3, 16($sp) #row
	sw $s4, 20($sp) #col
	sw $s5, 24($sp) # moveValue
	sw $s6, 28($sp) # cellColor
	sw $s7, 32($sp) #curvalue
	#save
	move $s0, $a0
	move $s1, $a1
	move $s2, $a2
	
	srl $t0, $s1, 8 #preset color
	andi $t0, $t0, 0xFF
	andi $t1, $s1, 0xFF #gamecolor
	sw $t0, 36($sp)
	
	move $a0, $s0
	li $a1, 0
	jal getBoardInfo
	li $t0, -1
	beq $v0, $t0, makeMove_invalidMove
	beq $v1, $t0, makeMove_invalidMove
	
	move $s3, $v0
	move $s4, $v1
	
	move $a0, $s0
	li $a1, 1
	jal getBoardInfo
	li $t0, -1
	beq $v0, $t0, makeMove_invalidMove
	
	move $s5, $v0
	
	move $a0, $s3
	move $a1, $s4
	jal getCell
	li $t0, 0xFF
	beq $v0, $t0, makeMove_invalidMove
	
	move $s6, $v0
	move $s7, $v1
	
	beq $s7, $s5, makeMove_noChange
	beqz $s7, makeMove_checkifClearingempty
	j makeMove_continue
	
makeMove_checkifClearingempty:
	beqz $s5, makeMove_noChange
	
makeMove_continue:
	lw $t0, 36($sp)
	andi $t1, $s6, 0x0F
	andi $t2, $t0, 0x0F
	beq $t1, $t2, makeMove_invalidMove
	
	beqz $s5, makeMove_clearCell
	
	move $a0, $s3 #row
	move $a1, $s4 #col
	move $a2, $s5 #move Value
	move $a3, $s2  #err color
	addi $sp, $sp, -4
	li $t0, 1
	sw $t0, 0($sp)
	jal check
	addi $sp, $sp, 4
	
	bnez $v0, makeMove_conflicts #branch not equal 0
	
	move $a0, $s3 #row
	move $a1, $s4 #col
	move $a2, $s5 #moveValue
	andi $a3, $s1, 0xFF #game cell color
	jal setCell
	bltz $v0, makeMove_invalidMove
	
#return success
	li $v0, 0
	li $v1, -1
	j makeMove_done

makeMove_clearCell:
	move $a0, $s3 # row
	move $a1, $s4 # col
	li $a2, 0 # clear value
	andi $a3, $s1, 0xFF # game cell color
	jal setCell
	bltz $v0, makeMove_invalidMove
	
	#return success
	li $v0, 0
	li $v1, 1
	j makeMove_done

makeMove_noChange:
	li $v0, 0
	li $v1, 0
	j makeMove_done

makeMove_conflicts:
	# save conflcit coutn first before changign v0
	move $t0, $v0 #save conflcit count from cehck
	li $v0, -1
	move $v1, $t0
	j makeMove_done

makeMove_invalidMove:
	li $v0, -1
	li $v1, 0

makeMove_done:
	lw $ra, 0($sp)
	lw $s0, 4($sp)
	lw $s1, 8($sp)
	lw $s2, 12($sp)
	lw $s3, 16($sp)
	lw $s4, 20($sp)
	lw $s5, 24($sp)
	lw $s6, 28($sp)
	lw $s7, 32($sp)
	addi $sp, $sp, 40
	jr $ra
