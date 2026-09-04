;
; Block 3 solution: one bit pattern, read several ways.
;
; Here so a student who missed Block 3 can start Block 4 today.
;
; It needs print_uint.inc beside it, which Block 3 ships. Build with:
;
;       make PROG=b3_solution run
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
        mov     esi, eax                ; the original bits, kept untouched

        ;
        ; The same 32 bits, read as signed and then as unsigned. Nothing about
        ; esi changes between these two. Only the routine reading it does.
        ;
        mov     eax, signed_msg
        call    print_string
        mov     eax, esi
        call    print_int
        call    print_nl

        mov     eax, unsigned_msg
        call    print_string
        mov     eax, esi
        call    print_uint
        call    print_nl

        ;
        ; Signed division. cdq fills edx with copies of the sign bit, which is
        ; what makes edx:eax a 64-bit version of the number in eax. Pairing
        ; mov edx, 0 with idiv instead would hand it a huge positive dividend.
        ;
        mov     eax, div_msg
        call    print_string
        mov     eax, esi
        cdq
        mov     ebx, 7
        idiv    ebx                     ; eax = quotient, edx = remainder
        mov     edi, edx                ; stash the remainder, eax is needed
        call    print_int
        mov     eax, rem_msg
        call    print_string
        mov     eax, edi
        call    print_int
        call    print_nl

        ;
        ; Unsigned multiply. mul writes 64 bits across edx:eax, so edx being
        ; non-zero is exactly the statement "eax alone is not the answer".
        ;
        mov     eax, umul_msg
        call    print_string
        mov     eax, esi
        mov     ebx, 100000
        mul     ebx
        cmp     edx, 0
        jne     .unsigned_overflowed
        call    print_uint              ; edx was zero, so eax is the whole of it
        jmp     .unsigned_done
.unsigned_overflowed:
        mov     eax, over_msg
        call    print_string
.unsigned_done:
        call    print_nl

        ;
        ; Signed multiply. The two-operand imul keeps the result in one
        ; register and sets the overflow flag when it did not fit, so the
        ; question is asked of the flag rather than of edx.
        ;
        mov     eax, imul_msg
        call    print_string
        mov     eax, esi
        mov     ebx, 100000
        imul    eax, ebx
        jo      .signed_overflowed
        call    print_int
        jmp     .signed_done
.signed_overflowed:
        mov     eax, over_msg
        call    print_string
.signed_done:
        call    print_nl

        popa
        mov     eax, 0
        leave
        ret
