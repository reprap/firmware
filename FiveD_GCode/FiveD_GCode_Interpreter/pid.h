#ifndef PID_H
#define PID_H

// Based on the excellent Wikipedia PID control article.
// See http://en.wikipedia.org/wiki/PID_controller

// for heated beds OR direct PIC temperature control of the extruder without a separate CPU. 
#if (HEATED_BED == HEATED_BED_ON) ||  (EXTRUDER_CONTROLLER == EXTRUDER_CONTROLLER_INTERNAL )

class PIDcontrol
{
  
private:

  bool doingBed;
  unsigned long previousTime; // ms
  unsigned long time;
  float previousError;
  float integral;
  float pGain;
  float iGain;
  float dGain;
  float band;
  byte heat_pin, temp_pin;
  int currentTemperature, targetTemperature;
 
  void internalTemperature(short table[][2]); 
  
public:

  PIDcontrol(byte hp, byte tp, bool b);
  void setTarget(int t);
  int getTarget();
  void pidCalculation();
  void shutdown();
  int temperature();
  
};

inline int PIDcontrol::temperature() 
{ 
  return currentTemperature; 
}

inline int PIDcontrol::getTarget() 
{ 
  return targetTemperature; 
}

inline void PIDcontrol::shutdown()
{
  analogWrite(heat_pin, 0);
}

#endif
#endif

