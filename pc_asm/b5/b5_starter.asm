;
; Block 5 starter: classify a number, then count up to it.
;
; This assembles and runs as it stands. It prompts, reads a number, and stops.
; The branching and the loop are yours.
;
; Rename it first:
;
;       cp b5_starter.asm classify.asm
;

%include "asm_io.inc"

segment .data
prompt      db  "Enter an integer: ", 0
neg_msg     db  "negative", 0
zero_msg    db  "zero", 0
pos_msg     db  "positive", 0
sum_msg     db  "sum: ", 0
none_msg    db  "nothing to count", 0

segment .bss

segment .text
        global  _asm_main
_asm_main:
        enter   0,0
        pusha

        mov     eax, prompt
        call    print_string
        call    read_int
        mov     esi, eax                ; esi holds the number

        ;
        ; TODO 1: the three-way branch.
        ;
        ; cmp esi against 0 and jump to .negative, .zero, or fall through into
        ; the positive case. Use the SIGNED jump family, jl and je and jg. The
        ; unsigned ones read every negative number as about four billion.
        ;
        ; Each case prints its word and a newline.
        ;

        ;
        ; TODO 2: the counting loop, for the positive case only.
        ;
        ; Print every integer from 1 up to esi on one line, separated by
        ; spaces, and add each one to a running total as you go.
        ;
        ; Two things to decide before you write it.
        ;
        ; Which register survives the loop? print_int and print_char give you
        ; back every register you had, so a counter in ecx and a total in edi
        ; both survive the calls. Only eax is spoken for, because that is how
        ; you hand a value to a routine.
        ;
        ; And where does the space go? Printing one after every number leaves
        ; a trailing space at the end of the line. You cannot see it, and
        ; check compares bytes rather than looks. Printing one BEFORE every
        ; number except the first avoids the problem.
        ;
        ; To print a single space:
        ;
        ;       mov     eax, ' '
        ;       call    print_char
        ;

        ;
        ; TODO 3: print sum_msg followed by the total, then a newline.
        ;

        ;
        ; TODO 4: the negative and zero cases print none_msg instead of
        ; counting anything. Remember that a true branch needs an unconditional
        ; jmp at its end, or it falls straight into the branch below it.
        ;

        popa
        mov     eax, 0
        leave
        ret
