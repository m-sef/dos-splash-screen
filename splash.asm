;==================================================================================================
;
;.d8888. d8888b. db       .d8b.  .d8888. db   db   .d8888.  .o88b. d8888b. d88888b d88888b d8b   db
;88'  YP 88  `8D 88      d8' `8b 88'  YP 88   88   88'  YP d8P  Y8 88  `8D 88'     88'     888o  88
;`8bo.   88oodD' 88      88ooo88 `8bo.   88ooo88   `8bo.   8P      88oobY' 88ooooo 88ooooo 88V8o 88
;  `Y8b. 88~~~   88      88~~~88   `Y8b. 88~~~88     `Y8b. 8b      88`8b   88~~~~~ 88~~~~~ 88 V8o88
;db   8D 88      88booo. 88   88 db   8D 88   88   db   8D Y8b  d8 88 `88. 88.     88.     88  V888
;`8888Y' 88      Y88888P YP   YP `8888Y' YP   YP   `8888Y'  `Y88P' 88   YD Y88888P Y88888P VP   V8P
;
;==================================================================================================
TITLE Splash Screen Demo (splash.asm)
; Constants
DOS = 21h
BIOS = 10h

.model small

.stack 10h

.386
;==================================================================================================
mWrite MACRO text
; Writes a string to the terminal
; Recieves:	text = Message to write
; Returns:	Nothing
;==================================================================================================
	LOCAL string
.data
	string BYTE text, 0
.code
	push dx
	
	mov dx, OFFSET string
	call WriteString
	
	pop dx
ENDM
;==================================================================================================


;==================================================================================================
mError MACRO text
; Writes an error message to the terminal and terminates the program
; Recieves:	text = Message to write
; Returns:	Nothing
;==================================================================================================
	LOCAL string
.data
	string BYTE text, 0
.code
	mov dx, OFFSET string
	call WriteString
	mNewLine
	
	mov al, 1
	call EndProgram
ENDM
;==================================================================================================


;==================================================================================================
mNewLine MACRO
; Prints new line
; Recieves:	Nothing
; Returns:	Nothing
;==================================================================================================
.code
	push ax
	push dx
	
	mov ah, 02h
	mov dl, 0Ah ; 0xAH = New Line
	int 21h
	
	pop dx
	pop ax
ENDM
;==================================================================================================

.data
file_name_buffer BYTE 256 DUP(0)

.code
;==================================================================================================
main PROC
; Program entry point
; Recieves:	Nothing
; Returns:	Nothing
;==================================================================================================
	mov ax, @data
	mov ds, ax
	
	; Get the command line argument (File name) and store it in file_name_buffer
	call GetCommandLineArgument
	
	; Open the file with the name specified in file_name_buffer
	mov dx, OFFSET file_name_buffer
	inc dx ; Skip space at the start of file name
	call OpenFile
	
	; Read the contents of that file into the VGA (Video Graphics Array)
	mov bx, ax
	call ReadFileIntoVGA
	
	; Close the file
	call CloseFile
	
	; Read character without echo
	mov ah, 07h
	int DOS
	
	mov al, 0
	call EndProgram
main ENDP
;==================================================================================================


;==================================================================================================
EndProgram PROC
; Terminates the program
; Recieves:	AL = Error code
; Returns:	Nothing
;==================================================================================================
	mov ah, 4Ch
	int DOS
EndProgram ENDP
;==================================================================================================


;==================================================================================================
ReadFileIntoVGA PROC USES ax cx dx ds
; Writes the contents of the file into the VGA (Video Graphics Array)
; Recieves:	BX = File handle
; Returns:	Nothing
;==================================================================================================
	pushf
	
	mov ax, 0B800h
	mov ds, ax
	mov dx, 0
	
	mov ah, 3Fh
	mov cx, 4000
	
	int DOS

	popf
	ret
ReadFileIntoVGA ENDP
;==================================================================================================


;==================================================================================================
GetCommandLineArgument PROC USES ax bx cx si di es
; Gets the command line argument from the program segment prefix
; Recieves:	Nothing
; Returns:	Nothing
;==================================================================================================
	pushf
	
	; Get current Program Segment Prefix address. Returns the address in register BX
	mov ah, 62h
	int DOS
	
	; Initialize registers
	mov cl, 0
	mov es, bx
	mov di, OFFSET file_name_buffer
	mov si, 80h
	
	; Move the length of the command line argument into register CH (0-256)
	mov ch, es:[si]
	; Increment register SI so that it points to the first character of the argument
	inc si
	
	jmp condition
top:
	mov bl, es:[si]
	mov [di], bl
	
	inc si
	inc di
	inc cl
condition:
	cmp cl, ch
	jb top
	
	mov BYTE PTR[di], 0
	
	popf
	ret
GetCommandLineArgument ENDP
;==================================================================================================


;==================================================================================================
OpenFile PROC USES dx
;
; Recieves:	DS:DX -> File name
; Returns:	AX = File handle
;==================================================================================================
	pushf
	
	mov ah, 3Dh
	
	mov al, 0
	int DOS
	
	jnc done
	mWrite 'File "'
	call WriteString
	mError '" not found.'
done:
	
	popf
	ret
OpenFile ENDP
;==================================================================================================


;==================================================================================================
CloseFile PROC USES ax
;
; Recieves:	BX = File handle
; Returns:	Nothing
;==================================================================================================
	pushf
	
	mov ah, 3Eh
	int DOS
	
	jnc done
	mError "File could not be closed."
done:
	
	popf
	ret
CloseFile ENDP
;==================================================================================================


;==================================================================================================
WriteString PROC USES ax bx dx
; Writes a null terminated string to the terminal
; Recieves:	DS:DX -> String
; Returns:	Nothing
;==================================================================================================
	pushf
	
	mov ah, 02h
	mov bx, dx
	
	jmp condition
top:
	mov dl, [bx]
	int DOS
	
	inc bx
condition:
	cmp BYTE PTR[bx], 0
	jne top
	
	popf
	ret
WriteString ENDP
;==================================================================================================
END main