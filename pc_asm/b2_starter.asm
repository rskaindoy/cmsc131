;
; Block 2 starter: the temperature converter.
;
; This assembles as it stands. Run `make PROG=convert run` before you change
; anything, so you know the build works and the only thing left to fix is your
; own code. It will prompt, read a number, and print nothing else.
;
; Fill in the three TODOs. Each one is a few instructions.
;
; Rename it first:
;
;       cp b2_starter.asm convert.asm
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
        mov     esi, eax                ; esi holds Celsius. Keep it there.

        ;
        ; TODO 1: Fahrenheit.  F = (C * 9) / 5 + 32
        ;
        ; Multiply before you divide. Clear edx before the div, because the
        ; mul above writes to it. Leave the answer somewhere that is not eax,
        ; because the print_string below needs eax for the message address.
        ;

        mov     eax, f_msg
        call    print_string
        ; TODO: put your Fahrenheit value in eax here
        call    print_int
        call    print_nl

        ;
        ; TODO 2: Kelvin.  K = ((F - 32) * 5) / 9 + 273
        ;
        ; Same shape as TODO 1. Start from the Fahrenheit value you just
        ; computed, not from Celsius.
        ;

        mov     eax, k_msg
        call    print_string
        ; TODO: put your Kelvin value in eax here
        call    print_int
        call    print_nl

        ;
        ; TODO 3: back to Celsius.  C = K - 273
        ;

        mov     eax, c_msg
        call    print_string
        ; TODO: put your Celsius value in eax here
        call    print_int
        call    print_nl

        popa
        mov     eax, 0
        leave
        ret
