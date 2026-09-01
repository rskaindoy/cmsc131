;
; Block 2 solution: the temperature converter.
;
; Here so a student who missed Block 2 can start Block 3 today. Read it before
; you use it. Every idea in Block 3 is built on the register habits below.
;
; Build and run it with:
;
;       make PROG=b2_solution run
;

%include "asm_io.inc"

segment .data
prompt      db  "Input a temperature in Celsius: ", 0
f_msg       db  "The temperature in Fahrenheit from Celsius is: ", 0
k_msg       db  "The temperature in Kelvin from Fahrenheit is: ", 0
c_msg       db  "The temperature in Celsius from Kelvin is: ", 0

segment .bss

segment .text
        global  _asm_main
_asm_main:
        enter   0,0
        pusha

        mov     eax, prompt
        call    print_string
        call    read_int
        mov     esi, eax                ; esi holds Celsius from here on

        ;
        ; F = (C * 9) / 5 + 32
        ;
        ; Multiply before dividing. (C / 5) * 9 throws away the remainder
        ; first and is wrong by several degrees, silently.
        ;
        mov     eax, esi
        mov     ebx, 9
        mul     ebx                     ; edx:eax = C * 9
        mov     edx, 0                  ; div reads edx:eax, and mul just wrote edx
        mov     ebx, 5
        div     ebx                     ; eax = (C * 9) / 5
        add     eax, 32
        mov     edi, eax                ; edi holds Fahrenheit

        mov     eax, f_msg
        call    print_string
        mov     eax, edi
        call    print_int
        call    print_nl

        ;
        ; K = ((F - 32) * 5) / 9 + 273
        ;
        mov     eax, edi
        sub     eax, 32
        mov     ebx, 5
        mul     ebx
        mov     edx, 0
        mov     ebx, 9
        div     ebx
        add     eax, 273
        mov     ecx, eax                ; ecx holds Kelvin

        mov     eax, k_msg
        call    print_string
        mov     eax, ecx
        call    print_int
        call    print_nl

        ;
        ; C = K - 273
        ;
        mov     eax, c_msg
        call    print_string
        mov     eax, ecx
        sub     eax, 273
        call    print_int
        call    print_nl

        popa
        mov     eax, 0
        leave
        ret
