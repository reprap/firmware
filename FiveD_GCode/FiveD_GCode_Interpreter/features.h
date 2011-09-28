#ifndef FEATURES_H
#define FEATURES_H
//-----------------------------------------------------------------------------------------------
// Features:   
//  Each of these defines relates specifically to a component electronic or hardware function or 
//     capability that may or may not exist in your particular machine.
//  You should select which of these are used in your instance, in configuration.h
//-----------------------------------------------------------------------------------------------

//NONE OF THESE CONSTANTS NEED EVER BE CHANGED IN HERE! ( only ever added to!) 

// TIP: We used to specify a "MOTHERBOARD" type, but that was too limiting on users with "custom" setup/s, 
//      so now we identify a machine by what "features" ( ie capabilities ) it has enabled/connected.
//      and enable different parts of the code on-demand for the given requested "feature set"
// TIP2: Send your machine a M115 M-CODE  to get the compiled-in feaure-set from it.   if it doesn't return 
//       info, it's a pre October 2010 "MOTHERBOARD" based firmware.


#define REVISION "1.8"  // arbitrary, based on comets in top of main file...

// definitions for M115 machine capabilities command, see http://reprap.org/wiki/M115_Keywords
#define xstr(s) str(s)
#define str(s) #s
#define PROTOCOL_VERSION "0.1"	// Make sure you really are compliant with what you advertize here

#define FIRMWARE_NAME "FiveD"	// Please change this name if you fork the codebase
#define FIRMWARE_URL "http%3A//reprap.org"	// Escape any colons as %3A
#define MACHINE_TYPE "Mendel"	// Set to whatever bot you have, could be Darwin, Huxley, or Custom, etc.
#define FIRMWARE_VERSION "20101023"	// Need to autoupdate this from svn or git.  FIXME.



//eg:
// #define DEFAULTS  MENDEL_GEN3_DEFAULTS   // setup the pinouts and opts to match a typical Mendel setup with typical wiring, and typical pinouts etc
#define DARWIN_DEFAULTS 1
#define MENDEL_GEN3_DEFAULTS 2
#define MENDEL_MEGA_DEFAULTS 3
#define MAKERBOT_DEFAULTS 4
#define BATHPROTO_DEFAULTS 5
#define CUSTOM_DEFAULTS 6


///#define EXTRUDER_CONTROLLER EXTRUDER_CONTROLLER_RS485   //  means the extruder has its own controller that we talk to via RS485, 0 means it uses the integrated PID logic. 

  #define EXTRUDER_CONTROLLER_RS485 1     // separate extruder temperature management logic on another CPU.
  #define EXTRUDER_CONTROLLER_INTERNAL 2  // stepper driven extruder on master CPU
  #define EXTRUDER_CONTROLLER_DC 3        // DC extruder like makerbot
  

 //eg: 
//#define CPUTYPE CPUTYPE_SANGUINO  //or MEGA, or ATMEL328 , or ATLEM168 ( describes the core CPU, how many pins, what types, and likely connection/s)

  #define CPUTYPE_ATMEL168 1
  #define CPUTYPE_SANGUINO 2
  #define CPUTYPE_MEGA 3
  #define CPUTYPE_ATMEL328 4
 // #define CPU_EMC2  5 // this is just a theoretical one at this time
 
 //#define BELT_PULLEY_TYPE MENDEL_8_TOOTH_ORIGINAL
 #define MENDEL_8_TOOTH_ORIGINAL 1
 #define MENDEL_9_TOOTH_NEWER 2
 #define MENDEL_13_TOOTH 3


 // extruders can be "fast heat" or "slow heat" types
 //#if EXTRUDER_THERMAL_MASS == EXTRUDER_THERMAL_MASS_LARGE
 #define EXTRUDER_THERMAL_MASS_LARGE 1
 #define EXTRUDER_THERMAL_MASS_SMALL 2

/*   NOT YET USED  
  //eg:
//#define POSITIONING_HARDWARE POSITIONING_HARDWARE_MENDEL_STYLE // what style XYZ positioning system do you use?

   #define POSITIONING_HARDWARE_DARWIN_STYLE 1
   #define POSITIONING_HARDWARE_MENDEL_STYLE 2 
   #define POSITIONING_HARDWARE_MAKERBOT_STYLE 3
   #define POSITIONING_HARDWARE_CNC_STYLE 4
  // #define POSITIONING_HARDWARE_MOVINGGANTRY_STYLE 5  // this is just a theoretical one at this time
  // #define CUSTOM 6 // this is just a theoretical one at this time

*/
   // there a a number of different wirings for the pololus and stepper-sub-boards, so we'll name them:
   //#if STEPPER_BOARD == ADRIAN_POLOLU_PCB
   #define ADRIAN_POLOLU_STRIPBOARD 1   // see: http://reprap.org/wiki/Pololu_Electronics#Making_the_electronics_using_stripboard
   #define ADRIAN_POLOLU_PCB 2
   #define ULTIMACHINE_PCB 3
   #define HSBNE_POLOLU_PCB 4
   #define STEPPER_DRIVER_TWO_POINT_THREE 5 // see: http://reprap.org/wiki/Stepper_Motor_Driver_2.3

// eg
//#define MOVEMENT_TYPE MOVEMENT_TYPE_STEP_DIR  // when sending signals to the drivers, what electrical/logical interface will we use? - there are a number of possible different hardware methods for getting directional movement, here we decide which one we want to use normally:  

  #define MOVEMENT_TYPE_STEP_DIR 1      // standard step & direction information, recommended
  #define MOVEMENT_TYPE_GRAY_CODE 2     // also called quadrature stepping, less popular but basically same quality as above
  #define MOVEMENT_TYPE_UNMANAGED_DC 3  //open-ended DC motor using timer or PWM. typically low res, perhaps use for Z axis or Makerbot Extruder , and only if you must. 
  #define MOVEMENT_TYPE_ENCODER_MANAGED_DC 4// closed-loop DC motor who's position is maintained by an opto or magneto encoder generating edges on an external imterrupt line. ?

// eg:
//#define STEPPER_TYPE STEPPER_TYPE_LIN_4118S // only really relevant if STEP_TYPE == 0 or 1

  #define STEPPER_TYPE_LIN_4118S  1  // http://www.reprap.org/wiki/StepperMotor#Lin_Engineering_.2F_4118S-62-07
  #define STEPPER_TYPE_ZAPP_SY42 2
  #define STEPPER_TYPE_NANOTEC_ST57 3
  #define STEPPER_TYPE_OSXMODS17_62 4   //  http://ausxmods.com.au/stepper-motors/62-oz-in-nema-17-stepper-motor


// eg: 
//#define ENDSTOP_OPTO_TYPE  ENDSTOP_OPTO_TYPE_OES2_1 

  #define ENDSTOP_OPTO_TYPE_NORMAL 0
  #define ENDSTOP_OPTO_TYPE_INVERTING 1
  #define ENDSTOP_OPTO_TYPE_OES1_0 ENDSTOP_OPTO_TYPE_NORMAL    //  http://make.rrrf.org/oes-1.0
  #define ENDSTOP_OPTO_TYPE_OES2_1 ENDSTOP_OPTO_TYPE_INVERTING    //  http://reprap.org/wiki/OptoEndstop_2_1   - reprap Opto End Stop circuit revision 2.1  
  #define ENDSTOP_OPTO_TYPE_H21LOI ENDSTOP_OPTO_TYPE_NORMAL
  #define ENDSTOP_OPTO_TYPE_H21LOB ENDSTOP_OPTO_TYPE_INVERTING
  #define ENDSTOP_OPTO_TYPE_HSBNE_OMRON ENDSTOP_OPTO_TYPE_INVERTING //HSBNE Mendel
  #define ENDSTOP_OPTO_TYPE_YOUR_TYPE ENDSTOP_OPTO_TYPE_INVERTING // if you have a published circuit  
  
  //eg:
  //#define ENABLE_PIN_STATE  ENABLE_PIN_STATE_NORMAL
  
  #define ENABLE_PIN_STATE_NORMAL 0
  #define ENABLE_PIN_STATE_INVERTING 1
// Set to 1 if enable pins are inverting
// For RepRap stepper boards version 1.x the enable pins are *not* inverting.
// For RepRap stepper boards version 2.x and above the enable pins are inverting.
// OLD variable was:
// #define INVERT_ENABLE_PINS 0


// is this machine capable of enabling/disabling each of its AXES? 
//  #if ENABLE_LINES == HAS_ENABLE_LINES
  #define  HAS_NO_ENABLE_LINES 0 
  #define  HAS_ENABLE_LINES 1
/*  #define X_ENABLE_CAPABLE 0
  #define Y_ENABLE_CAPABLE 1
  #define Z_ENABLE_CAPABLE 2  
  #define E0_ENABLE_CAPABLE 3  
  #define E1_ENABLE_CAPABLE 4  
*/  
//eg:
// #define TEMP_SENSOR TEMP_SENSOR_EPCOS_THERMISTOR
  
 #define TEMP_SENSOR_EPCOS540_THERMISTOR 1  //see: http://reprap.org/wiki/Thermistor
 #define TEMP_SENSOR_EPCOS560_THERMISTOR 2  //see: http://reprap.org/wiki/Thermistor
 #define TEMP_SENSOR_RRRF100K_THERMISTOR 3  //see: http://reprap.org/wiki/Thermistor
 #define TEMP_SENSOR_RRRF10K_THERMISTOR 4  //see: http://reprap.org/wiki/Thermistor
 #define TEMP_SENSOR_RS10K_THERMISTOR 5  //see: http://reprap.org/wiki/Thermistor
 #define TEMP_SENSOR_RS100K_THERMISTOR TEMP_SENSOR_EPCOS540_THERMISTOR  // different names for the same thing.
 #define TEMP_SENSOR_AD595_THERMOCOUPLE  6 // see: http://reprap.org/wiki/Thermocouple_Sensor_1.0
 #define TEMP_SENSOR_MAX6675_THERMOCOUPLE 7 // see: http://reprap.org/wiki/Hacks_to_the_RepRap_Extruder_Controller_v2.2
 #define TEMP_JAYCAR_NTC_125DEG_10K_THERMISTOR 8 // see: http://www.jaycar.com.au/productView.asp?ID=RN3440&keywords=thermistor&form=KEYWORD

// #define DATA_SOURCE DATA_SOURCE_USB_SERIAL

#define DATA_SOURCE_USB_SERIAL 1
#define DATA_SOURCE_SDCARD 2   // is there an SD card reader present?   
//#define DATA_SOURCE_EPROM 3   // this is just a theoretical one at this time


//eg:
//#define ACCELERATION  ACCELERATION_ON
#define ACCELERATION_ON 1
#define ACCELERATION_OFF 0

//eg:
//#define HEATED_BED HEATED_BED_ON

#define HEATED_BED_ON 1
#define HEATED_BED_OFF 0

//eg: #define THERMAL_CONTROL THERMAL_CONTROL_PID
    #define THERMAL_CONTROL_PID 1     //more accurate but P,I,D values may need tweaking
	#define THERMAL_CONTROL_SIMPLE 2  //BANG-BANG control. If temp is over requested turn off, if below, turn on.

//-----------------------------------------------------------------------------------------------
// IMMUTABLE (READONLY) CONSTANTS GO HERE:
//-----------------------------------------------------------------------------------------------
// The width of Henry VIII's thumb (or something).
#define INCHES_TO_MM 25.4 // *RO

// The temperature routines get called each time the main loop
// has gone round this many times
#define SLOW_CLOCK 2000

// The speed at which to talk with the host computer; default is 19200=
#define HOST_BAUD 19200 // *RO

// The number of mm below which distances are insignificant (one tenth the
// resolution of the machine is the default value).
#define SMALL_DISTANCE 0.01 // *RO

// Useful to have its square
#define SMALL_DISTANCE2 (SMALL_DISTANCE*SMALL_DISTANCE) // *RO

//our command string length
#define COMMAND_SIZE 128 // *RO

// Our response string length
#define RESPONSE_SIZE 256 // *RO

// The size of the movement buffer
#define BUFFER_SIZE 4 // *RO

// Number of microseconds between timer interrupts when no movement
// is happening
#define DEFAULT_TICK (long)1000 // *RO

// What delay value to use when waiting for things to free up in milliseconds
#define WAITING_DELAY 1 // *RO

// Bit flags for hit endstops

#define X_LOW_HIT 1
#define Y_LOW_HIT 2
#define Z_LOW_HIT 4
#define X_HIGH_HIT 8
#define Y_HIGH_HIT 16
#define Z_HIGH_HIT 32

// Not sure if this is the best place for...

extern volatile byte endstop_hits;

#endif



