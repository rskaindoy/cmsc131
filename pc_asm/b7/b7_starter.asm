;
; Block 7 starter: pack three fields into one doubleword, then take it apart.
;
; This program assembles and runs as it stands. It asks the three questions,
; prints the labels, and packs nothing. The bit work is yours.
;
; Rename the file first:
;
;       cp b7_starter.asm pack.asm
;

%include "asm_io.inc"

segment .data
v_prompt    db  "Version (0-15): ", 0
f_prompt    db  "Flag (0 or 1): ", 0
l_prompt    db  "Length (0-255): ", 0
packed_msg  db  "Packed: ", 0
uv_msg      db  "Unpacked version: ", 0
uf_msg      db  "Unpacked flag: ", 0
ul_msg      db  "Unpacked length: ", 0

segment .bss
packed      resd  1                     ; one doubleword, zero at start, written before read

segment .text
        global  _asm_main
_asm_main:
        enter   0,0
        pusha

        mov     eax, v_prompt
        call    print_string
        call    read_int
        mov     esi, eax                ; version

        mov     eax, f_prompt
        call    print_string
        call    read_int
        mov     edi, eax                ; flag

        mov     eax, l_prompt
        call    print_string
        call    read_int
        mov     ecx, eax                ; length

        call    print_nl

        ;
        ; TODO 1: pack the three fields into one doubleword. Store the result
        ; in packed.
        ;
        ; The layout places the version in bits 12 to 15, the flag in bit 8,
        ; and the length in bits 0 to 7.
        ;
        ; Mask each field to its width first. The version keeps 4 bits, the
        ; flag keeps 1 bit, and the length keeps 8 bits. An over-wide input
        ; then cannot reach a field that it does not own.
        ;
        ; Shift each field up to its place. Merge the fields with or. The or
        ; sets bits. It does not clear bits that are already set. The length
        ; needs no shift because bits 0 to 7 are its place.
        ;
        ; A store to memory needs brackets:
        ;
        ;       mov     [packed], eax
        ;
        ; The bare name packed is an address, a constant the assembler knows.
        ; A constant cannot be the destination of a mov, so the line without
        ; brackets does not assemble.
        ;

        mov     eax, packed_msg
        call    print_string
        ; TODO: print the packed value. Read it back from memory with [packed].
        call    print_nl

        ;
        ; TODO 2: unpack all three fields. Read [packed] again for each field.
        ; Do not reuse a register from the pack step. The exercise shows that
        ; the value survived the trip to memory.
        ;
        ; Shift a field down to the bottom first. Then mask it to its width.
        ; The other order works only when the mask matches the field position.
        ;

        mov     eax, uv_msg
        call    print_string
        ; TODO: version
        call    print_nl

        mov     eax, uf_msg
        call    print_string
        ; TODO: flag
        call    print_nl

        mov     eax, ul_msg
        call    print_string
        ; TODO: length
        call    print_nl

        ;
        ; TODO 3, after the rest of the program works: run it with a version
        ; of 20.
        ;
        ; Version 20 is 5 bits wide. Shifted left by 12 places, its top bit
        ; lands in bit 16. This layout leaves bit 16 unused, so the other
        ; fields do not change. The packed value is wrong. With the mask on
        ; the unpack side, the printed version is 4. Without it, the printed
        ; version is 20.
        ;
        ; Then run it with a length of 325. Length 325 is 9 bits wide. Its
        ; top bit lands in bit 8. Bit 8 is the flag, so the flag changes.
        ;
        ; The mask in TODO 1 prevents both cases. The mask is not optional.
        ;

        popa
        mov     eax, 0                  ; eax carries the value that main returns
        leave
        ret
