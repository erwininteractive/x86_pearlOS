org 0x7c00
bits 16

%define ENDL 0x0d, 0x0a

jmp short start
nop

; BIOS param block
bdb_oem:                    db 'MSWIN4.1'
bdb_bytes_per_sector:       dw 512
bdb_sectors_per_cluster:    db 1 
bdb_reserved_sectors:       dw 1
bdb_fat_count:              db 2
bdb_dir_entries_count:      dw 0e0h
bdb_total_sectors:          dw 2880
bdb_media_description_type: db 0f0h
bdb_sectors_per_fat:        dw 9
bdb_sectors_per_track:      dw 18
bdb_heads:                  dw 2
bdb_hidden_sectors:         dd 0
bdb_large_sector_count:     dd 0

; extended boot record
ebr_drive_number:           db 0
                            db 0
ebr_signature:              db 29h
ebr_volume_id:              db 66h, 66h, 66h, 66h
ebr_volume_label:           db 'PearlOS    '
ebr_system_id:              db 'FAT12   '

start:
    jmp main

puts:
    push si
    push ax

.loop:
    lodsb
    or al, al
    jz .done

    mov ah, 0x0e
    int 0x10

    jmp .loop

.done:
    pop ax
    pop si
    ret


main:
    mov ax, 0
    mov ds, ax
    mov es, ax

    ;stack
    mov ss, ax
    mov sp, 0x7c00

    mov [ebr_drive_number], dl
    
    mov ax, 1
    mov cl, 1
    mov bx, 0x7e00

    call diskread

    ; print startup message to screen
    mov si, msg_startup
    call puts

    cli                 ; dnd
    hlt

floppyerror:
    mov si, msg_floppy_failed
    call puts
    jmp reboot

reboot:
    mov ah, 0
    int 16h
    jmp 0ffffh:0        ; beginning of BIOS

.halt:
    cli                 ; dnd
    hlt

lbatochs:
    push ax
    push dx
    
    xor dx, dx
    div word [bdb_sectors_per_track]

    inc dx
    mov cx, dx

    xor dx, dx
    div word [bdb_heads]

    mov dh, dl
    mov ch, al
    shl ah, 6
    or cl, ah

    pop ax
    mov dl, al
    pop ax

    ret

diskread:
    push ax
    push bx
    push cx
    push dx
    push di

    push cx
    call lbatochs
    pop ax

    mov ah, 02h
    mov di, 3       ; retry the conversion 3 times. Suggested in FAT documentation

.retry:
    pusha
    stc
    int 13h
    jnc .done

    ; failure
    popa
    call reset

    dec di
    test di, di
    jnz .retry

.fail:
    jmp floppyerror


.done:
    popa

    pop di
    pop dx
    pop cx
    pop bx
    pop ax

    ret

reset:
    pusha
    mov ah, 0
    stc
    int 13h
    jc floppyerror
    popa

    ret

msg_startup:        db 'Welcome to PearlOS', ENDL, 0
msg_floppy_failed:  db 'I could not read from the disk!', ENDL, 0

times 510-($-$$) db 0
dw 0aa55h
