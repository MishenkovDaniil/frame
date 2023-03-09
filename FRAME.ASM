.model tiny
.code
org 100h
locals @@

INCLUDE         ../macros/vidmem.asm
INCLUDE         ../macros/exit.asm

Start:          LoadVideoES
                call clean_screen
                ;xor bx, bx

                mov bx, 81h
                call Frameprint
                Exit

INCLUDE         f_clean.asm
INCLUDE         new_fr.asm

end		Start