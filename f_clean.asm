locals @@
.code

;-----------------------------------
;Cleans the screen
;-----------------------------------
;Entry: ES = 0b800h (set on video memory start addr)
;Exit: None 
;Destroys: AX, BX CX
;-----------------------------------
clean_screen    proc
                xor bx, bx

                mov cx, 80d*25d 
@@next:         mov word ptr es:[bx], 0
                add bx, 2
                loop @@next

                ret 
                endp
;-----------------------------------