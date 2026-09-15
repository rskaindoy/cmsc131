;
; Block 6 solution: compound interest, in whole centavos.
;
; This file is here so that a student who missed Block 6 can start Block 7
; today.
;
;       make PROG=b6_solution run
;
; Two parts of this program run ahead of Block 6.
;
; The rate and the term sit in memory. The program reads them back with
; brackets. This program has more values to keep alive than there are
; registers to keep them in. That shortage is where Block 7 starts. The two
; values are reserved in .bss, because the program writes each one before
; it reads it. Block 7 explains that rule.
;
; print_money below is your own routine. It is built the same way as the
; routines of Carter.
;
; The numbers this program handles:
;
;   * The starting balance is 0 to 2147483647 centavos. That is the range
;     read_int accepts.
;   * The rate is 0 to 100 percent. The interest for one year is then at
;     most the balance, so the quotient of the division fits in eax.
;   * The balance must stay below 4294967296 centavos, which is
;     42949672.95 pesos, for the whole term. The add that grows the balance
;     is a 32-bit add. A balance that passes that limit wraps around.
;
; make-bootcamp-bundles.sh verify-references runs four boundary cases:
; 2000000000 at 5 percent for 1 year, 2147483647 at 100 percent for 1
; year, 100 at 0 percent for 3 years, and 5 at 5 percent for 1 year.
;

%include "asm_io.inc"

segment .data
bal_prompt      db  "Starting balance in centavos: ", 0
rate_prompt     db  "Annual rate as a percent: ", 0
years_prompt    db  "Number of years: ", 0
year_msg        db  "Year ", 0
colon_msg       db  ": ", 0
total_msg       db  "Total interest earned: ", 0
dot             db  ".", 0

segment .bss
rate            resd  1                 ; written by read_int before any read
years           resd  1

segment .text
        global  _asm_main
_asm_main:
        enter   0,0
        pusha

        mov     eax, bal_prompt
        call    print_string
        call    read_int
        mov     esi, eax                ; esi: the running balance, in centavos
        mov     edi, eax                ; edi: what we started with, kept for later

        mov     eax, rate_prompt
        call    print_string
        call    read_int
        mov     [rate], eax

        mov     eax, years_prompt
        call    print_string
        call    read_int
        mov     [years], eax

        mov     ebx, 100                ; the divisor, needed every iteration
        mov     ecx, 1                  ; which year we are in

.year:
        cmp     ecx, [years]
        jg      .finished

        ;
        ; interest = balance * rate / 100
        ;
        ; Multiply first. The division balance / 100 would round the balance
        ; down to whole pesos before the rate applies. Up to 99 centavos are
        ; lost every year.
        ;
        ; mul writes the full product to edx:eax. div divides that pair by
        ; the divisor. Keep edx as mul left it. Clear edx only when the
        ; dividend is a plain 32-bit value with no high half.
        ;
        mov     eax, esi
        mul     dword [rate]            ; edx:eax = balance * rate
        div     ebx                     ; divide the full product by 100
        add     esi, eax                ; balance = balance + interest

        mov     eax, year_msg
        call    print_string
        mov     eax, ecx
        call    print_int
        mov     eax, colon_msg
        call    print_string
        mov     eax, esi
        call    print_money
        call    print_nl

        inc     ecx
        jmp     .year

.finished:
        mov     eax, total_msg
        call    print_string
        mov     eax, esi
        sub     eax, edi                ; total interest = now - what we started with
        call    print_money
        call    print_nl

        popa
        mov     eax, 0                  ; eax carries the value that main returns
        leave
        ret

;
; print_money - print the centavos in eax as pesos and centavos.
;
; One division splits the amount. The quotient is pesos. The remainder is
; centavos.
;
; The division has one awkward part. A value of 5 centavos must print as .05.
; print_int does not know that it owes a leading zero. This routine tests the
; centavos and prints one zero when the test needs it.
;
print_money:
        enter   0,0
        pusha
        pushf

        mov     ebx, 100
        mov     edx, 0                  ; eax is a plain balance, not a product
        div     ebx                     ; eax = pesos, edx = centavos
        mov     ecx, edx                ; stash centavos, print_int wants eax

        call    print_int               ; the pesos

        mov     eax, dot
        call    print_string

        cmp     ecx, 10
        jge     .two_digits
        mov     eax, '0'                ; below ten, so pad it
        call    print_char
.two_digits:
        mov     eax, ecx
        call    print_int

        popf
        popa
        leave
        ret
