;
; Block 5 solution: classify a number, then count up to it.
;
; Here so a student who missed Block 5 can start Block 6 today.
;
;       make PROG=b5_solution run
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
        ; Three-way branch. The signed jumps are the right family here because
        ; the user is allowed to type a negative number. jl and jg on the same
        ; comparison with jb and ja would call every negative number huge.
        ;
        cmp     esi, 0
        jl      .negative
        je      .zero

        mov     eax, pos_msg
        call    print_string
        call    print_nl

        ;
        ; Count 1 up to esi, printing each. The separator goes BEFORE each
        ; number except the first, rather than after each one, because a
        ; trailing space is invisible on screen and check compares bytes.
        ;
        mov     ecx, 1                  ; the counter
        mov     edi, 0                  ; the running sum
.count:
        cmp     ecx, esi
        jg      .counted

        mov     eax, ecx
        call    print_int
        add     edi, ecx

        cmp     ecx, esi                ; was that the last one?
        je      .no_separator
        mov     eax, ' '                ; print_char takes the character in eax
        call    print_char
.no_separator:
        inc     ecx
        jmp     .count

.counted:
        call    print_nl

        mov     eax, sum_msg
        call    print_string
        mov     eax, edi
        call    print_int
        call    print_nl
        jmp     .done

.negative:
        mov     eax, neg_msg
        call    print_string
        call    print_nl
        jmp     .nothing

.zero:
        mov     eax, zero_msg
        call    print_string
        call    print_nl

.nothing:
        mov     eax, none_msg
        call    print_string
        call    print_nl

.done:
        popa
        mov     eax, 0
        leave
        ret
