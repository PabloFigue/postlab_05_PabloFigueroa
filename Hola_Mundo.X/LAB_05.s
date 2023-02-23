;   Archivo:    LAB_05.s
;   Dispositivo: PIC16F887
;   Autor:  Pablo Figueroa
;   Copilador: pic-as (v2.40),MPLABX v6.05
;
;   Progra: Contador binario de 8bits utilizando 2 pushbuttons para aumentar o decrementar el contador y mostrarlos en 2 display.
;   Hardware: LEDs en el puerto A, display en el puerto C, . Pushbuttons en laas entradas del puerto B.
; 
;   Creado: 30 ene, 2023
;   Ultima modificacion: 30 ene, 2023
    
PROCESSOR 16F887
#include <xc.inc>
    
;--------Palabras de Configuración---------
    
; configuration word 1
  CONFIG  FOSC = INTRC_NOCLKOUT   ; Oscillator Selection bits (INTOSC oscillator: CLKOUT function on RA6/OSC2/CLKOUT pin, I/O function on RA7/OSC1/CLKIN)
  CONFIG  WDTE = OFF            ; Watchdog Timer Enable bit (WDT disabled and can be enabled by SWDTEN bit of the WDTCON register)
  CONFIG  PWRTE = OFF           ; Power-up Timer Enable bit (PWRT enabled)
  CONFIG  MCLRE = OFF           ; RE3/MCLR pin function select bit (RE3/MCLR pin function is digital input, MCLR internally tied to VDD)
  CONFIG  CP = OFF              ; Code Protection bit (Program memory code protection is disabled)
  CONFIG  CPD = OFF             ; Data Code Protection bit (Data memory code protection is disabled)
  
  CONFIG  BOREN = OFF           ; Brown Out Reset Selection bits (BOR disabled)
  CONFIG  IESO = OFF            ; Internal External Switchover bit (Internal/External Switchover mode is disabled)
  CONFIG  FCMEN = OFF           ; Fail-Safe Clock Monitor Enabled bit (Fail-Safe Clock Monitor is disabled)
  CONFIG  LVP = OFF              ; Low Voltage Programming Enable bit (RB3/PGM pin has PGM function, low voltage programming enabled)

; configuration word 2
  CONFIG  BOR4V = BOR40V        ; Brown-out Reset Selection bit (Brown-out Reset set to 4.0V)
  CONFIG  WRT = OFF             ; Flash Program Memory Self Write Enable bits (Write protection off)
  
;-----------------MACROS----------------
restart_tmr0 macro
  banksel TMR0	;banco 00
  movlw 240	;valor inicial del TMR0
  movwf TMR0	;Se carga el valor inicial
  bcf T0IF	;Se apaga la bandera de interrupción por Overflow del TMR0
  endm
  
;---------variables a utilizar----------
  
PSECT udata_bank0 ;common memory
  
  W_TEMP:   DS 1 ;Variable reservada para guardar el W Temporal
  STATUS_TEMP: DS 1 ;Variable reservada para guardar el STATUS Temporal
  display: DS 2
  banderas: DS 1
    
  NB: DS 1 ;variable para registrar el Nible Bajo del contador
  NA: DS 1 ;variabl para registrar el Nible Alto del contador

  
  UP EQU 0
  DOWN EQU 1
    
;--------------vector Reset-------------   
PSECT VectorReset, class=CODE, abs, delta=2
;-------------vector reset--------------
ORG 00h		;Posición 0000h para el reset
    
VectorReset:
    PAGESEL main 
    goto main
    
; ----configuracion del microcontrolador----
;PSECT code, delta=2, abs
    
;----------------TABLAS---------------------
    
ORG 100h		    ; posicion para la tabla
 tabla:			    ;tabla donde se retorna el valor de la suma. PARA ANODO
    clrf PCLATH
    bsf PCLATH,0
    addwf PCL,F
    retlw 11000000B ;0
    retlw 11111001B ;1
    retlw 10100100B ;2
    retlw 10110000B ;3
    retlw 10011001B ;4
    retlw 10010010B ;5
    retlw 10000010B ;6
    retlw 11111000B ;7
    retlw 10000000B ;8
    retlw 10010000B ;9
    retlw 10001000B ;10 A
    retlw 10000011B ;11 B
    retlw 11000110B ;12 C 
    retlw 10100001B ;13 D
    retlw 10000110B ;14 E
    retlw 10001110B ;15 F
    
;-------------Vector de Interrupción---------
    
ORG 04h			    ;posicionamiento para las interrupciones.
push:
    movwf W_TEMP	    ;guardado temporal de STATUS y W
    swapf STATUS, W 
    movwf STATUS_TEMP
isr:			    ;instrucciones de la interrupcion
    btfsc T0IF	    ;Verificacion de la bandera de interrupcion del timer0
    call inte_TMR0
    btfsc RBIF	    ;Verificacion de la bandera de interrupcion del PORTB
    call inte_portb
pop:			    ;Retorno de los valores previos de W y STATUS
    swapf STATUS_TEMP, W
    movwf STATUS
    swapf W_TEMP, F
    swapf W_TEMP, W
    retfie

;----------SubRutinas de INTERRUPCIÓN-------
inte_portb: ;interrupcion en el puertoB
    banksel PORTB
    btfss PORTB, UP ;Si el bit 0 cambio, entonces se incrementa el portA
    incf PORTA
    btfss PORTB, DOWN	;Si el bit 1 cambio, entonces se decrementa el portA
    decf PORTA
    bcf RBIF
    return
 
inte_TMR0:
    restart_tmr0 ;macro
    movlw   0x01
    xorwf   banderas, F
    return
    
ORG 200h	; posición para el código
 
 ;------configuracion-------
main:
    
    call config_tmr0	;Temporizador 10ms
    call config_io	;Configuracion de los puertos ENTRADAS/SALIDAS
    call config_reloj	;Configuracion del oscilador Interno
    call config_push	;Configuracion de los pull-ups
    call config_inte	;Configuracion y habilitacion de las interrupciones
    banksel PORTA
    
    ;------loop principal-------
loop:  
    call separar_nibbles
    call preparar_displays
    call display_var
    goto loop
    
    ;--------sub rutinas---------  

config_tmr0:
    Banksel TRISA
    bcf T0CS	;TMR0 como temporizador
    bcf PSA	;Preescaler en TMR0
    bcf PS2	    
    bsf PS1
    bcf PS0	;Prescaler de 1:8 (010)
    restart_tmr0
    return       
    
config_io:    
    Banksel ANSEL
    clrf ANSEL ; 0 = pines digitales, ANS<4:0> = PORTA,  ANS<7:5> = PORTE // Clear Register ANSEL
    clrf ANSELH ; 0 = pines digitales, ANS<13:8>, estos corresponden al PORTB
    
    Banksel TRISA
    clrf TRISA ; 0 = PORTA como salida
    clrf TRISC ; 0 = PORTC como salida
    clrf TRISD ; 0 = PORTD como salida
    ; los primeros dos bits del registro PORTB se colocan como entrada digital
    bsf TRISB, UP ; Bit set (1), BIT 1 del registro TRISB
    bsf TRISB, DOWN ; Bit set (1), BIT 0 del registro TRISB
      
    Banksel PORTA
    clrf PORTA ; 0 = Apagados, todos los puertos del PORTA estan apagados.
    clrf PORTC ; 0 = Apagados, todos los puertos del PORTC estan apagados.
    clrf PORTD ; 0 = Apagados, todos los puertos del PORTD estan apagados.
    return
    
config_reloj:
    banksel OSCCON
    ; frecuencia de 250kHz
    bcf IRCF2 ; OSCCON, 6
    bsf IRCF1 ; OSCCON, 5
    bcf IRCF0 ; OSCCON, 4
    bsf SCS ; reloj interno
    return
    
config_push:
    banksel TRISA
    bsf IOCB,DOWN   ; Interrupcion ON-CHANGE habilitada para el bit 0 del PORTB
    bsf IOCB,UP	    ; Interrupcion ON-CHANGE habilitada para el bit 1 del PORTB
    bsf WPUB, UP    ; Activacion PULLUPS
    bsf WPUB, DOWN  ; Activacion PULLUPS
    bcf OPTION_REG,7	;Habilitar Pull-ups
    
    banksel PORTA
    movf PORTB, W   ;lectura del PORTB
    bcf RBIF	    ;Se limpia la bandera RBIF
    return
    
config_inte: ;configuracion de las interrupciones
    bsf GIE	;Habilitacion de las interrupciones globales INTCON REGISTER
    
    bsf RBIE	;Habilitacion de interrupcion por cambio en el PORTB 
    bcf RBIF	;Apagar bandera de cambio en el PORTB.
    bsf T0IE	;Habilitacion de la interrupcion por overflow del TMR0
    bcf T0IF	;Apagar bandera de overflow del TMR0
    return
    
display_var:
    clrf    PORTD
    btfsc   banderas,  0
    goto    display_1
    goto display_0
    return
display_0:
    movf    display, W
    movwf   PORTC
    bsf     PORTD,  0
    bcf     PORTD,  1
    goto    toggle_b0
display_1:
    movf    display+1, W
    movwf   PORTC
    bsf     PORTD,  1
    bcf     PORTD,  0
    goto toggle_b0     
toggle_b0:    
    movlw   0x01
    xorwf   banderas, F
    return
  
separar_nibbles:
    movf    PORTA, W
    andlw   00001111B
    movwf   NB
    swapf   PORTA, W
    andlw   00001111B
    movwf   NA
    return
    
preparar_displays:
    movf    NB, W
    call    tabla
    movwf   display
    
    movf    NA, W
    call    tabla
    movwf   display+1
    return    
    
END ; Finalización del código



