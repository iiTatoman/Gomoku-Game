# five in a row
.data
board:      .byte 0:225          # 15 x 15 = 225 total size of the board
boardSize:  .word 15            
player1:    .byte 'X'         
player2:    .byte 'O'           
empty:      .byte '-'         
currentPlayer: .word 1           # Current player (1 || 2)
hasWinner:  .word 0              # bool 
promptP1:   .asciiz "Player 1, please input your coordinates: "
promptP2:   .asciiz "Player 2, please input your coordinates: "
invalidMsg: .asciiz "Invalid input\n"
winMsgP1:   .asciiz "Player 1 wins\n"
winMsgP2:   .asciiz "Player 2 wins\n"
tieMsg:     .asciiz "Tie\n"
comma:      .asciiz ","
newline:    .asciiz "\n"
space:      .asciiz " "
fileName:   .asciiz "C:\\Users\\Admin\\Downloads\\result.txt"

# Buffer for reading coordinates
buffer:     .space 100

.text

.globl main
main:
    jal initBoard
    jal displayBoard
    
    gameLoop:
        # check winning condition
        lw $t0, hasWinner
        beq $t0, 1, gameEnd
        
        # check tie condition
        jal checkTie
        beq $v0, 1, gameTie
        
        # input prompt current player
        jal promptPlayer
        
        # get input coordinates
        jal getValidInput
        
        # Update board 
        move $a0, $v1    
        move $a1, $v0    
        jal updateBoard
        jal displayBoard
        # check win
        jal checkWin
        # next player
        jal switchPlayer
        j gameLoop
    
    gameEnd:
        # winner message
        lw $t0, currentPlayer
        li $v0, 4
        beq $t0, 1, showP2Win    # If current player is 1, then player 2 just won
        la $a0, winMsgP1
        syscall
        j writeResult
    
    showP2Win:
        li $v0, 4
        la $a0, winMsgP2
        syscall
        j writeResult
    
    gameTie:
        li $v0, 4
        la $a0, tieMsg
        syscall
        
    writeResult:
        jal writeResultToFile
        
        # exit 
        li $v0, 10
        syscall

# Initialize board 
initBoard:
    li $t0, 0                   # index i
    lw $t1, boardSize           # load board size
    mul $t1, $t1, $t1           # 15*15 = board size
    lb $t2, empty             
    
    initLoop:
        bge $t0, $t1, initDone  # exit when the board is full
        la $t3, board           # board address
        add $t3, $t3, $t0       # get address of current cell
        sb $t2, 0($t3)          # store empty space in cell
        addi $t0, $t0, 1        # i++
        j initLoop
    
    initDone:
        jr $ra                 

# Display current board
displayBoard:
    # save return address
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    
    # format spaces
    li $v0, 4
    la $a0, space
    syscall
    li $v0, 4
    la $a0, space
    syscall
    
    # print column numbers 
    li $t0, 0 # index i
    lw $t1, boardSize
    
    printColNum:
        li $v0, 1
        move $a0, $t0
        syscall
        li $v0, 4
        la $a0, space
        syscall
        
        addi $t0, $t0, 1
        blt $t0, $t1, printColNum
        
    li $v0, 4
    la $a0, newline
    syscall
    
    # print the board content with row numbers
    li $t0, 0       # row index
    
    printBoardRows:
        # print row number
        li $v0, 1
        move $a0, $t0
        syscall
        
        li $v0, 4
        la $a0, space
        syscall
        
        # print row content
        li $t1, 0   # column index
        
        printBoardCols:
            # calculate cell index in the board 
            lw $t2, boardSize
            mul $t3, $t0, $t2
            add $t3, $t3, $t1 # idx = 15*x + y
            
            # load cell value
            la $t4, board
            add $t4, $t4, $t3
            lb $t5, 0($t4)
            
            # print cell value
            li $v0, 11
            move $a0, $t5
            syscall
            
            # space
            li $v0, 4
            la $a0, space
            syscall
            
            # i++
            addi $t1, $t1, 1
            blt $t1, $t2, printBoardCols
        
        li $v0, 4
        la $a0, newline
        syscall
        
        # i++
        addi $t0, $t0, 1
        lw $t2, boardSize
        blt $t0, $t2, printBoardRows
    	li $v0, 4
    	la $a0, newline
    	syscall
    
    # restore return address
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra

# prompt current player
promptPlayer:
    lw $t0, currentPlayer
    li $v0, 4
    beq $t0, 1, promptP1Label
    la $a0, promptP2
    j promptContinue
    
promptP1Label:
    la $a0, promptP1
    
promptContinue:
    syscall
    jr $ra

# get player coordinates
getValidInput:
    # save return address
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    
    inputLoop:
        # read input as string (coordinate)
        li $v0, 8
        la $a0, buffer
        li $a1, 100
        syscall
        
        # take X coordinate
        la $t0, buffer
        li $t2, 0       
        
    parseX:
        lb $t1, 0($t0)
        beq $t1, ',', parseXDone
        beq $t1, '\n', invalidInput
        beq $t1, '\0', invalidInput
        
        # check if character is a digit
        blt $t1, '0', invalidInput
        bgt $t1, '9', invalidInput
        
        # convert digit and add to X value
        sub $t1, $t1, '0' # char - '0'
        mul $t2, $t2, 10
        add $t2, $t2, $t1
        
        # move to next character
        addi $t0, $t0, 1
        j parseX
        
    parseXDone:
        # check if X is in valid range 
        lw $t3, boardSize
        blt $t2, $zero, invalidInput
        bge $t2, $t3, invalidInput
        move $t7, $t2 #store x
        # skip comma
        addi $t0, $t0, 1
        # parse Y coordinate
        li $t2, 0         
    parseY:
        lb $t1, 0($t0)
        beq $t1, '\n', parseYDone
        beq $t1, '\0', parseYDone
        
        # check is digit
        blt $t1, '0', invalidInput
        bgt $t1, '9', invalidInput
        
        # convert digit and add to Y value
        sub $t1, $t1, '0'
        mul $t2, $t2, 10
        add $t2, $t2, $t1
        
        # next character
        addi $t0, $t0, 1
        j parseY
    
    parseYDone:
    # check if Y is in valid range
    lw $t3, boardSize
    blt $t2, $zero, invalidInput
    bge $t2, $t3, invalidInput
    
    # check if cell is already occupied 
    lw $t3, boardSize
    mul $t4, $t7, $t3    # x*15 
    add $t4, $t4, $t2    # x*15 + y
    la $t5, board
    add $t5, $t5, $t4
    lb $t6, 0($t5)
    lb $t3, empty
    bne $t6, $t3, invalidInput    # if cell already occupied
        
        # return valid X, Y coordinates
        move $v0, $t7    # X
        move $v1, $t2    # Y
        
        # restore return address and return
        lw $ra, 0($sp)
        addi $sp, $sp, 4
        jr $ra
        
    invalidInput:
        # display invalid input message and input again
        li $v0, 4
        la $a0, invalidMsg
        syscall
        jal promptPlayer
        j inputLoop

# Update board 
updateBoard:
    
    # Calculate index in board array
    lw $t0, boardSize
    mul $t1, $a1, $t0    # x * boardSize
    add $t1, $t1, $a0    # x * boardSize + y
    
    # Determine player symbol
    lw $t0, currentPlayer
    beq $t0, 1, usePlayerOne
    lb $t2, player2
    j updateCell
    
    usePlayerOne:
        lb $t2, player1
    
    updateCell:
        # Update cell 
        la $t0, board
        add $t0, $t0, $t1
        sb $t2, 0($t0)
        
        jr $ra

# Switch current player
switchPlayer:
    lw $t0, currentPlayer
    beq $t0, 1, switchToTwo
    li $t0, 1
    j storeSwitched
    
    switchToTwo:
        li $t0, 2
    
    storeSwitched:
        sw $t0, currentPlayer
        jr $ra

# check for winning condition
checkWin:
    # save return address
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    
    # get current player symbol
    lw $t0, currentPlayer
    beq $t0, 1, getSymbolP1
    lb $t1, player2
    j startCheck
    
    getSymbolP1:
        lb $t1, player1 # X
    
    startCheck:
        # checkwin by examining each cell as a potential starting point
        li $t2, 0    # Row counter
        lw $t3, boardSize
        
        rowLoop:
            li $t4, 0    # Column counter
            
            colLoop:
                # Check if current cell matches X
                lw $t5, boardSize
                mul $t6, $t2, $t5    # x*15
                add $t6, $t6, $t4    # x*15 + y
                la $t7, board
                add $t7, $t7, $t6
                lb $t8, 0($t7)
                
                # If cell matches x, check for potential win
                beq $t8, $t1, checkWinDirections
                
            continueColLoop:
                addi $t4, $t4, 1
                blt $t4, $t3, colLoop
                
            addi $t2, $t2, 1
            blt $t2, $t3, rowLoop
        
        # no win found
        li $t0, 0
        sw $t0, hasWinner
        j checkWinEnd
    
    checkWinDirections:
        # Check horizontal (right)
        jal checkHorizontalWin
        beq $v0, 1, winFound
        
        # Check diagonal (down-right)
        jal checkDiagDownRightWin
        beq $v0, 1, winFound
        
        # Check vertical (down)
        jal checkVerticalWin
        beq $v0, 1, winFound
        
        
        # Check diagonal (down-left)
        jal checkDiagDownLeftWin
        beq $v0, 1, winFound
        
        j continueColLoop
    
    winFound:
        li $t0, 1
        sw $t0, hasWinner
    
    checkWinEnd:
        # Restore return address and return
        lw $ra, 0($sp)
        addi $sp, $sp, 4
        jr $ra
    
# Check horizontal win
checkHorizontalWin:
    # Check if there are enough cells to the right
    add $t9, $t4, 4
    lw $t5, boardSize
    bge $t9, $t5, noHorizWin
    
    # Check 5 cells in a row
    li $t9, 0    # counter
    move $t5, $t4    # start column
    
    horizCheckLoop:
        lw $t6, boardSize
        mul $t7, $t2, $t6    # x*15
        add $t7, $t7, $t5    # x*15 + y
        la $t8, board
        add $t8, $t8, $t7
        lb $t8, 0($t8)
        
        bne $t8, $t1, noHorizWin    # Not matching player's symbol
        
        addi $t9, $t9, 1
        beq $t9, 5, horizWin    # Found 5 in a row
        
        addi $t5, $t5, 1
        j horizCheckLoop
    
    horizWin:
        li $v0, 1    # Win found
        jr $ra
    
    noHorizWin:
        li $v0, 0    # No win
        jr $ra

# Check vertical win
checkVerticalWin:
    # Check if there are enough cells below
    add $t9, $t2, 4
    lw $t5, boardSize
    bge $t9, $t5, noVertWin
    
    # Check 5 cells in a column
    li $t9, 0    # counter
    move $t5, $t2    # start row
    
    vertCheckLoop:
        lw $t6, boardSize
        mul $t7, $t5, $t6    # x*15
        add $t7, $t7, $t4    # x*15 + y
        la $t8, board
        add $t8, $t8, $t7
        lb $t8, 0($t8)
        
        bne $t8, $t1, noVertWin    # Not matching player's symbol
        
        addi $t9, $t9, 1
        beq $t9, 5, vertWin    # Found 5 in a row
        
        addi $t5, $t5, 1
        j vertCheckLoop
    
    vertWin:
        li $v0, 1    # Win found
        jr $ra
    
    noVertWin:
        li $v0, 0    # No win
        jr $ra

# Check diagonal down-right win
checkDiagDownRightWin:
    # Check if there are enough cells to the right and down
    add $t9, $t4, 4
    lw $t5, boardSize
    bge $t9, $t5, noDiagDRWin
    
    add $t9, $t2, 4
    bge $t9, $t5, noDiagDRWin
    
    # Check 5 cells diagonally down-right
    li $t9, 0    # counter
    move $t5, $t2    # start row
    move $t6, $t4    # start column
    
    diagDRCheckLoop:
        lw $t7, boardSize
        mul $t8, $t5, $t7    # x*15
        add $t8, $t8, $t6    # x*15 + y
        la $t7, board
        add $t7, $t7, $t8
        lb $t8, 0($t7)
        
        bne $t8, $t1, noDiagDRWin    # Not matching player's symbol
        
        addi $t9, $t9, 1
        beq $t9, 5, diagDRWin    # Found 5 in a row
        
        addi $t5, $t5, 1
        addi $t6, $t6, 1
        j diagDRCheckLoop
    
    diagDRWin:
        li $v0, 1    # Win found
        jr $ra
    
    noDiagDRWin:
        li $v0, 0    # No win
        jr $ra

# Check diagonal down-left win
checkDiagDownLeftWin:
    # Check if there are enough cells to the left and down
    sub $t9, $t4, 4
    blt $t9, 0, noDiagDLWin
    
    add $t9, $t2, 4
    lw $t5, boardSize
    bge $t9, $t5, noDiagDLWin
    
    # Check 5 cells diagonally down-left
    li $t9, 0    # counter
    move $t5, $t2    # start row
    move $t6, $t4    # start column
    
    diagDLCheckLoop:
        lw $t7, boardSize
        mul $t8, $t5, $t7    # x*15
        add $t8, $t8, $t6    # x*15 + y
        la $t7, board
        add $t7, $t7, $t8
        lb $t8, 0($t7)
        
        bne $t8, $t1, noDiagDLWin    # Not matching player's symbol
        
        addi $t9, $t9, 1
        beq $t9, 5, diagDLWin    # Found 5 in a row
        
        addi $t5, $t5, 1
        subi $t6, $t6, 1
        j diagDLCheckLoop
    
    diagDLWin:
        li $v0, 1    # Win found
        jr $ra
    
    noDiagDLWin:
        li $v0, 0    # No win
        jr $ra

# Check if the board is full (tie)
checkTie:
    li $t0, 0    # Index counter
    lw $t1, boardSize
    mul $t1, $t1, $t1    # Total board cells (15*15)
    lb $t2, empty    # Load empty space character
    
    tieCheckLoop:
        bge $t0, $t1, tieFound    # If we've checked all cells, it's a tie
        la $t3, board
        add $t3, $t3, $t0
        lb $t4, 0($t3)
        beq $t4, $t2, noTie    # Found an empty cell, no tie
        
        addi $t0, $t0, 1
        j tieCheckLoop
    
    tieFound:
        li $v0, 1    # Tie found
        jr $ra
    
    noTie:
        li $v0, 0    # No tie
        jr $ra

# Write final board and result to file
writeResultToFile:
    # Open file for writing
    li $v0, 13
    la $a0, fileName
    li $a1, 1    # 1 = write
    li $a2, 0    # Ignored for write
    syscall
    
    move $s0, $v0    # Save file descriptor
    
    # header formatting
    li $v0, 15
    move $a0, $s0
    la $a1, space
    li $a2, 1
    syscall
    
    li $v0, 15
    move $a0, $s0
    la $a1, space
    li $a2, 1
    syscall
    
    # write column numbers 
    li $t0, 0              # Column idx counter
    lw $t1, boardSize      # Load board size
    
    writeColNums:
        # Convert number to character and write
        move $t2, $t0
        li $t3, 10        # For division by 10
        div $t2, $t3
        mflo $t4          # Tens digit
        mfhi $t5          # Ones digit
        
        # For numbers >= 10, write tens digit
        beqz $t4, writeColOnesDigit
        
        # Write tens digit
        addi $t4, $t4, '0'
        li $v0, 15
        move $a0, $s0
        la $a1, buffer
        sb $t4, 0($a1)
        li $a2, 1
        syscall
        
    writeColOnesDigit:
        # Write ones digit
        addi $t5, $t5, '0'
        li $v0, 15
        move $a0, $s0
        la $a1, buffer
        sb $t5, 0($a1)
        li $a2, 1
        syscall
        
        # space
        li $v0, 15
        move $a0, $s0
        la $a1, space
        li $a2, 1
        syscall
        
        # Increment and check if done
        addi $t0, $t0, 1
        blt $t0, $t1, writeColNums
    
    # newline
    li $v0, 15
    move $a0, $s0
    la $a1, newline
    li $a2, 1
    syscall
    
    # Continue with existing code to write the board
    li $t0, 0    # Row counter
    lw $t1, boardSize
    
    writeRows:
        #  row number
        li $v0, 15
        move $a0, $s0
        la $a1, space
        li $a2, 1
        syscall
        
        move $t2, $t0
        li $t3, 10    # For division by 10
        div $t2, $t3
        mflo $t4    # tens digit
        mfhi $t5    # ones digit
        
        # row numbers ones digit
        beqz $t4, writeOnesDigit
        
        # Write tens digit
        addi $t4, $t4, '0'
        li $v0, 15
        move $a0, $s0
        la $a1, buffer
        sb $t4, 0($a1)
        li $a2, 1
        syscall
        
    writeOnesDigit:
        addi $t5, $t5, '0'
        li $v0, 15
        move $a0, $s0
        la $a1, buffer
        sb $t5, 0($a1)
        li $a2, 1
        syscall
        
        # Write space
        li $v0, 15
        move $a0, $s0
        la $a1, space
        li $a2, 1
        syscall
        
        # Write row content
        li $t2, 0    # Column counter
        
        writeRowContent:
            # Calculate cell index in the board array
            lw $t3, boardSize
            mul $t4, $t0, $t3    # x*15
            add $t4, $t4, $t2    # x*15 + y
            la $t5, board
            add $t5, $t5, $t4
            lb $t6, 0($t5)
            
            # Write cell content
            li $v0, 15
            move $a0, $s0
            la $a1, buffer
            sb $t6, 0($a1)
            li $a2, 1
            syscall
            
            # space
            li $v0, 15
            move $a0, $s0
            la $a1, space
            li $a2, 1
            syscall
            
            # ++ column counter
            addi $t2, $t2, 1
            blt $t2, $t1, writeRowContent
        
        # Write newline at end of row
        li $v0, 15
        move $a0, $s0
        la $a1, newline
        li $a2, 1
        syscall
        
        # Increment row counter
        addi $t0, $t0, 1
        blt $t0, $t1, writeRows
    
    # Write result message
    lw $t0, hasWinner
    beqz $t0, writeTie
    
    # Write win message
    lw $t0, currentPlayer
    beq $t0, 1, writeP2Win
    
    # Player 1 wins
    li $v0, 15
    move $a0, $s0
    la $a1, winMsgP1
    li $a2, 12
    syscall
    j closeFile
    
    writeP2Win:
        li $v0, 15
        move $a0, $s0
        la $a1, winMsgP2
        li $a2, 12
        syscall
        j closeFile
    
    writeTie:
        li $v0, 15
        move $a0, $s0
        la $a1, tieMsg
        li $a2, 4
        syscall
    
    closeFile:
        li $v0, 16
        move $a0, $s0
        syscall
        
        jr $ra
