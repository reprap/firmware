

#ifndef CONFIGURATION_H
#define CONFIGURATION_H

#define MY_NAME '0'          // One byte string representing the name of this device

#define RS485_MASTER 0       // We are a slave

#define MOTHERBOARD 2

// Temperature measurement
// Uncomment ONE of the next three
#define USE_THERMISTOR
//#define AD595_THERMOCOUPLE
//#define MAX6675_THERMOCOUPLE

// Uncomment the next line if this is driving a paste extruder
//#define PASTE_EXTRUDER


/*

*** EXPERIMENTAL
 This drives the stepper PWM at high frequency.  This is quieter and works best for low 
 currents.  But it needs to be debugged, sol leave it commented out unless you're experimenting. 

 ***NOTE*** 
 If set, FAST_PWM changes the frequency of Timer 0 so that PWM on pins H1E and H2E goes at
 a very high frequency (64kHz see: 
 http://tzechienchu.typepad.com/tc_chus_point/2009/05/changing-pwm-frequency-on-the-arduino-diecimila.html)
 This will mess up timings in the delay() and similar functions; they will no longer work in
 milliseconds, but 64 times faster.
 */
//#define FAST_PWM

//******************************************************************************************************

// Divide by this to correct for the fact that we have
// messed up the timer clock

#ifdef FAST_PWM
#define MILLI_CORRECTION 64
#else
#define MILLI_CORRECTION 1
#endif

// The temperature routines get called each time the main loop
// has gone round this many times

#define SLOW_CLOCK 5000

// Default pwm for the stepper motor

#define STEP_PWM 140

// Pin defintion section.  This is for the RepRap Extruder Controler V2.2

//our RS485 pins

#define RX_ENABLE_PIN 4
#define TX_ENABLE_PIN 16

// Pins to direct-drive the extruder stepper

#define E_STEP_PIN 10
#define E_DIR_PIN 9

#ifdef MAX6675_THERMOCOUPLE
// I2C pins for the MAX 6675 temperature chip
 #define SO 18    // MISO
 #define SCK 19   // Serial Clock
 #define TC_0 17  // CS Pin of MAX6607
#else
 #define TEMP_PIN 3
 #define BED_TEMP_PIN 6
#endif

// The heated bed thermistor

#define BED_TEMP 6

// Control pins for the A3949 chips

#define H1D 7
#define H1E 5
#define H2D 8
#define H2E 6

// Analogue read of this pin gets the potentiometer setting

#define POT 0

// MOSFET drivers

#define BED_OUTPUT 15
#define FAN_OUTPUT 11
#define HEATER_OUTPUT 12

#define DEBUG_PIN 13

#ifdef PASTE_EXTRUDER
#define OPTO_PIN 10
#endif;

// The LED blink function

extern void blink(bool on);

#endif
