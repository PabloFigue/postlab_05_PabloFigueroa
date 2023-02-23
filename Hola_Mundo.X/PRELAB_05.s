;   Archivo:    PRELAB_05.s
;   Dispositivo: PIC16F887
;   Autor:  Pablo Figueroa
;   Copilador: pic-as (v2.40),MPLABX v6.05
;
;   Progra: Contador binario de 8bits utilizando 2 pushbuttons para aumentar o decrementar el contador.
;   Hardware: LEDs en el puerto A, . Pushbuttons en laas entradas del puerto B.
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

;---------variables a utilizar----------
  
PSECT udata_bank0 ;common memory
 
  W_TEMP:   DS 1 ;Variable reservada para guardar el W Temporal
  STATUS_TEMP: DS 1 ;Variable reservada para guardar el STATUS Temporal
      
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
    
;-------------Vector de Interrupción---------
    
ORG 04h			    ;posicionamiento para las interrupciones.
push:
    movwf W_TEMP	    ;guardado temporal de STATUS y W
    swapf STATUS, W 
    movwf STATUS_TEMP
isr:			    ;instrucciones de la interrupcion
    btfsc RBIF
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
 
    
ORG 200h	; posición para el código
 
 ;------configuracion-------
main:
    
    call config_io	;Configuracion de los puertos ENTRADAS/SALIDAS
    call config_reloj	;Configuracion del oscilador Interno
    call config_push	;Configuracion de los pull-ups
    call config_inte	;Configuracion y habilitacion de las interrupciones
    banksel PORTA
    
    ;------loop principal-------
loop:  

    goto loop
    
    ;--------sub rutinas---------  

config_push:
    banksel TRISA
    bsf IOCB,0 ; Interrupcion ON-CHANGE habilitada para el bit 0 del PORTB
    bsf IOCB,1 ; Interrupcion ON-CHANGE habilitada para el bit 1 del PORTB
    
    banksel PORTA
    movf PORTB, W   ;lectura del PORTB
    bcf RBIF	    ;Se limpia la bandera RBIF
    return
    
config_io:    
    Banksel ANSEL
    clrf ANSEL ; 0 = pines digitales, ANS<4:0> = PORTA,  ANS<7:5> = PORTE // Clear Register ANSEL
    clrf ANSELH ; 0 = pines digitales, ANS<13:8>, estos corresponden al PORTB
    
    Banksel TRISA
    clrf TRISA ; 0 = port A como salida

    ; los primeros dos bits del registro PORTB se colocan como entrada digital
    bsf TRISB, UP ; Bit set (1), BIT 1 del registro TRISB
    bsf TRISB, DOWN ; Bit set (1), BIT 0 del registro TRISB
    bsf WPUB, UP
    bsf WPUB, DOWN
    
    bcf OPTION_REG,7	;Habilitar Pull-ups
    
    Banksel PORTA
    clrf PORTA ; 0 = Apagados, todos los puertos del PORTA estan apagados.
    return
    
config_reloj:
    banksel OSCCON
    ; frecuencia de 250kHz
    bcf IRCF2 ; OSCCON, 6
    bsf IRCF1 ; OSCCON, 5
    bcf IRCF0 ; OSCCON, 4
    bsf SCS ; reloj interno
    return
    
config_inte: ;configuracion de las interrupciones
    bsf GIE	;Habilitacion de las interrupciones globales INTCON REGISTER
    
    bsf RBIE	;Habilitacion de interrupcion por cambio en el PORTB 
    bcf RBIF	;Apagar bandera de cambio en el PORTB.
    return
    

    
END ; Finalización del código
