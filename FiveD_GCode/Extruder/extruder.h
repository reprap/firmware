#ifndef EXTRUDER_H
#define EXTRUDER_H

#define REPLY_LENGTH 20

#define WAIT_T 'W'        // wait_for_temperature();
#define VALVE 'V'         // valve_set(bool open, int dTime);
#define DIRECTION 'D'     // set_direction(bool direction);
#define COOL 'C'          // set_cooler(byte e_speed);
#define SET_T 'T'         // set_temperature(int temp);
#define GET_T 't'         // get_temperature();
#define SET_BED_T 'B'     // set bed temperature(int temp);
#define GET_BED_T 'b'     // get bed temperature();
#define STEP 'S'          // step();
#define ENABLE 'E'        // enableStep();
#define DISABLE 'e'       // disableStep();
#define PREAD 'R'         // read the pot voltage
#define SPWM 'M'          // Set the motor PWM
#define UPFM 'U'          // Use the pot to control the motor
#define SHUT 'X'          // Hard stop
#define PING 'P'          // Just acknowledge

// PID definitions

#define TEMP_PID_INTEGRAL_DRIVE_MAX 110
#define TEMP_PID_PGAIN 5.0
#define TEMP_PID_IGAIN 0.1
#define TEMP_PID_DGAIN 100.0


#define VALVE_STARTING 0
#define VALVE_RUNNING 1
#define VALVE_STOPPING 2

//******************************************************************************************************

class PIDcontrol
{
  
private:

  volatile int iState; // Integrator state
  volatile int dState; // Last position input
  unsigned long previousTime; // ms
  unsigned long time;
  int dt;
  float pGain;
  float iGain;
  float dGain;
  int temp_dState;
  long temp_iState;
  float temp_iState_max;
  float temp_iState_min;
  int output;
  int error;
  float pTerm, iTerm, dTerm;
  byte heat_pin, temp_pin;
  bool bedTable;
  int currentTemperature;
  
public:

  PIDcontrol(byte hp, byte tp, bool b);
  void internalTemperature(short table[][2]);
  void pidCalculation(int target);
  int temperature();
  
};

inline int PIDcontrol::temperature() 
{ 
  return currentTemperature; 
}


class extruder
{

public:
   extruder();

   char* processCommand(char command[]);
   
   void manage();
  
private:

   byte coilPosition;// Stepper position between 0 and 7 inclusive
   byte pwmValue;    // PWM to the motor
   byte potVal;      // The averaged pot voltage
   byte potCount;    // Averaging counter
   int  potSum;      // For computing the pot average
   bool usePot;      // True to control the motor by the pot
   byte stp;         // Tracks the step signal
   int  targetTemperature;        // Target temperature in C
   int  targetBedTemperature;        // Target bed temperature in C
   int  manageCount; // Timing in the manage function
   bool forward;     // Extrude direction
   char reply[REPLY_LENGTH];  // For sending messages back
   PIDcontrol* extruderPID;    // Temperature control - extruder...
   PIDcontrol* bedPID;         // ... and bed (if any).

#ifdef PASTE_EXTRUDER

  bool valveAlreadyRunning;
  long valveEndTime;
  bool valveAtEnd;
  bool seenHighLow;
  bool valveState;
  bool requiredValveState;

  bool valveTimeCheck(int millisecs);
  void valveTurn(bool close);
  void valveMonitor();
  void kickStartValve();

#endif

   void waitForTemperature();
   void slowManage();
   int internalTemperature(byte pin, short table[NUMTEMPS][2]);
   void valveSet(bool open);
   void setDirection(bool direction);
   void setCooler(byte e_speed);
   void setTemperature(int t);
   void setBedTemperature(int t);
   int getTemperature();
   int getBedTemperature();
   void controlTemperature();
   void sStep(byte dir);
   void enableStep();
   void disableStep();
   int potVoltage();
   void setPWM(int p);
   void usePotForMotor();
   void shutdown(); 
};


#endif

