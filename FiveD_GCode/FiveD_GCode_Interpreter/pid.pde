#include "pid.h"

// for heated beds OR direct PIC temperature control of the extruder without a separate CPU. 
#if (HEATED_BED == HEATED_BED_ON) ||  (EXTRUDER_CONTROLLER == EXTRUDER_CONTROLLER_INTERNAL )

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
  
#if TEMP_SENSOR == TEMP_SENSOR_MAX6675_THERMOCOUPLE
  pinMode(E_MISO, INPUT);
  pinMode(E_SCK, OUTPUT);
  pinMode(E_CS, OUTPUT);
#endif

#if BED_TEMP_SENSOR == TEMP_SENSOR_MAX6675_THERMOCOUPLE
  pinMode(B_MISO, INPUT);
  pinMode(B_SCK, OUTPUT);
  pinMode(B_CS, OUTPUT);
#endif
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
#ifdef USE_THERMISTOR  // any thermistor here will do! 
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

#if TEMP_SENSOR == TEMP_SENSOR_AD595_THERMOCOUPLE 
  if(!doingBed) {
  	currentTemperature = ( 5.0 * analogRead(temp_pin* 100.0) / 1024.0; //(int)(((long)500*(long)analogRead(TEMP_PIN))/(long)1024);
  	return;
  }
#endif  
#if BED_TEMP_SENSOR == TEMP_SENSOR_AD595_THERMOCOUPLE
  if(doingBed) {
  	currentTemperature = ( 5.0 * analogRead(temp_pin* 100.0) / 1024.0; //(int)(((long)500*(long)analogRead(TEMP_PIN))/(long)1024);
  	return;
  }
#endif
#if TEMP_SENSOR == TEMP_SENSOR_MAX6675_THERMOCOUPLE || BED_TEMP_SENSOR == TEMP_SENSOR_MAX6675_THERMOCOUPLE
 // depending on the bed or extruder we may read diferent thermocouples ( if we have two! ) 
 if(doingBed) {
   read_max6675(B_CS,B_SCK,B_MISO);  
 } else {
   read_max6675(E_CS,E_SCK,E_MISO);     
 }
 
#endif

}

#if TEMP_SENSOR == TEMP_SENSOR_MAX6675_THERMOCOUPLE || BED_TEMP_SENSOR == TEMP_SENSOR_MAX6675_THERMOCOUPLE
// read from one of the thermcouples, and store into the currentTemperature variable in the current object. 
int PIDcontrol::read_max6675(int tc_0, int sck, int miso ) {

   int value = 0;
   byte error_tc;
 // don't read more often than 200 ms
 if (  millis() - last_read > 200 )  { 
   
   last_read = millis();

  digitalWrite(tc_0, 0); // Enable device

  /* Cycle the clock for dummy bit 15 */
  digitalWrite(sck,1);
  digitalWrite(sck,0);

  /* Read bits 14-3 from MAX6675 for the Temp
   	 Loop for each bit reading the value 
   */
  for (int i=11; i>=0; i--)
  {
    digitalWrite(sck,1);  // Set Clock to HIGH
    value += digitalRead(miso) << i;  // Read data and add it to our variable
    digitalWrite(sck,0);  // Set Clock to LOW
  }

  /* Read the TC Input inp to check for TC Errors */
  digitalWrite(sck,1); // Set Clock to HIGH
  error_tc = digitalRead(miso); // Read data
  digitalWrite(sck,0);  // Set Clock to LOW

  digitalWrite(tc_0, 1); //Disable Device

  if(error_tc)
    currentTemperature = 2000;
  else
    currentTemperature = value/4;
    
 } // read 
 
}
#endif

void PIDcontrol::pidCalculation()
{
  if(doingBed)
    internalTemperature(bedtemptable);
  else
    internalTemperature(temptable);
  

#if THERMAL_CONTROL == THERMAL_CONTROL_SIMPLE

  if(doingBed) {   //PWM for the bed
    if (targetTemperature >= currentTemperature) {
      analogWrite(heat_pin, 255);  //don't ever run bed above 255 PWM!  
    }else {
      analogWrite(heat_pin, 0);  //even when off, we could run it on low to "warm" it gently, but we dont
    } 
 //   Serial.println("bed");
  }else {  // ban-bang for the extruder 
  if (targetTemperature >= currentTemperature)
    digitalWrite(heat_pin, 1);  //100% power 
  else
    digitalWrite(heat_pin, 0);  //no power
  }
#endif

#if THERMAL_CONTROL == THERMAL_CONTROL_PID

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

#endif

#ifndef THERMAL_CONTROL
#error You have not defined THERMAL_CONTROL in configuration.h
#endif

}



#endif
