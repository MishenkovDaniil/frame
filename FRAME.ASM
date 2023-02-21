.model tiny
.code
org 100h
locals @@

;-----------------------------------
VIDMEM          equ 0b800h
;-----------------------------------

;-----------------------------------
;Loads ES with video seg addr
;-----------------------------------
;Entry: None
;Exit: None
;Destroys: BX
;-----------------------------------
LoadVideoES     macro


                nop
                mov bx, VIDMEM
                mov es, bx
                nop


                endm
;-----------------------------------

;-----------------------------------
;Exit programm
;-----------------------------------
;Entry: None
;Exit: None
;Destroys: N/A 
;-----------------------------------
Exit            macro


                nop
                mov ax, 4c00h
                int 21h
                nop


                endm
;-----------------------------------



Start:          LoadVideoES
                xor bx, bx

                mov di, 81h
                call Frameprint
                Exit

;-----------------------------------
;Print frame on user screen
;-----------------------------------
;Entry: ES = 0b800h (set on video memory start addr)
;       DI = attr: start of array of printing chrs
;               0-3:   left corner shift 
;               4-5:   len
;               6-7:   height
;               8-10:  colour
;               11-16: symbols in high str
;               17-22: symbols in mid str
;               23-28: symbols in low str
;Exit: None 
;Destroys: AX, BX, CX, DX, SI, BP, DI = end of msg
;-----------------------------------
Frameprint      proc

                xor bh, bh          ;-| 
                xor ah, ah          ; |
                                    ; |
                call Skipspaces     ; |
                call Read_d_num     ; |
                mov al, 2d          ; |
                mul dl              ; |set bx
                                    ; |
                mov bx, ax          ; |
                                    ; |
                call Skipspaces     ; |
                call Read_d_num     ; |
                mov al, 160d        ; |
                mul dl              ; |
                add bx, ax          ;-|

                call Skipspaces
                call Read_d_num       ;-|set len
                mov si, dx            ;-|


                call Skipspaces
                call Read_d_num       ; |set height
                mov bp, dx            ;-|
                

                call Skipspaces
                call Read_h_num         ;set colour

                push bp 
                mov ax, bx
                shr bp, 1
                shl bp, 5
                add ax, bp
                shl bp, 2
                add ax, bp 
                pop bp  

                push si 
                shr si, 1          ;mov ax, bp shl 8 + bp shl 4                     ;-|shift for text 
                shl si, 1
                add ax, si                                 ;-|
                pop si
                                                                ;
                push ax                                         ; |push shift for text
                xor ah, ah 
                
                push dx                 ;push colour
                
                ;push bp/2 *160 + bx + si/2
                
                call Skipspaces         ;-|
                call Read_d_num         ; |
                cmp dx, 0               ; |
                je @@scanuser           ; |
                ;push di
                cmp dx, 1               ; |
                je @@theme1             ; |
                cmp dx, 2               ; |
                je @@theme2             ; |
                cmp dx, 3               ; | set theme
                je @@theme3             ; |
                jmp @@error             ; |
@@theme1:       pop dx
                push di
                mov di, offset theme_1  ; |
                jmp @@scanchr           ; |
@@theme2:       pop dx
                push di
                mov di, offset theme_2  ; |
                jmp @@scanchr           ; |
@@theme3:       pop dx
                push di
                mov di, offset theme_3  ; |
                jmp @@scanchr           ;-|

@@scanuser:     pop dx 
                call Skipspaces 
                add di, 18d
                push di
                sub di, 18d

@@scanchr:      
                push dx                 ;push colour
                push dx                 ;push colour
                push dx                 ;push colour
                call Skipspaces
                call Read_h_num     
                push dx             ;set left high symb
                
                call Read_h_num
                push dx             ;set mid high symb

                call Read_h_num
                mov al, dl          ;set right high symb
                
                pop cx 
                mov dl, cl          ;pop mid symb in dl

                pop cx
                mov ah, cl          ;pop left high symb 
                pop cx
                mov dh, cl          ;pop colour 
                mov cx, si          ;len in cx
                push cx
                call Framestring
                
                add bx, 160d        ;next str
                pop cx              ;next str
                sub bx, cx          ;next str
                sub bx, cx          ;next str

                call Read_h_num
                push dx             ;set left mid symb
                
                call Read_h_num
                push dx             ;set mid nmid symb

                call Read_h_num
                mov al, dl          ;set right mid symb

                pop cx 
                mov dl, cl          ;pop mid symb in dl

                pop cx
                mov ah, cl          ;pop left high symb 
                pop cx
                mov dh, cl          ;pop colour 
                mov cx, si          ;len in cx
                dec bp 
                
@@mid:                
                push cx             ; push len
                ;push bp
                call Framestring
                
                ;pop cx 
                ;add cx, cx 


                add bx, 160d        ;next str
                pop cx              ;next str (pop len)
                sub bx, cx          ;next str
                sub bx, cx          ;next str
                
                dec bp
             
                cmp bp, 1
                jne @@mid

                call Read_h_num
                push dx             ;set left low symb
                
                call Read_h_num
                push dx             ;set mid low symb

                call Read_h_num
                mov al, dl          ;set right low symb

                pop cx 
                mov dl, cl          ;pop mid symb in dl

                pop cx
                mov ah, cl          ;pop left high symb 
                pop cx
                mov dh, cl          ;pop colour 
                mov cx, si          ; len in cx
                call Framestring


                pop di
                pop si             ;pop shift for text
                push di 
                call Skipspaces
                inc di
                ;lea di, [di]
                call strlen_to_quote 
                shr bx, 1
                shl bx, 1
                mov cx, bx
                mov bx, si 
                sub bx, cx
                pop di 
                call Skipspaces
                call Print_text                
                
                ret

@@error:        pop dx
                pop dx
                pop dx
                mov ah, 09h
                mov dx, offset error
                int 21h

                ret
                endp
;-----------------------------------

;-----------------------------------
;Find len of string
;-----------------------------------
;Entry: ES:DI = attr: start of str
;Exit:  BX := len of str
;Destroys: AX, CX, DI = next symbol after str end
;-----------------------------------
strlen_to_quote proc

                cld
                
                push di 
                
                mov al, 27h
                dec di 

@@next:         inc di 
                mov cx, 100h
                cmp byte ptr[di], al 
                jne @@next
        
                pop ax
                mov bx, di
                sub bx, ax
                        
                ret 
                endp 
;-----------------------------------
;-----------------------------------
;print string of frame 
;-----------------------------------
;Entry: ES = 0b800h (set on video memory start addr)
;       DI = attr: start of text (MUST START AND END WITH ' symbol)
;       BX = attr: start addr of printing
;       DH = attr: colour
;Exit:  None 
;Destroys: BX, DI = end of msg (symbol '), (DX and AH if error)
;-----------------------------------
Print_text      proc

                cmp byte ptr [di], "'"
                jne @@error
                inc di

@@next_symb:    mov ah, [di]
                mov byte ptr es:[bx], ah 
                inc bx 
                mov byte ptr es:[bx], dh 
                inc bx 

                inc di 
                cmp byte ptr [di], "'"
                je @@end
                jmp @@next_symb
        
@@error:        mov ah, 09h
                mov dx, offset print_text_err
                int 21h

@@end:          ret
                endp 
;-----------------------------------
;-----------------------------------
;print string of frame 
;-----------------------------------
;Entry: ES = 0b800h (set on video memory start addr)
;       BX = attr: start addr of printing
;       CX = attr: len of str
;       DH = attr: colour
;       DL = attr: mid symbol
;       AH = attr: left symbol
;       AL = attr: right symbol
;Exit:  None 
;Destroys: BX, CX
;-----------------------------------
Framestring     proc

                mov byte ptr es:[bx], ah
                inc bx
                mov byte ptr es:[bx], dh 
                inc bx

                sub cx, 2

@@Next:         mov es:[bx], dx
                add bx, 2
                loop @@Next

                mov byte ptr es:[bx], al
                inc bx
                mov byte ptr es:[bx], dh 
                inc bx
                
                ret
                endp 
;-----------------------------------
;-----------------------------------
;Read num up to 255d from string
;-----------------------------------
;Entry; DI = attr: start of string with number
;Exit:  DL = num
;       SI = addr of next symbol after num 
;Destroys: AX, CX, DH = 0
;-----------------------------------
Read_d_num      proc  


                xor dx, dx
                mov cx, 3

@@r_next:       mov al, 10d 
                mul dl
                mov dl, al

                add dl, [di]
                sub dl, '0'
                inc di
                cmp byte ptr [di], ' '
                je @@ret
                cmp byte ptr [di], 0Dh
                jne @@loop
                jmp @@ret
@@loop:         loop @@r_next

@@ret:          ret
                endp  
;-----------------------------------
;-----------------------------------
;Read hex num up to 255d from string
;-----------------------------------
;Entry; DI = attr: start of string with number
;Exit:  DL = num
;       SI = addr of next symbol after num 
;Destroys: AX, CX, DH = 0
;-----------------------------------
Read_h_num      proc  

                xor dx, dx
                mov cx, 2

@@r_next:       mov al, 10h 
                mul dl
                mov dl, al

                add dl, [di]
                cmp byte ptr [di], '9'
                
                jna @@digit

                sub dl, 'A'
                add dl, 10  
                
                inc di
                cmp byte ptr [di], ' '
                je @@ret
                cmp byte ptr [di], 0Dh 
                jne @@loop
                jmp @@ret
@@loop:         loop @@r_next

                ret
                
@@digit:        sub dl, '0'


                inc di
                cmp byte ptr [di], ' '
                jne @@loop

@@ret:          ret
                endp  
;-----------------------------------
;-----------------------------------
;skip space symbols in str
;-----------------------------------
;Entry; DI = attr: addr of string
;Exit:  DI = first not space symbol
;Destroys: None
;-----------------------------------
Skipspaces      proc  
                dec di

@@next:         inc di
                cmp byte ptr [di], ' '
                je @@next

                ret
                endp  
;-----------------------------------

theme_1           db '030403030404040303', "'hello'"
theme_2           db '030403030404040303', "'hello'"
theme_3           db '030403030404040303', "'hello'"
error             db 'error$'            
print_text_err    db "error: msg must start with '$"            

end		Start