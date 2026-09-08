;
; Block 4 solution: broken.asm, with the one instruction it was missing.
;
; Here so a student who missed Block 4 can start Block 5 today. The whole
; difference from the program handed out in Block 4 is the mov edx, 0 below.
;
;       make PROG=b4_solution run
;
; Enter 7 and it prints 142. Enter 0 and it still dies, which is correct: the
; missing instruction was never the only way to fault a div.
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

        ;
        ; div divides the 64-bit value in edx:eax, not the 32 bits in eax.
        ; Whatever the operating system left in edx on the way in counts as
        ; part of the dividend, and it is never zero by luck for long. Clear
        ; it and the quotient fits; leave it and the processor faults trying
        ; to squeeze a huge answer into eax.
        ;
        mov     edx, 0
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
