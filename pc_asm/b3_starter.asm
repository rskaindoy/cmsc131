;
; Block 3 starter: one bit pattern, read several ways.
;
; This assembles and runs as it stands. It prompts, reads a number, and prints
; the labels with nothing after them. Filling in the five TODOs is the work.
;
; Rename it first:
;
;       cp b3_starter.asm signs.asm
;
; Keep print_uint.inc in the same folder. The %include below needs it.
;

%include "asm_io.inc"
%include "print_uint.inc"

segment .data
prompt          db  "Enter an integer: ", 0
signed_msg      db  "As signed:               ", 0
unsigned_msg    db  "As unsigned:             ", 0
div_msg         db  "Divided by 7:            ", 0
rem_msg         db  " remainder ", 0
umul_msg        db  "Times 100000 (unsigned): ", 0
imul_msg        db  "Times 100000 (signed):   ", 0
over_msg        db  "overflowed", 0

segment .bss

segment .text
        global  _asm_main
_asm_main:
        enter   0,0
        pusha

        mov     eax, prompt
        call    print_string
        call    read_int
        mov     esi, eax                ; the original bits. Never overwrite esi.

        ;
        ; TODO 1: print esi with print_int, which reads the bits as signed.
        ;
        mov     eax, signed_msg
        call    print_string
        call    print_nl

        ;
        ; TODO 2: print the SAME esi with print_uint, which reads the same bits
        ; as unsigned. You are not converting anything between these two. You
        ; are asking two different questions about one register.
        ;
        mov     eax, unsigned_msg
        call    print_string
        call    print_nl

        ;
        ; TODO 3: divide esi by 7 with idiv, and print the quotient, then the
        ; rem_msg string, then the remainder.
        ;
        ; idiv pairs with cdq, never with mov edx, 0. And the remainder lands
        ; in edx, which print_int has no use for, so move it somewhere before
        ; you print the quotient.
        ;
        mov     eax, div_msg
        call    print_string
        call    print_nl

        ;
        ; TODO 4: multiply esi by 100000 with mul, the unsigned one.
        ;
        ; mul writes 64 bits across edx:eax. If edx came out non-zero the
        ; answer did not fit, so print over_msg. Otherwise print eax with
        ; print_uint.
        ;
        mov     eax, umul_msg
        call    print_string
        call    print_nl

        ;
        ; TODO 5: multiply esi by 100000 again, this time with the two-operand
        ; imul, the signed one.
        ;
        ; imul leaves the result in one register and sets the overflow flag if
        ; it did not fit, so jo is the test here rather than a look at edx.
        ; Print over_msg when it overflowed and the value with print_int when
        ; it did not.
        ;
        ; Feed the finished program -100. One of these two multiplies
        ; overflows and the other does not. That is the whole point of the
        ; block.
        ;
        mov     eax, imul_msg
        call    print_string
        call    print_nl

        popa
        mov     eax, 0
        leave
        ret
