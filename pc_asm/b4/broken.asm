;
; Block 4: a program with one bug in it.
;
; Do not fix it by reading it. The block is about finding out what a machine
; is actually doing, so run it, watch it fail, and let gdb tell you where.
;
;       make PROG=broken run
;
; The fix is one instruction. You will know which one once you have looked.
;

%include "asm_io.inc"

segment .data
prompt  db  "Enter a divisor: ", 0
result  db  "1000 divided by your number is: ", 0

segment .bss

segment .text
        global  _asm_main
_asm_main:
        enter   0,0
        pusha

        mov     eax, prompt
        call    print_string
        call    read_int
        mov     ebx, eax

        mov     eax, 1000
        div     ebx

        mov     ecx, eax
        mov     eax, result
        call    print_string
        mov     eax, ecx
        call    print_int
        call    print_nl

        popa
        mov     eax, 0
        leave
        ret
