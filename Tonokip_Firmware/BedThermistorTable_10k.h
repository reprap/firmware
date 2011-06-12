#ifndef BEDTHERMISTORTABLE_10K_H_
#define BEDTHERMISTORTABLE_10K_H_

// Thermistor lookup table for RepRap Temperature Sensor Boards (http://make.rrrf.org/ts)
// See this page:  
// http://dev.www.reprap.org/bin/view/Main/Thermistor
// for details of what goes in this table.
// Made with createTemperatureLookup.py (http://svn.reprap.org/trunk/reprap/firmware/Arduino/utilities/createTemperatureLookup.py)



// RS thermistor 484-0149; EPCOS B57550G103J
// Made with createTemperatureLookup.py (http://svn.reprap.org/trunk/reprap/firmware/Arduino/utilities/createTemperatureLookup.py)
// ./createTemperatureLookup.py --r0=10000 --t0=25 --r1=0 --r2=4700 --beta=3480 --max-adc=1023
// r0: 10000
// t0: 25
// r1: 0
// r2: 4700
// beta: 3480
// max adc: 1023
#define BNUMTEMPS 20
short bedtemptable[BNUMTEMPS][2] = {
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


