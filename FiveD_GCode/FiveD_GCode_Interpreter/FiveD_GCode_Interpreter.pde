#include <ctype.h>
#include <stdio.h>
#include <HardwareSerial.h>
#include <avr/pgmspace.h>
#include "WProgram.h"
#include "vectors.h"
#include "features.h"
#include "configuration.h"
#include "hostcom.h"
#include "intercom.h"
#include "pins.h"
#include "Temperature.h"
#include "pid.h"
#include "bed.h"
#include "extruder.h"
#include "cartesian_dda.h"

// function prototypes:
void blink();
void dQMove();
void setupTimerInterrupt();
void setTimer(long delay);
void setTimerResolution(byte r);

void setupGcodeProcessor();
void init_process_string();
void cancelAndClearQueue();
void get_and_do_command();
void setupThermistors();

void process_string(char instruction[], int size);

int scan_int(char *str, int *valp, unsigned int *seen, unsigned int flag);
int scan_float(char *str, float *valp, unsigned int *seen, unsigned int flag);
int scan_long(char *str, long *valp, unsigned int *seen, unsigned int flag);


/**

RepRap GCode interpreter.

IMPORTANT

Before changing this interpreter, read this page:

http://objects.reprap.org/wiki/Mendel_User_Manual:_RepRapGCodes

*/


// Sanguino G-code Interpreter
// Arduino v1.0 by Mike Ellery - initial software (mellery@gmail.com)
// v1.1 by Zach Hoeken - cleaned up and did lots of tweaks (hoeken@gmail.com)
// v1.2 by Chris Meighan - cleanup / G2&G3 support (cmeighan@gmail.com)
// v1.3 by Zach Hoeken - added thermocouple support and multi-sample temp readings. (hoeken@gmail.com)
// Sanguino v1.4 by Adrian Bowyer - added the Sanguino; extensive mods... (a.bowyer@bath.ac.uk)
// Sanguino v1.5 by Adrian Bowyer - implemented 4D Bressenham XYZ+ stepper control... (a.bowyer@bath.ac.uk)
// Sanguino v1.6 by Adrian Bowyer - implemented RS485 extruders
// Arduino Mega v1.7 by Adrian Bowyer
// Features code v1.8 by David Bussenschutt July 2010
// Tidying by Adrian September 2011

// Maintain a list of extruders...

extruder* ex[EXTRUDER_COUNT];
byte extruder_in_use = 0;



#if EXTRUDER_CONTROLLER == EXTRUDER_CONTROLLER_DC

// TODO: For some reason, if you declare the following two in the order ex0 ex1 then
// ex0 won't drive its stepper.  They seem fine this way round though.  But that's got
// to be a bug.

#if EXTRUDER_COUNT == 2            
static extruder ex1(EXTRUDER_1_MOTOR_DIR_PIN, EXTRUDER_1_MOTOR_SPEED_PIN , EXTRUDER_1_HEATER_PIN,
              EXTRUDER_1_FAN_PIN,  EXTRUDER_1_TEMPERATURE_PIN, EXTRUDER_1_VALVE_DIR_PIN,
              EXTRUDER_1_VALVE_ENABLE_PIN, EXTRUDER_1_STEP_ENABLE_PIN, E1_STEPS_PER_MM);            
#endif

static extruder ex0(EXTRUDER_0_MOTOR_DIR_PIN, EXTRUDER_0_MOTOR_SPEED_PIN , EXTRUDER_0_HEATER_PIN,
            EXTRUDER_0_FAN_PIN,  EXTRUDER_0_TEMPERATURE_PIN, EXTRUDER_0_VALVE_DIR_PIN,
            EXTRUDER_0_VALVE_ENABLE_PIN, EXTRUDER_0_STEP_ENABLE_PIN, E0_STEPS_PER_MM);
   
#if HEATED_BED == HEATED_BED_ON
static bed heatedBed(BED_HEATER_PIN, BED_TEMPERATURE_PIN);
#endif

#endif // extruder controller


// Standard Mendel, 

#if EXTRUDER_CONTROLLER == EXTRUDER_CONTROLLER_RS485

#if EXTRUDER_COUNT == 2    
static extruder ex1(E1_NAME, E1_STEPS_PER_MM);            
#endif

static extruder ex0(E0_NAME, E0_STEPS_PER_MM);

intercom talker;

#endif // extruder controller


// Arduino Mega and friends

#if EXTRUDER_CONTROLLER == EXTRUDER_CONTROLLER_INTERNAL

#if EXTRUDER_COUNT == 2  

 static PIDcontrol ePID1(EXTRUDER_1_HEATER_PIN, EXTRUDER_1_TEMPERATURE_PIN, false);
 static extruder ex1(&ePID1, EXTRUDER_1_STEP_PIN, EXTRUDER_1_DIR_PIN, EXTRUDER_1_ENABLE_PIN, EXTRUDER_1_HEATER_PIN, EXTRUDER_1_TEMPERATURE_PIN, E1_STEPS_PER_MM);            
#endif

static PIDcontrol ePID0(EXTRUDER_0_HEATER_PIN, EXTRUDER_0_TEMPERATURE_PIN, false);   
static extruder ex0(&ePID0, EXTRUDER_0_STEP_PIN, EXTRUDER_0_DIR_PIN, EXTRUDER_0_ENABLE_PIN, EXTRUDER_0_HEATER_PIN, EXTRUDER_0_TEMPERATURE_PIN, E0_STEPS_PER_MM); 


#if HEATED_BED == HEATED_BED_ON

static bed heatedBed(BED_HEATER_PIN, BED_TEMPERATURE_PIN);

#endif //heated bed


#endif  // extruder controller



static hostcom talkToHost;

// Each entry in the buffer is an instance of cartesian_dda.

cartesian_dda* cdda[BUFFER_SIZE];

static cartesian_dda cdda0;
static cartesian_dda cdda1;
static cartesian_dda cdda2;
static cartesian_dda cdda3;

volatile byte head;
volatile byte tail;
bool led;

word interruptBlink;

// Where the machine is from the point of view of the command stream

FloatPoint where_i_am;

//The coordinates of the last zero positions

LongPoint zeroHit;

// And what we hit

volatile byte endstop_hits;

// Our interrupt function

/*
This has an internal flag (nonest) to prevent its being interrupted by another timer interrupt.
It re-enables interrupts internally (not something that one would normally do with an ISR).
This allows USART interrupts to be serviced while this ISR is also live, and so prevents 
communications errors.
*/

volatile bool nonest;

ISR(TIMER1_COMPA_vect)
{
  if(nonest)
    return;
  nonest = true;
  sei();
  interruptBlink++;
  if(interruptBlink == 0x280)
  {
     blink();
     interruptBlink = 0; 
  }

      
  if(cdda[tail]->active())
      cdda[tail]->dda_step();
  else
      dQMove();
  nonest = false;
}

void setup()
{
  nonest = false;
  endstop_hits = 0;
  disableTimerInterrupt();
  setupTimerInterrupt();
  interruptBlink = 0;
  pinMode(DEBUG_PIN, OUTPUT);
  led = false;
  
  setupThermistors(); // map the correct thermistor table to the correct thermistor ( extruder or bed )
  
  setupGcodeProcessor();
  
  ex[0] = &ex0;
#if EXTRUDER_COUNT == 2  
  ex[1] = &ex1;
#endif  
  extruder_in_use = 0; 
  
  head = 0;
  tail = 0;
  
  cdda[0] = &cdda0;
  cdda[1] = &cdda1;  
  cdda[2] = &cdda2;  
  cdda[3] = &cdda3;
  
  for(byte i = 0; i < 4; i++)
    cdda[i]->set_units(true);
  
  //setExtruder();
  
  init_process_string();
  
  talkToHost.start();
  
  // uncomment this line , upload, and immdiately connect to the "Serial Monitor" to help with exruder and endstop issues
   //validate_hardware(); 
 
 // turn on remote powersupply, if it's possible
#ifdef PS_ON_PIN 
    pinMode(PS_ON_PIN, OUTPUT);  // add to run G3 as built by makerbot
    digitalWrite(PS_ON_PIN, LOW);   // ditto
    unsigned long endTime = millis() + 2000;
      while(millis() < endTime) manage();    
#endif
#if EXTRUDER_CONTROLLER == EXTRUDER_CONTROLLER_RS485
rs485Interface.begin(RS485_BAUD);  
#endif

  setTimer(DEFAULT_TICK);
  enableTimerInterrupt();
}

// This does a hard stop.  It disables interrupts, turns off all the motors 
// (regardless of DISABLE_X etc), and calls extruder.shutdown() for each
// extruder.  It then spins in an endless loop, never returning.  The only
// way out is to press the reset button.

void shutdown()
{
  // No more stepping or other interrupts
  
  cli();
  
  // Delete everything in the ring buffer
  
  cancelAndClearQueue();
  
#if ENABLE_LINES == HAS_ENABLE_LINES
// Motors off
// Note - we ignore DISABLE_X etc here; we are
// definitely turning everything off.
  digitalWrite(X_ENABLE_PIN, !ENABLE_ON);
  digitalWrite(Y_ENABLE_PIN, !ENABLE_ON);
  digitalWrite(Z_ENABLE_PIN, !ENABLE_ON);
#endif

  // Stop the extruders
  
  for(byte i = 0; i < EXTRUDER_COUNT; i++)
    ex[i]->shutdown();

// If we run the bed, turn it off.

#if HEATED_BED == HEATED_BED_ON
  heatedBed.shutdown();
#endif

  
  // LED off
  
  digitalWrite(DEBUG_PIN, 0);
  
  
  // Till the end of time...
  
  for(;;); 
}


// Keep all extruders, bed, up to temperature etc.

void manage()
{
  for(byte i = 0; i < EXTRUDER_COUNT; i++)
    ex[i]->manage();
#if HEATED_BED == HEATED_BED_ON   
  heatedBed.manage();
#endif  
}

//long count = 0;
//int ct1 = 0;

void loop()
{
  nonest = false;
   manage();
   get_and_do_command(); 
#if EXTRUDER_CONTROLLER == EXTRUDER_CONTROLLER_RS485
   talker.tick();
#endif
}

//******************************************************************************************
// checkover the basic settings and report anything unusual? 
void validate_hardware() { 
  
  if (( ENDSTOPS_MIN_ENABLED == 0 ) && (ENDSTOPS_MAX_ENABLED == 0) ) { talkToHost.informational("V: no endstops enabled ( please enable at least one)"); }

        pinMode(X_MIN_PIN, INPUT);
         pinMode(Y_MIN_PIN, INPUT);
       pinMode(Z_MIN_PIN, INPUT);

  
  if (( ENDSTOPS_MIN_ENABLED == 0 ) && (ENDSTOPS_MAX_ENABLED == 0) ) { talkToHost.informational("no endstops enabled ( please enable at least one ot ENDSTOPS_MIN_ENABLED or ENDSTOPS_MAX_ENABLED)"); }

        int e = 2; //invalid default 

	if ( ( ENDSTOP_OPTO_TYPE == ENDSTOP_OPTO_TYPE_INVERTING) && (!digitalRead(X_MIN_PIN)) ) {  talkToHost.informational("X endstop inverted ( change ENDSTOP_OPTO_TYPE to ENDSTOP_OPTO_TYPE_NORMAL ) or sensor triggered"); e = 0; }
	if ( ( ENDSTOP_OPTO_TYPE == ENDSTOP_OPTO_TYPE_NORMAL ) && (digitalRead(X_MIN_PIN)) ) {  talkToHost.informational("X endstop inverted ( change ENDSTOP_OPTO_TYPE to ENDSTOP_OPTO_TYPE_INVERTING ) or sensor triggered"); e = 1;}

	if ( ( ENDSTOP_OPTO_TYPE == ENDSTOP_OPTO_TYPE_INVERTING ) && (!digitalRead(Y_MIN_PIN)) ) {  talkToHost.informational("Y endstop inverted (change ENDSTOP_OPTO_TYPE to ENDSTOP_OPTO_TYPE_NORMAL ) or sensor triggered"); e = 0; }
	if ( ( ENDSTOP_OPTO_TYPE == ENDSTOP_OPTO_TYPE_NORMAL ) && (digitalRead(Y_MIN_PIN)) ) {  talkToHost.informational("Y endstop inverted ( change ENDSTOP_OPTO_TYPE to ENDSTOP_OPTO_TYPE_INVERTING ) or sensor triggered"); e = 1; }

	if ( ( ENDSTOP_OPTO_TYPE == ENDSTOP_OPTO_TYPE_INVERTING ) && (!digitalRead(Z_MIN_PIN)) ) {  talkToHost.informational("Z endstop inverted ( change ENDSTOP_OPTO_TYPE to ENDSTOP_OPTO_TYPE_NORMAL) or sensor triggered"); e = 0; }
	if ( ( ENDSTOP_OPTO_TYPE == ENDSTOP_OPTO_TYPE_NORMAL ) && (digitalRead(Z_MIN_PIN)) ) {  talkToHost.informational("Z endstop IS inverted ( change ENDSTOP_OPTO_TYPE to ENDSTOP_OPTO_TYPE_INVERTING ) or sensor triggered"); e = 1 ; }


         if ( e == 0 || e == 1 ) { 
           talkToHost.informational("HINT:  If your optos are all electrically connected right , and the sensors are not blocked ... then you are geting the above message/s because you have not defined the opto correctly in the configuration.h");
           talkToHost.informational("tThe usual Symptom, if you leave your opto/s incorrectly configured is that XY&Z steppers will only turn one way , but the Extruder stepper will turn either"); 
         }

//        if (  USE_THERMISTOR == 0 ) { talkToHost.informational("not configured to use a thermistor, unlikely! see USE_THERMISTOR constant"); }
        if ( EXTRUDER_COUNT > 1 ) { talkToHost.informational("multiple extruders are setup! Are u sure?  see EXTRUDER_COUNT constant."); }
        
        if ( ENABLE_PIN_STATE == ENABLE_PIN_STATE_INVERTING ) { talkToHost.informational("still not stepping? check ENABLE_PIN_STATE if it should be inverting (it is) "); } 
        

        talkToHost.informational("// X-endstop-pin-raw-reading (X_MIN_PIN): ");talkToHost.informational(int2str(digitalRead(X_MIN_PIN)));
        talkToHost.informational("// Y-endstop-pin-raw-reading (Y_MIN_PIN): ");talkToHost.informational(int2str(digitalRead(Y_MIN_PIN)));
        talkToHost.informational("// Z-endstop-pin-raw-reading (Z_MIN_PIN): ");talkToHost.informational(int2str(digitalRead(Z_MIN_PIN)));
        
        unsigned long endTime = millis() + 1000;
        while(millis() < endTime) manage();
        ex[extruder_in_use]->manage();
        int t = ex[extruder_in_use]->getTemperature();
        talkToHost.informational("temp is ");
        talkToHost.informational(int2str((unsigned long)t));
	if ( t > 250) { talkToHost.informational("Temperature reading is likely invalid ( >250 )");  } 
	if ( t < 5 ) { talkToHost.informational("Temperature reading is likely invalid ( < 5 )");  } 


        talkToHost.informational("Validate done  ( press reset on the arduino/sanguino/mega to re-run ) ");

}
// The move buffer

inline void cancelAndClearQueue()
{
	tail = head;	// clear buffer
	for(int i=0;i<BUFFER_SIZE;i++)
		cdda[i]->shutdown();
}

inline void waitFor_qEmpty()
{
// while waiting maintain the temperatures
  while(!qEmpty()) {
    manage();
  }
}
 
inline void waitFor_qNotFull()
{
// while waiting maintain the temperatures
  while(qFull()) {
    manage();
  }
}

inline bool qFull()
{
  if(tail == 0)
    return head == (BUFFER_SIZE - 1);
  else
    return head == (tail - 1);
}

inline bool qEmpty()
{
   return tail == head && !cdda[tail]->active();
}

inline void qMove(const FloatPoint& p)
{
  waitFor_qNotFull();
  byte h = head; 
  h++;
  if(h >= BUFFER_SIZE)
    h = 0;
  cdda[h]->set_target(p);
  head = h;
}

inline void dQMove()
{
  if(qEmpty())
    return;
  byte t = tail;  
  t++;
  if(t >= BUFFER_SIZE)
    t = 0;
  cdda[t]->dda_start();
  tail = t; 
}

inline void setUnits(bool u)
{
   for(byte i = 0; i < BUFFER_SIZE; i++)
     cdda[i]->set_units(u); 
}


inline void setPosition(const FloatPoint& p)
{
  where_i_am = p;  
}

void blink()
{
  led = !led;
  if(led)
      digitalWrite(DEBUG_PIN, 1);
  else
      digitalWrite(DEBUG_PIN, 0);
} 


//******************************************************************************************

// Interrupt functions

void setupTimerInterrupt()
{
	//clear the registers
	TCCR1A = 0;
	TCCR1B = 0;
	TCCR1C = 0;
	TIMSK1 = 0;
	
	//waveform generation = 0100 = CTC
	TCCR1B &= ~(1<<WGM13);
	TCCR1B |=  (1<<WGM12);
	TCCR1A &= ~(1<<WGM11); 
	TCCR1A &= ~(1<<WGM10);

	//output mode = 00 (disconnected)
	TCCR1A &= ~(1<<COM1A1); 
	TCCR1A &= ~(1<<COM1A0);
	TCCR1A &= ~(1<<COM1B1); 
	TCCR1A &= ~(1<<COM1B0);

	//start off with a slow frequency.
	setTimerResolution(4);
	setTimerCeiling(65535);
}

void setTimerResolution(byte r)
{
	//here's how you figure out the tick size:
	// 1000000 / ((16000000 / prescaler))
	// 1000000 = microseconds in 1 second
	// 16000000 = cycles in 1 second
	// prescaler = your prescaler

	// no prescaler == 0.0625 usec tick
	if (r == 0)
	{
		// 001 = clk/1
		TCCR1B &= ~(1<<CS12);
		TCCR1B &= ~(1<<CS11);
		TCCR1B |=  (1<<CS10);
	}	
	// prescale of /8 == 0.5 usec tick
	else if (r == 1)
	{
		// 010 = clk/8
		TCCR1B &= ~(1<<CS12);
		TCCR1B |=  (1<<CS11);
		TCCR1B &= ~(1<<CS10);
	}
	// prescale of /64 == 4 usec tick
	else if (r == 2)
	{
		// 011 = clk/64
		TCCR1B &= ~(1<<CS12);
		TCCR1B |=  (1<<CS11);
		TCCR1B |=  (1<<CS10);
	}
	// prescale of /256 == 16 usec tick
	else if (r == 3)
	{
		// 100 = clk/256
		TCCR1B |=  (1<<CS12);
		TCCR1B &= ~(1<<CS11);
		TCCR1B &= ~(1<<CS10);
	}
	// prescale of /1024 == 64 usec tick
	else
	{
		// 101 = clk/1024
		TCCR1B |=  (1<<CS12);
		TCCR1B &= ~(1<<CS11);
		TCCR1B |=  (1<<CS10);
	}
}

unsigned int getTimerCeiling(const long& delay)
{
	// our slowest speed at our highest resolution ( (2^16-1) * 0.0625 usecs = 4095 usecs)
	if (delay <= 65535L)
		return (delay & 0xffff);
	// our slowest speed at our next highest resolution ( (2^16-1) * 0.5 usecs = 32767 usecs)
	else if (delay <= 524280L)
		return ((delay / 8) & 0xffff);
	// our slowest speed at our medium resolution ( (2^16-1) * 4 usecs = 262140 usecs)
	else if (delay <= 4194240L)
		return ((delay / 64) & 0xffff);
	// our slowest speed at our medium-low resolution ( (2^16-1) * 16 usecs = 1048560 usecs)
	else if (delay <= 16776960L)
		return ((delay / 256) & 0xffff);
	// our slowest speed at our lowest resolution ((2^16-1) * 64 usecs = 4194240 usecs)
	else if (delay <= 67107840L)
		return ((delay / 1024) & 0xffff);
	//its really slow... hopefully we can just get by with super slow.
	else
		return 65535;
}

byte getTimerResolution(const long& delay)
{
	// these also represent frequency: 1000000 / delay / 2 = frequency in hz.
	
	// our slowest speed at our highest resolution ( (2^16-1) * 0.0625 usecs = 4095 usecs (4 millisecond max))
	// range: 8Mhz max - 122hz min
	if (delay <= 65535L)
		return 0;
	// our slowest speed at our next highest resolution ( (2^16-1) * 0.5 usecs = 32767 usecs (32 millisecond max))
	// range:1Mhz max - 15.26hz min
	else if (delay <= 524280L)
		return 1;
	// our slowest speed at our medium resolution ( (2^16-1) * 4 usecs = 262140 usecs (0.26 seconds max))
	// range: 125Khz max - 1.9hz min
	else if (delay <= 4194240L)
		return 2;
	// our slowest speed at our medium-low resolution ( (2^16-1) * 16 usecs = 1048560 usecs (1.04 seconds max))
	// range: 31.25Khz max - 0.475hz min
	else if (delay <= 16776960L)
		return 3;
	// our slowest speed at our lowest resolution ((2^16-1) * 64 usecs = 4194240 usecs (4.19 seconds max))
	// range: 7.812Khz max - 0.119hz min
	else if (delay <= 67107840L)
		return 4;
	//its really slow... hopefully we can just get by with super slow.
	else
		return 4;
}


// Depending on how much work the interrupt function has to do, this is
// pretty accurate between 10 us and 0.1 s.  At fast speeds, the time
// taken in the interrupt function becomes significant, of course.

// Note - it is up to the user to call enableTimerInterrupt() after a call
// to this function.

inline void setTimer(long delay)
{
	// delay is the delay between steps in microsecond ticks.
	//
	// we break it into 5 different resolutions based on the delay. 
	// then we set the resolution based on the size of the delay.
	// we also then calculate the timer ceiling required. (ie what the counter counts to)
	// the result is the timer counts up to the appropriate time and then fires an interrupt.

        // Actual ticks are 0.0625 us, so multiply delay by 16
        
        delay <<= 4;
        
	setTimerCeiling(getTimerCeiling(delay));
	setTimerResolution(getTimerResolution(delay));
}


void delayMicrosecondsInterruptible(unsigned int us)
{
  // for a one-microsecond delay, simply return.  the overhead
  // of the function call yields a delay of approximately 1 1/8 us.
  if (--us == 0)
    return;

  // the following loop takes a quarter of a microsecond (4 cycles)
  // per iteration, so execute it four times for each microsecond of
  // delay requested.
  us <<= 2;

  // account for the time taken in the preceeding commands.
  us -= 2;

  // busy wait
  __asm__ __volatile__ ("1: sbiw %0,1" "\n\t" // 2 cycles
"brne 1b" : 
  "=w" (us) : 
  "0" (us) // 2 cycles
    );
}


char * int2str( unsigned long num ) {
  static char retnum[21];       // enough for 20 digits plus NUL from a 64-bit uint
  sprintf( retnum, "%ul", num );
  return retnum;
}
