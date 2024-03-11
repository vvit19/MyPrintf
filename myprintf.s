section .data

error_message:          db 10, "You put incorrect mode for %, exit!", 10, 0

buffer:
times (64)              db 0

jump_table:
			dq Bin
			dq Char
			dq Dec

times ('h' - 'd' - 1)   dq IncorrectMode
			dq Hex
times ('o' - 'h' - 1)   dq IncorrectMode
			dq Oct
times ('s' - 'o' - 1)   dq IncorrectMode
			dq Str

digits_table:           db '0123456789abcdef'
modes_table:            db '0b0ox'

ret_address:            dq 0

section .text

global MyPrintf

MyPrintf:
        pop r13

        push r9
        push r8
        push rcx
        push rdx
        push rsi        ; push function params
        push rbp        ; save base ptr

        mov rsi, rdi    ; save string ptr in rsi
        mov rbp, rsp
        add rbp, 8      ; rbp to params (skip push rbp)

        call Main

        pop rbp
        pop rsi
        pop rdx
        pop rcx
        pop r8
        pop r9

        push r13

        ret

Main:
.While:
        mov al, [rsi]

        cmp al, 0
        je .RetL

        cmp al, '%'
        je HandleMode

        call Putch

        inc rsi
        jmp .While

.RetL:
        ret

;-------------------------------
; Putchar
; Entry:    RSI - string ptr
; Destr:    RDX, RDI, RAX
Putch:
        mov rdx, 1
        mov rdi, 1
        mov rax, 1
        syscall

        ret

;----------------------------
; Parses % mode (%b, %c, ...)
; Entry:    RSI - string ptr
; Destr:    RAX, RBP, RCX, RDX, RDI
HandleMode:
        inc rsi
        xor rax, rax
        mov al, [rsi]
        inc rsi

        cmp al, '%'
        jne .NoPercent

        call Putch
        jmp Main

.NoPercent:
        cmp al, 'b'
        jb IncorrectMode

        cmp al, 's'
        ja IncorrectMode

        jmp [jump_table + 8 * (rax - 'b')]

Char:
        push rsi
        mov rsi, buffer

        mov al, [rbp]
        add rbp, 8
        mov byte [rsi], al

        call Putch

        mov byte [rsi], 0
        pop rsi
        jmp Main

Str:
        push rsi
        mov rsi, [rbp]
        add rbp, 8

        call Puts

        pop rsi
        jmp Main

Dec:
        push rsi

        mov ecx, 10             ; base
        mov rsi, buffer
        mov rax, [rbp]          ; number
        add rbp, 8

        call Itoa10

        pop rsi
        jmp Main
Bin:
        push rsi

        mov rsi, buffer
        mov ecx, 1              ; base = 2^ecx
        mov rax, [rbp]
        add rbp, 8
        call Itoa2x

        pop rsi
        jmp Main

IncorrectMode:
        push rsi
        mov rsi, error_message
        call Puts
        pop rsi

        ret
Oct:
        push rsi

        mov rsi, buffer
        mov ecx, 3
        mov rax, [rbp]
        add rbp, 8
        call Itoa2x

        pop rsi
        jmp Main
Hex:
        push rsi

        mov rsi, buffer
        mov ecx, 4
        mov rax, [rbp]
        add rbp, 8
        call Itoa2x

        pop rsi
        jmp Main

;----------------------------
; Reverses string in buffer
; Entry:    RSI - end of the buffer ptr
; Destr:    RSI, RDI, AL
ReverseString:
        mov rdi, buffer
.While:
        cmp rdi, rsi
        jae .RetL
        mov al, [rsi]
        xchg al, [rdi]
        mov [rsi], al
        dec rsi
        inc rdi
        jmp .While

.RetL:
        ret

;----------------------------
; Puts
; Entry:    RSI - string ptr
; Destr:    AL
Puts:
        push rsi
.While:
        mov al, [rsi]
        cmp al, 0
        je .RetL

        call Putch
        inc rsi
        jmp .While

.RetL:
        pop rsi
        ret

;----------------------------
; Fills buffer '0'
; Entry:    RSI - buffer ptr
; Destr:    AL
ClearBuffer:
        push rsi
.While:
        mov al, [rsi]
        cmp al, 0
        je .RetL

        mov byte [rsi], 0
        inc rsi
        jmp .While

.RetL:
        pop rsi
        ret

;----------------------------
; Convert number to string by base (base = 10)
; Entry:    RSI - buffer ptr
;           ECX - base
;           RAX - number
; Destr:    RSI, BH, RAX, EDX
Itoa10:
        xor ch, ch          ; BH = SF
        mov edx, eax
        test edx, edx
        jns .While
        neg eax
        mov bh, 1
        inc rsi

.While:
        xor edx, edx
        div ecx

        mov dh, [digits_table + edx]
        mov [rsi], dh
        inc rsi

        cmp eax, 0
        jne .While

        cmp bh, 1
        jne .NoNegative
        mov byte [rsi], '-'
        inc rsi

.NoNegative:
        dec rsi
        call ReverseString
        mov rsi, buffer
        call Puts
        call ClearBuffer

        ret

;----------------------------
; Convert number to string by base (base = 2^k)
; Entry:    RSI - buffer ptr
;           ECX = k
;           RAX - number
; Destr:    RSI, CH, RAX, EDX
Itoa2x:
        mov ebx, eax
.While:
        shr ebx, cl
        shl ebx, cl
        sub eax, ebx    ; num -= num >> k
        shr ebx, cl
        mov ah, [digits_table + eax]
        mov [rsi], ah
        inc rsi
        cmp ebx, 0
        je .Break

        mov eax, ebx
        jmp .While

.Break:
        mov al, [modes_table + ecx]
        mov [rsi], al
        inc rsi
        mov al, '0'
        mov [rsi], al          ; put 0x, 0b, 0o

        call ReverseString
        mov rsi, buffer
        call Puts
        call ClearBuffer

        ret
