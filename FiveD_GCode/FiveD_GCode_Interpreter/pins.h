#ifndef PINS_H
#define PINS_H

#include "features.h"

#if CPUTYPE == CPUTYPE_ATMEL168

#error The Arduino_168 cannot likely run the 5D GCode interpreter

/****************************************************************************************
* Old Arduino168 pin assignment - left here as they might be useful
****************************************************************************************/

#define X_STEP_PIN (byte)2
#define X_DIR_PIN (byte)3
#define X_MIN_PIN (byte)4
#define X_MAX_PIN (byte)9

#define Y_STEP_PIN (byte)10
#define Y_DIR_PIN (byte)7
#define Y_MIN_PIN (byte)8
#define Y_MAX_PIN (byte)13

#define Z_STEP_PIN (byte)19
#define Z_DIR_PIN (byte)18
#define Z_MIN_PIN (byte)17
#define Z_MAX_PIN (byte)16


//extruder pins
#define EXTRUDER_0_MOTOR_SPEED_PIN  (byte)11
#define EXTRUDER_0_MOTOR_DIR_PIN    (byte)12
#define EXTRUDER_0_HEATER_PIN       (byte)6
#define EXTRUDER_0_FAN_PIN          (byte)5
#define EXTRUDER_0_TEMPERATURE_PIN  (byte)0  // Analogue input
#define EXTRUDER_0_VALVE_DIR_PIN             (byte)16       //NB: Conflicts with Max Z!!!!
#define EXTRUDER_0_VALVE_ENABLE_PIN          (byte)15 
#define EXTRUDER_0_STEP_ENABLE_PIN  5 // 5 - NB conflicts with the fan; set -ve if no stepper

//incase a user puts a STEPPER extruder on a Darwin, this makes the pin assignments equivalent:
#if EXTRUDER_CONTROLLER == EXTRUDER_CONTROLLER_INTERNAL
#define EXTRUDER_0_STEP_PIN EXTRUDER_0_MOTOR_SPEED_PIN
#define EXTRUDER_0_DIR_PIN EXTRUDER_0_MOTOR_DIR_PIN
#define EXTRUDER_0_ENABLE_PIN EXTRUDER_0_STEP_ENABLE_PIN
#endif

#define DEBUG_PIN        0

/****************************************************************************************
* Sanguino/RepRap Motherboard with a direct-connected stepper extruder, and NOT a RS485 connected "extruder controller".
* note: most likely, if you are using an "Extruder Controller" PCB, you want the NEXT set of definitions, not this one. 
*
****************************************************************************************/
#elif (CPUTYPE == CPUTYPE_SANGUINO) && (EXTRUDER_CONTROLLER == EXTRUDER_CONTROLLER_INTERNAL)

#ifndef __AVR_ATmega644P__
#error Oops!  Make sure you have 'Sanguino' selected from the 'Tools -> Boards' menu.
#endif

#define DEBUG_PIN        0


#define STEPPER_BOARD STEPPER_DRIVER_TWO_POINT_THREE


#if STEPPER_BOARD == STEPPER_DRIVER_TWO_POINT_THREE
// Standard RepRap Stepper Driver v. 2.3 pin defs


#define X_STEP_PIN (byte)15
#define X_DIR_PIN (byte)18
#define X_MIN_PIN (byte)20
#define X_MAX_PIN (byte)21
#define X_ENABLE_PIN (byte)19

#define Y_STEP_PIN (byte)23
#define Y_DIR_PIN (byte)22
#define Y_MIN_PIN (byte)25
#define Y_MAX_PIN (byte)26
#define Y_ENABLE_PIN (byte)19

#define Z_STEP_PIN (byte)29
#define Z_DIR_PIN (byte)30
#define Z_MIN_PIN (byte)2
#define Z_MAX_PIN (byte)1
#define Z_ENABLE_PIN (byte)31

#endif

#if STEPPER_BOARD != STEPPER_DRIVER_TWO_POINT_THREE
#error The only pre-configured stepper driver pinout for Gen3 is the STEPPER_DRIVER_TWO_POINT_THREE board.
#endif

// Heated bed - TODO: reassign these

#define BED_HEATER_PIN (byte)3
#define BED_TEMPERATURE_PIN (byte)1 


//extruder pins
#define EXTRUDER_0_MOTOR_SPEED_PIN   (byte)12
#define EXTRUDER_0_MOTOR_DIR_PIN     (byte)16
#define EXTRUDER_0_HEATER_PIN        (byte)14
#define EXTRUDER_0_FAN_PIN           (byte)3
#define EXTRUDER_0_TEMPERATURE_PIN  (byte)4    // Analogue input
#define EXTRUDER_0_VALVE_DIR_PIN     (byte)17
#define EXTRUDER_0_VALVE_ENABLE_PIN  (byte)13  // Valve needs to be redesigned not to need this
#define EXTRUDER_0_STEP_ENABLE_PIN  (byte)3  // 3 - Conflicts with the fan; set -ve if no stepper

#define EXTRUDER_1_MOTOR_SPEED_PIN   (byte)4
#define EXTRUDER_1_MOTOR_DIR_PIN    (byte)0
#define EXTRUDER_1_HEATER_PIN        (byte)24
#define EXTRUDER_1_FAN_PIN           (byte)7
#define EXTRUDER_1_TEMPERATURE_PIN  (byte)3  // Analogue input
#define EXTRUDER_1_VALVE_DIR_PIN    (byte) 6
#define EXTRUDER_1_VALVE_ENABLE_PIN (byte)5   // Valve needs to be redesigned not to need this 
#define EXTRUDER_1_STEP_ENABLE_PIN  (byte)-1  // 7 - Conflicts with the fan; set -ve if no stepper


/****************************************************************************************
* RepRap "Gen 3" Motherboard with RS485 Extruder Controller and SDA/SCL wired to D9(DIR) & D10(STEP)
*   TIP: This is a "typical Gen3" setup .
****************************************************************************************/

#elif (CPUTYPE == CPUTYPE_SANGUINO) && (EXTRUDER_CONTROLLER == EXTRUDER_CONTROLLER_RS485)

#ifndef __AVR_ATmega644P__
#error Oops!  Make sure you have 'Sanguino' selected from the 'Tools -> Boards' menu.
#endif

#define STEPPER_BOARD STEPPER_DRIVER_TWO_POINT_THREE

#if STEPPER_BOARD == STEPPER_DRIVER_TWO_POINT_THREE
// Standard RepRap Stepper Driver v. 2.3 pin defs


//x axis pins
#define X_STEP_PIN      15
#define X_DIR_PIN       18
#define X_ENABLE_PIN    19
#define X_MIN_PIN       20
#define X_MAX_PIN       21

//y axis pins
#define Y_STEP_PIN      23
#define Y_DIR_PIN       22
#define Y_ENABLE_PIN    24
#define Y_MIN_PIN       25
#define Y_MAX_PIN       26

//z axis pins
#define Z_STEP_PIN      27
#define Z_DIR_PIN       28
#define Z_ENABLE_PIN    29
#define Z_MIN_PIN       30
#define Z_MAX_PIN       31

#endif

#if STEPPER_BOARD != STEPPER_DRIVER_TWO_POINT_THREE
#error The only pre-configured steppr driver pinout for Gen3 is the STEPPER_DRIVER_TWO_POINT_THREE board.
#endif

#define E_STEP_PIN      17
#define E_DIR_PIN       16

//our pin for debugging.

#define DEBUG_PIN        0

//our SD card pins
#define SD_CARD_WRITE    2
#define SD_CARD_DETECT   3
#define SD_CARD_SELECT   4

//our RS485 pins
#define TX_ENABLE_PIN	12
#define RX_ENABLE_PIN	13

//pin for controlling the PSU.
#define PS_ON_PIN       14

/****************************************************************************************
* Typical Arduino Mega + Pololu Board Setup
*  ( using directly controlled extruder stepper, not RS485)
* THere are three pre-configured pinouts, if you want yours added, please let us know.
****************************************************************************************/

#elif (CPUTYPE == CPUTYPE_MEGA) && (EXTRUDER_CONTROLLER == EXTRUDER_CONTROLLER_INTERNAL)

#ifndef __AVR_ATmega1280__
 #ifndef __AVR_ATmega2560__
  #error Oops!  Make sure you have 'Arduino Mega' selected from the 'Tools -> Boards' menu.
 #endif
#endif

#if STEPPER_BOARD == ADRIAN_POLOLU_STRIPBOARD
/*
  Pin definitions for the Pololu stripboard design here:
  
  http://reprap.org/wiki/Pololu_Electronics#Making_the_electronics_using_stripboard
*/

#define DEBUG_PIN        13

#define X_STEP_PIN (byte)48
#define X_DIR_PIN (byte)47
#define X_MIN_PIN (byte)45
#define X_MAX_PIN (byte)21
#define X_ENABLE_PIN (byte)46

#define Y_STEP_PIN (byte)43
#define Y_DIR_PIN (byte)42
#define Y_MIN_PIN (byte)44
#define Y_MAX_PIN (byte)26
#define Y_ENABLE_PIN (byte)40

#define Z_STEP_PIN (byte)35
#define Z_DIR_PIN (byte)34
#define Z_MIN_PIN (byte)37
#define Z_MAX_PIN (byte)1
#define Z_ENABLE_PIN (byte)33

// Heated bed

#define BED_HEATER_PIN (byte)3
#define BED_TEMPERATURE_PIN (byte)1 


//extruder pins

#define EXTRUDER_0_STEP_PIN (byte)30
#define EXTRUDER_0_DIR_PIN (byte)15
#define EXTRUDER_0_ENABLE_PIN (byte)14
#define EXTRUDER_0_HEATER_PIN (byte)2
#define EXTRUDER_0_TEMPERATURE_PIN (byte)0 

#define EXTRUDER_1_STEP_PIN (byte)4
#define EXTRUDER_1_DIR_PIN (byte)5
#define EXTRUDER_1_ENABLE_PIN (byte)6
#define EXTRUDER_1_HEATER_PIN (byte)13
#define EXTRUDER_1_TEMPERATURE_PIN (byte)2 


#endif //adrian pololu stripboard



//HSBNE: 
#if STEPPER_BOARD == HSBNE_POLOLU_PCB

#define DEBUG_PIN 13

//CHAN 1
#define X_STEP_PIN (byte)51  //was 36
#define X_DIR_PIN (byte)53  //was 23
#define X_MIN_PIN (byte)4 // 20
#define X_MAX_PIN (byte)3 //21
#define X_ENABLE_PIN (byte)49  //was 24

//CHAN 2
#define Y_STEP_PIN (byte)43 //was 34
#define Y_DIR_PIN (byte)45  //was 29
#define Y_ENABLE_PIN (byte)41  //was 39
#define Y_MIN_PIN (byte)5 //25
#define Y_MAX_PIN (byte)3 //26

//CHAN 3
#define Z_STEP_PIN (byte)42 //was 25
#define Z_DIR_PIN (byte)44  //was 26
#define Z_MIN_PIN (byte)6 //2
#define Z_MAX_PIN (byte)3 //1
#define Z_ENABLE_PIN (byte)40 //was 27


// Heated bed

#define BED_HEATER_PIN (byte)10
#define BED_TEMPERATURE_PIN (byte)1 


//extruder pins
#define EXTRUDER_0_STEP_PIN (byte)48 //26
#define EXTRUDER_0_DIR_PIN (byte)50 //28
#define EXTRUDER_0_ENABLE_PIN (byte)46 //30

#define EXTRUDER_0_HEATER_PIN (byte)9
#define EXTRUDER_0_TEMPERATURE_PIN (byte)4 


#endif  //HSBNE



#if STEPPER_BOARD == ADRIAN_POLOLU_PCB

/*
  Pin definitions for the Pololu PCB design here:
  
  http://reprap.org/wiki/Pololu_Electronics#Simple_PCBs
*/

#define DEBUG_PIN        13

#define X_STEP_PIN (byte)51
#define X_DIR_PIN (byte)53
#define X_MIN_PIN (byte)47
#define X_MAX_PIN (byte)-1
#define X_ENABLE_PIN (byte)49

#define Y_STEP_PIN (byte)43
#define Y_DIR_PIN (byte)45
#define Y_MIN_PIN (byte)39
#define Y_MAX_PIN (byte)-1
#define Y_ENABLE_PIN (byte)41

#define Z_STEP_PIN (byte)42
#define Z_DIR_PIN (byte)44
#define Z_MIN_PIN (byte)38
#define Z_MAX_PIN (byte)-1
#define Z_ENABLE_PIN (byte)40

// Heated bed

#define BED_HEATER_PIN (byte)3
#define BED_TEMPERATURE_PIN (byte)1 


//extruder pins

#define EXTRUDER_0_STEP_PIN (byte)48
#define EXTRUDER_0_DIR_PIN (byte)50
#define EXTRUDER_0_ENABLE_PIN (byte)46
#define EXTRUDER_0_HEATER_PIN (byte)2
#define EXTRUDER_0_TEMPERATURE_PIN (byte)0 

#define EXTRUDER_1_STEP_PIN (byte)4
#define EXTRUDER_1_DIR_PIN (byte)5
#define EXTRUDER_1_ENABLE_PIN (byte)6
#define EXTRUDER_1_HEATER_PIN (byte)13
#define EXTRUDER_1_TEMPERATURE_PIN (byte)2 

#endif

#if STEPPER_BOARD == ULTIMACHINE_PCB
// Johnny's pin defs in here...
#error sorry, the ULTIMACHINE_PCB STEPPER_BOARD type is known, but pin assignments are not. 
#endif

#if STEPPER_BOARD == STEPPER_DRIVER_TWO_POINT_THREE
// Standard RepRap Stepper Driver v. 2.3 pin defs are in the MENDEL_GEN3_DEFAULTS section.
// If perchance you are using a Arduino Mega CPU, but are using Gen3 stepper drivers, then copy the pinouts from there to here.
#error Using STEPPER_DRIVER_TWO_POINT_THREE with a Mega CPU is not currently supported, but if you REALLY meant to configure it this way, it should be easy to do.
#endif

#ifndef STEPPER_BOARD
#error sorry, on the Mega, you must define a STEPPER_BOARD type, with pin assignments, etc.
#endif

/****************************************************************************************
*  ANY OTHER TYPICAL MACHINE PINOUTS CAN GO HERE.
****************************************************************************************/
//#elif (CPUTYPE == CPUTYPE_XXXX) && (EXTRUDER_CONTROLLER == EXTRUDER_CONTROLLER_INTERNAL)


#else

#error Unknown CPUTYPE value in pins.h  Please add your setup, and let us know, so we  can add it.  join the list: reprap-dev@lists.reprap.org


#endif

#endif
