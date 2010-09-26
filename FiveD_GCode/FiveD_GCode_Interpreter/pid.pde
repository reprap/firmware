#include "pid.h"

#if MOTHERBOARD != 2

// Based on the excellent Wikipedia PID control article.
// See http://en.wikipedia.org/wiki/PID_controller

PIDcontrol::PIDcontrol(byte hp, byte tp, bool b)
{
   heat_pin = hp;
   temp_pin = tp;
   doingBed = b;
   if(doingBed)
   {
     pGain = B_TEMP_PID_PGAIN;
     iGain = B_TEMP_PID_IGAIN;
     dGain = B_TEMP_PID_DGAIN;
     band = B_TEMP_PID_BAND;
   } else
   {
     pGain = E_TEMP_PID_PGAIN;
     iGain = E_TEMP_PID_IGAIN;
     dGain = E_TEMP_PID_DGAIN;
     band = E_TEMP_PID_BAND;
   }   
   currentTemperature = 0;
   setTarget(0);
   pinMode(heat_pin, OUTPUT);
   pinMode(temp_pin, INPUT); 
}

/*
 Set the target temperature.  This also
 resets the PID to, for example, remove accumulated integral error from
 a long period when the heater was off and the requested temperature was 0 (which it
 won't go down to, even with the heater off, so the integral error grows).  
*/

void PIDcontrol::setTarget(int t)
{
   targetTemperature = t;
   previousTime = millis();
   previousError = 0;
   integral = 0;  
}

/* 
 Temperature reading function  
 With thanks to: Ryan Mclaughlin - http://www.arduino.cc/cgi-bin/yabb2/YaBB.pl?num=1230859336
 for the MAX6675 code
 */

void PIDcontrol::internalTemperature(short table[][2])
{
#ifdef USE_THERMISTOR
  int raw = 0;
  for(int i = 0; i < 3; i++)
    raw += analogRead(temp_pin);
    
  raw = raw/3;

  byte i;

  // TODO: This should do a binary chop

  for (i=1; i<NUMTEMPS; i++)
  {
    if (table[i][0] > raw)
    {
      currentTemperature  = table[i-1][1] + 
        (raw - table[i-1][0]) * 
        (table[i][1] - table[i-1][1]) /
        (table[i][0] - table[i-1][0]);

      break;
    }
  }

  // Overflow: Set to last value in the table
  if (i >= NUMTEMPS) currentTemperature = table[i-1][1];
  // Clamp to byte
  //if (celsius > 255) celsius = 255; 
  //else if (celsius < 0) celsius = 0; 

#endif

#ifdef AD595_THERMOCOUPLE
  currentTemperature = ( 5.0 * analogRead(pin* 100.0) / 1024.0; //(int)(((long)500*(long)analogRead(TEMP_PIN))/(long)1024);
#endif  

#ifdef MAX6675_THERMOCOUPLE
  int value = 0;
  byte error_tc;


  digitalWrite(TC_0, 0); // Enable device

  /* Cycle the clock for dummy bit 15 */
  digitalWrite(SCK,1);
  digitalWrite(SCK,0);

  /* Read bits 14-3 from MAX6675 for the Temp
   	 Loop for each bit reading the value 
   */
  for (int i=11; i>=0; i--)
  {
    digitalWrite(SCK,1);  // Set Clock to HIGH
    value += digitalRead(SO) << i;  // Read data and add it to our variable
    digitalWrite(SCK,0);  // Set Clock to LOW
  }

  /* Read the TC Input inp to check for TC Errors */
  digitalWrite(SCK,1); // Set Clock to HIGH
  error_tc = digitalRead(SO); // Read data
  digitalWrite(SCK,0);  // Set Clock to LOW

  digitalWrite(TC_0, 1); //Disable Device

  if(error_tc)
    currentTemperature = 2000;
  else
    currentTemperature = value/4;

#endif

}


void PIDcontrol::pidCalculation()
{
  if(doingBed)
    internalTemperature(bedtemptable);
  else
    internalTemperature(temptable);
  
  float error = (float)(targetTemperature - currentTemperature);
  int output;
  if(error < -band)
  {
    output = 0;
    setTarget(targetTemperature);
  } else if (error > band)
  {
    output = 255;
    setTarget(targetTemperature);    
  } else
  {
    // PID
    time = millis();
    float dt = 0.001*(float)(time - previousTime);
    previousTime = time;
    if (dt <= 0) // Don't do it when millis() has rolled over
      return;
    
  
    integral += error*dt;
    float derivative = (error - previousError)/dt;
    previousError = error;
    output = (int)(error*pGain + integral*iGain + derivative*dGain);
    if(!doingBed && cdda[tail]->extruding())
      output += EXTRUDING_INCREASE;
    output = constrain(output, 0, 255);
  }
  
  analogWrite(heat_pin, output);
}



#endif
