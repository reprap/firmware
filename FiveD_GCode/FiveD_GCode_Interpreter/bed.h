/*
 * This controld the heated bed (if any).
 */

#ifndef BED_H
#define BED_H

#if HEATED_BED == HEATED_BED_ON

class bed
{
  
public:
   bed(byte heat, byte temp);
   void waitForTemperature();
   
   void setTemperature(int temp);
   int getTemperature();
   void slowManage();
   void manage();
   void shutdown();
 
private:

//   int targetTemperature;
   int count;
   int oldT, newT;
   long manageCount;
   
   PIDcontrol* bedPID;    // Temperature control - extruder...

   int sampleTemperature();
   void controlTemperature();
   void temperatureError(); 

// The pins we control
   byte heater_pin,  temp_pin;
 
};

inline void bed::slowManage()
{
  manageCount = 0;  

  controlTemperature();
}

inline void bed::manage()
{
  manageCount++;
  if(manageCount > SLOW_CLOCK)
    slowManage();   
}

// Stop everything

inline void bed::shutdown()
{
  setTemperature(0);
  bedPID->shutdown();
}

inline void bed::setTemperature(int tp)
{
  bedPID->setTarget(tp);
}

inline int bed::getTemperature()
{
  return bedPID->temperature();  
}


#endif
#endif
