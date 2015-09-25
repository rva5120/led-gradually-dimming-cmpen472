*************************************************************************
*
* Title:        LED Light Dimming
*
* Objective:    CMPEN 472 Homework 4
*
* Revision:     V2.1.4
*
* Date:         Sept. 23, 2015
*
* Programmer:   Raquel Alvarez
*
* Company:      The Pennsylvania State University
*               Department of Computer Science and Engineering
*
* Algorithm:    Simple Parallel I/O in a nested delay-loop
*
* Register Use: A,B: counters for percentage dimming
*               X,Y: Delay loop counters
*
* Memory Use:   RAM locations from $3000 for data,
*                                  $3100 for program
*
* Input:        Parameters hard coded in the program.
*
* Output:       LED 1,2,3,4 at PORTB bit 4,5,6,7
*
* Observation:  This is a program that gradually dims up and down LED 1
*               from 0% to 100% and from 100% to 0%, infintely.
*
*
* Comments:     This program is developed and simulated using CodeWarrior
*               development software.
*
*************************************************************************

*************************************************************************
* LED Mapping:                                                          *
* -----------------------------------------                             *
* |  LED  | 4   3   2   1   x   x   x   x |                             *
* -----------------------------------------                             *
* | PORTB | 7   6   5   4   3   2   1   0 |                             *
* -----------------------------------------                             *
*                                                                       *                                              *
*************************************************************************

*************************************************************************
* Parameter Declaration Section
*
* Export Symbols
          XDEF        pgstart       ; export 'pgstart' symbol
          ABSENTRY    pgstart       ; for assembly entry point
                                    ; this is the first instruction of the
                                    ; program, up on the start of simulation

* Symbols and Macros
PORTA     EQU         $0000         ; i/o port addresses (port A not used)
DDRA      EQU         $0002       

PORTB     EQU         $0001         ; port B is connected with LEDs   (port = 1 is PORT B)
DDRB      EQU         $0003         
PUCR      EQU         $000C         ; enable pull-up mode for PORT A,B,E,K
                                    ; this leaves the pins logic high

*
*************************************************************************

*************************************************************************
* Data Section
*
                ORG         $3000         ; reserve RAM memory starting address
                                          ; memory $3000 - $30FF are for data

Counter_10us    DC.W        $002F         ; initial Y register count number - 10 usec = 47 cycles
Counter_i       DC.B        $00
Counter_50      DC.B        50


StackSP                                   ; remaining memory space for stack data
                                          ; initial stack pointer position set
                                          ; to $3100 (pgstart)
*
*************************************************************************

*************************************************************************
* Program Section
*
          ORG         $3100         ; program start address in RAM
pgstart   LDS         #pgstart      ; loads stack pointer with address of pgstart
                                    ; initialize stack pointer

          JSR         initialize    ; intialize Port B

mainLoop
          JSR         dimup         ; jump to subroutine, dim from 0% to 100%
          JSR         dimdown       ; jump to subroutine, dim from 100% to 0%
          BRA         mainLoop      ; repeat infintely
*
*************************************************************************
* Subroutines
** -------------------------------------------------------------------------
** INITIALIZE
** Args: Counter_i, A
** Description: initialize port B
initialize
          LDAA        #%11110000    ; set PORT B bit 7-4 as output, and 3-0 as input
          STAA        DDRB          ; LED 1-4 on PORT B bit 4-7
                                    ; DIP switch 1-4 on PORT B bit 0-3
                                    
          BSET        PUCR, %00000010 ; enable PORT B pull-up/down feature for the
                                      ; DIP switch 1-4 on PORT B bits 0-3                                   
          
          LDAA        #%11110000      ; load reg A to set inital states of LEDs
          STAA        PORTB           ; 0=on 1=off, this turns LEDs 4,3,2,1 off
          
          RTS                         ; return to mainLoop
          
* -------------------------------------------------------------------------
** DIMUP
** Args: Counter_i, A
** Description: First, clear Counter_i so that current value of i is 0. Then
**              enter a loop. Inside of the loop, first check to see if i = 101
**              and if it does, then we are done looping. Otherwise, jump into
**              a d50 subroutine (which uses the current value of Counter_i to
**              loop 50 times and execute an i% dim for 1 msec total), come back,
**              decrease i by 1, and branch back to check the status of i again.
dimup
          CLR         Counter_i       ; set i = 0 to loop from 0 to 100

loopdimup
          LDAA        Counter_i       ; A = current i
          CMPA        #100            ; is i == 101?
          BEQ         donedimup       ; if i == 101, stop looping

          JSR         d50             ; dim i% for 1 msec, 50 times
          INC         Counter_i       ; increase i
          BRA         loopdimup       ; loop back

donedimup
          RTS                         ; return to mainLoop
          
** -------------------------------------------------------------------------
** DIMDOWN
** Args: Counter_i, A
** Description: First, set Counter_i so that current value of i is 100. Then
**              enter a loop. Inside of the loop, first check to see if i = 00
**              and if it does, then we are done looping. Otherwise, jump into
**              a d50 subroutine (which uses the current value of Counter_i to
**              loop 50 times and execute an i% dim for 1 msec total), come back,
**              decrease i by 1, and branch back to check the status of i again. 
dimdown
          LDAA        #100            ; load 100 into A
          STAA        Counter_i       ; i = 100
          
loopdimdn
          LDAA        Counter_i       ; A stores current i
          CMPA        #00             ; compare A(i) with 0, i == 0?
          BEQ         donedimdn       ; if i is 0, then we are done looping
          
          JSR         d50             ; dim i% for 1 msec, 50 times
          DEC         Counter_i       ; decrease i
          BRA         loopdimdn       ; loop back
          
donedimdn 
          RTS                         ; return to mainLoop
         
** -------------------------------------------------------------------------
** D50
** Args: Counter_50, A and B
** Description: calls a subroutine (50 times) that dims at i% for 1 msec,
**              it also saves current i to the stack (since it is being stored
**              in A, and A will be used by subroutine dim_i), and then restores it 
d50
          LDAB        #50             ; load 50 to B
          STAB        Counter_50      ; Counter_50 = 50
          PSHA                        ; save value of reg A (current value of i) 
          
loop_50   
          JSR         dim_i           ; jump to subroutine that will dim i% for 1msec
          DEC         Counter_50      ; decreae counter_50
          BNE         loop_50         ; keep looping until counter_50 is 0
          
          PULA                        ; restore current i to A
          STAA        Counter_i       ; restore current i to memory
          
          RTS                         ; return to loopdimup (in dimup) or loopdimdn (in dimdn)

** -------------------------------------------------------------------------
** DIM_I
** Args: Counter_i, A and B
** Description: turn on LED 1 and use B to go from i -> 0 and delay 10usec for each decrement, then
**              turn off LED 1 and use A to go from 100-i -> 0
dim_i
          LDAB      Counter_i         ; store current i in reg B to loop
          CMPB      #00
          BEQ       start_off         ; if i = 0, go straight to 100% of off time       
          
          BCLR      PORTB, %00010000  ; for i > 0, turn on LED 1

delay_i   JSR       delay_10usec      ; delay 10 usec
          DECB                        ; decrease B (i)
          BNE       delay_i           ; is B(i) = 0? no, then keep looping
                                                
          LDAB      Counter_i         ; restore B with current value of i
          LDAA      #100
          CBA                         ; A = A - B = 100 - i
          BEQ       done              ; if 100-i == 0 (i = 100), then don't delay, end subroutine
          
start_off BSET      PORTB, %00010000  ; turn off LED 1
          
delay100_i
          JSR       delay_10usec      ; delay 10 usec
          DECA
          BNE       delay100_i        ; is A(100-i) == 0? no, then keep looping
                                      ; return to d50
done      RTS
        

* -------------------------------------------------------------------------          
* DELAY_10uSEC
* Args: Counter2 and X
*   - Description: delay 1 microsecond.
*   - Input: a 16 bit number in 'Counter2', stored in register X
*   - Output: cpu cycles wasted to delay a few msec.
*   - Registers in use: X register, as counter
*   - Memory locations in use: a 16 bit input number in 'Counter2' originally set to $002F = 47            
            
delay_10usec
            LDX         Counter_10us    ; 10 usec delay
dlyLoop     DEX                         ; decrement X
            BNE         dlyLoop         ; kep looping until counter is 0
            RTS           
*
*************************************************************************



*****************************   End of File   ***************************

            end                     ; last line of a file
            
*************************************************************************