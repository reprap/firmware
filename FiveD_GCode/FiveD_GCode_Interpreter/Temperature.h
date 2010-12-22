#ifndef TEMPERATURE_H
#define TEMPERATURE_H

// HINT: To decide which Thermistor/s are used, you no longer need to change this file!
// please just change the two definitions in your configuration.h file that are:
//  TEMP_SENSOR       ( choose what to set it to based on the options in features.h )
//  BED_TEMP_SENSOR    ( as per above, or leave it unset, and it will automatically be set the same as TEMP_SENSOR )
//
// Developers please note:   the "Tables" defined in this .h file are arbitrarily identified by unique prefixes 
// such as a_  and b_, etc.  this is so that you can use a different temperature table for your extruder
// and your heated bed.  ( or perhaps use a thermocouple of one, and a thermistor on the other ). 
//  If you add your own "Table", please give it a unique prefix, following the existing conventions below
//    ( and update setupThermistors() function too )

// The temperature control dead zone in deg C

#define HALF_DEAD_ZONE 5

// ie max6675 or AD595 or similar  we just declare a dummy :
#ifndef USE_THERMISTOR 
short temptable[0][2] = { };
short bedtemptable[0][2] = { };
#endif 

// now we can ignore the rest of this file unless we are using a thermistor somewhere! 
#ifdef USE_THERMISTOR

// theoretically we could change this number on a per-thermistor basis, 
//but in reality this is a fixed constant that applies to both thermistor/s you use.  
#define NUMTEMPS 20

// convenience typedefs
typedef short Pair[2];
typedef Pair Table[NUMTEMPS]; 

// for direct PIC temperature control of the extruder without a separate extruder CPU, we define the 
// thermistor table/s we want to use in this file.
#if ( EXTRUDER_CONTROLLER == EXTRUDER_CONTROLLER_INTERNAL )  || ( EXTRUDER_CONTROLLER == EXTRUDER_CONTROLLER_DC ) 
Pair *temptable; // a pointer to the first "Pair" is equivalient to a "Table" type, but conveniently modifiable.
#endif 


// ... And this is the heated bed thermistor (if any)
#if HEATED_BED == HEATED_BED_ON 
Pair *bedtemptable; 
#endif


// using "Jaycar 125deg 10k thermistor" and 4.7k R  ( not  temperature rated for extruder/s, heated bed only)
#if TEMP_SENSOR == TEMP_JAYCAR_NTC_125DEG_10K_THERMISTOR ||  BED_TEMP_SENSOR == TEMP_JAYCAR_NTC_125DEG_10K_THERMISTOR

Table a_temptable = {
	{1, 599},
	{40, 130},
	{60, 120},
	{81, 110},
	{106, 100},
	{133, 90},
	{177, 80},
	{235, 70},
	{295, 60},
	{346, 55},
	{373, 50},
	{309, 45},
	{451, 43},
	{490, 37},
	{637, 31},
	{690, 25},
	{743, 19},
	{796, 12},
	{849, 5},
    {999, 0}
};


#endif 


// "RS 10k thermistor" RS Part: 484-0149; EPCOS B57550G103J
// Made with createTemperatureLookup.py (http://svn.reprap.org/trunk/reprap/firmware/Arduino/utilities/createTemperatureLookup.py)
// ./createTemperatureLookup.py --r0=10000 --t0=25 --r1=0 --r2=4700 --beta=3480 --max-adc=1023
// r0: 10000
// t0: 25
// r1: 0
// r2: 4700
// beta: 3480
// max adc: 1023
#if TEMP_SENSOR == TEMP_SENSOR_RS10K_THERMISTOR || BED_TEMP_SENSOR == TEMP_SENSOR_RS10K_THERMISTOR
Table b_temptable = {
   {1, 599},
   {54, 160},
   {107, 123},
   {160, 103},
   {213, 90},
   {266, 79},
   {319, 70},
   {372, 62},
   {425, 55},
   {478, 49},
   {531, 43},
   {584, 37},
   {637, 31},
   {690, 25},
   {743, 19},
   {796, 12},
   {849, 5},
   {902, -3},
   {955, -16},
   {1008, -42}
};

#endif

 

 
// "RS 100k thermistor" Rs Part: 528-8592; "EPCOS NTC G540" B57540G0104J
// ./createTemperatureLookup.py --r0=100000 --t0=25 --r1=0 --r2=4700 --beta=4036 --max-adc=1023
// r0: 100000
// t0: 25
// r1: 0
// r2: 4700
// beta: 4036
// max adc: 1023
#if TEMP_SENSOR == TEMP_SENSOR_EPCOS540_THERMISTOR || BED_TEMP_SENSOR == TEMP_SENSOR_EPCOS540_THERMISTOR
Table c_temptable = {
   {1, 864},
   {54, 258},
   {107, 211},
   {160, 185},
   {213, 168},
   {266, 154},
   {319, 143},
   {372, 133},
   {425, 125},
   {478, 116},
   {531, 109},
   {584, 101},
   {637, 94},
   {690, 87},
   {743, 79},
   {796, 70},
   {849, 61},
   {902, 50},
   {955, 34},
   {1008, 2}
};

#endif


// RRRF 100K Thermistor 
// ./createTemperatureLookup.py --r0=100000 --t0=25 --r1=0 --r2=4700 --beta=3960 --max-adc=1023
// r0: 100000
// t0: 25
// r1: 0
// r2: 4700
// beta: 3960
// max adc: 1023
#if TEMP_SENSOR == TEMP_SENSOR_RRRF100K_THERMISTOR || BED_TEMP_SENSOR == TEMP_SENSOR_RRRF100K_THERMISTOR
Table d_temptable = {
   {1, 929},
   {54, 266},
   {107, 217},
   {160, 190},
   {213, 172},
   {266, 158},
   {319, 146},
   {372, 136},
   {425, 127},
   {478, 119},
   {531, 111},
   {584, 103},
   {637, 96},
   {690, 88},
   {743, 80},
   {796, 71},
   {849, 62},
   {902, 50},
   {955, 34},
   {1008, 2}
};

#endif



// RRRF 10K Thermistor 
// ./createTemperatureLookup.py --r0=10000 --t0=25 --r1=680 --r2=1600 --beta=3964 --max-adc=305
// r0: 10000
// t0: 25
// r1: 680
// r2: 1600
// beta: 3964
// max adc: 305
#if TEMP_SENSOR == TEMP_SENSOR_RRRF10K_THERMISTOR || BED_TEMP_SENSOR == TEMP_SENSOR_RRRF10K_THERMISTOR
Table e_temptable = {
   {1, 601},
   {17, 260},
   {33, 213},
   {49, 187},
   {65, 170},
   {81, 156},
   {97, 144},
   {113, 134},
   {129, 125},
   {145, 117},
   {161, 109},
   {177, 101},
   {193, 94},
   {209, 86},
   {225, 78},
   {241, 69},
   {257, 59},
   {273, 46},
   {289, 28},
   {999, 0}  // added to make NUMTEMPS 20 same as the others.
};

#endif



// Farnell code for this thermistor: 882-9586
// Made with createTemperatureLookup.py (http://svn.reprap.org/trunk/reprap/firmware/Arduino/utilities/createTemperatureLookup.py)
// ./createTemperatureLookup.py --r0=100000 --t0=25 --r1=0 --r2=4700 --beta=4066 --max-adc=1023
// r0: 100000
// t0: 25
// r1: 0
// r2: 4700
// beta: 4066
// max adc: 1023
//Developer note:  does anyone have any accurate uptodate info on supplier/s of this part, please tell reprap-dev mailing list.
/* 
 Table temptable = {
 {1, 841},
 {54, 255},
 {107, 209},
 {160, 184},
 {213, 166},
 {266, 153},
 {319, 142},
 {372, 132},
 {425, 124},
 {478, 116},
 {531, 108},
 {584, 101},
 {637, 93},
 {690, 86},
 {743, 78},
 {796, 70},
 {849, 61},
 {902, 50},
 {955, 34},
 {1008, 3}
 };
 */


// Farnell code for this thermistor: 882-9586
// Made with createTemperatureLookup.py (http://svn.reprap.org/trunk/reprap/firmware/Arduino/utilities/createTemperatureLookup.py)
// ./createTemperatureLookup.py --r0=100000 --t0=25 --r1=0 --r2=4700 --beta=4066 --max-adc=1023
// r0: 100000
// t0: 25
// r1: 0
// r2: 4700
// beta: 4066
// max adc: 1023
//Developer note:  does anyone have any accurate uptodate info on supplier/s of this part, please tell reprap-dev mailing list.
/*
 Table temptable = {
 {1, 841},
 {54, 255},
 {107, 209},
 {160, 184},
 {213, 166},
 {266, 153},
 {319, 142},
 {372, 132},
 {425, 124},
 {478, 116},
 {531, 108},
 {584, 101},
 {637, 93},
 {690, 86},
 {743, 78},
 {796, 70},
 {849, 61},
 {902, 50},
 {955, 34},
 {1008, 3}
 };
 */



// * Other thermistors...
// See this page:  
// http://www.reprap.org/wiki/Thermistor
// for details of what goes in this table, and how to make your own.

#endif //USE_THERMISTOR


void setupThermistors() {
  #if TEMP_SENSOR == TEMP_JAYCAR_NTC_125DEG_10K_THERMISTOR
  temptable = &a_temptable[0]; 
  #endif
  #if BED_TEMP_SENSOR == TEMP_JAYCAR_NTC_125DEG_10K_THERMISTOR
  bedtemptable = &a_temptable[0]; 
  #endif
  
  #if TEMP_SENSOR == TEMP_SENSOR_RS10K_THERMISTOR
  temptable = &b_temptable[0]; 
  #endif
  #if BED_TEMP_SENSOR == TEMP_SENSOR_RS10K_THERMISTOR
  bedtemptable = &b_temptable[0]; 
  #endif
  
  #if TEMP_SENSOR == TEMP_SENSOR_EPCOS540_THERMISTOR
  temptable = &c_temptable[0]; 
  #endif
  #if BED_TEMP_SENSOR == TEMP_SENSOR_EPCOS540_THERMISTOR
  bedtemptable = &c_temptable[0]; 
  #endif
  
  #if TEMP_SENSOR == TEMP_SENSOR_RRRF100K_THERMISTOR
  temptable = &d_temptable[0]; 
  #endif
  #if BED_TEMP_SENSOR == TEMP_SENSOR_RRRF100K_THERMISTOR
  bedtemptable = &d_temptable[0]; 
  #endif
  
  #if TEMP_SENSOR == TEMP_SENSOR_RRRF10K_THERMISTOR
  temptable = &e_temptable[0]; 
  #endif
  #if BED_TEMP_SENSOR == TEMP_SENSOR_RRRF10K_THERMISTOR
  bedtemptable = &e_temptable[0]; 
  #endif
}

#endif

