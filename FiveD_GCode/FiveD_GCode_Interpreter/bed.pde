
/*
 * This controld the heated bed (if any).
 * In a standard Mendel (MOTHERBOARD == 2) this
 * is done by an extruder controller.
 */


#if HEATED_BED == HEATED_BED_ON

static PIDcontrol bPID(BED_HEATER_PIN, BED_TEMPERATURE_PIN, true);


bed::bed(byte heat, byte temp)
{
  heater_pin = heat;
  temp_pin = temp;

  manageCount = 0;
  bedPID = &bPID;

  //setup our pins

  pinMode(heater_pin, OUTPUT);
  pinMode(temp_pin, INPUT);
  
  analogWrite(heater_pin, 0);


  setTemperature(0);
}

void bed::controlTemperature()
{   
  bedPID->pidCalculation();
}


void bed::waitForTemperature()
{
  byte seconds = 0;
  unsigned long endTime;
  bool warming = true;
  count = 0;
  newT = 0;
  oldT = newT;

  while (true)
  {
    newT += getTemperature();
    count++;
    if(count > 5)
    {
      newT = newT/5;
      if(newT >= bedPID->getTarget() - HALF_DEAD_ZONE)
      {
        warming = false;
        if(seconds > WAIT_AT_TEMPERATURE)
          return;
        else 
          seconds++;
      } 

      if(warming)
      {
        if(newT > oldT)
          oldT = newT;
        else
        {
          // Temp isn't increasing - extruder hardware error
          temperatureError();
          return;
        }
      }

      newT = 0;
      count = 0;
    }
    for(int i = 0; i < 1000; i++)
    {
      endTime = millis() + 1;
      while(millis() < endTime) manage();
    }
  }
}

// This is a fatal error - something is wrong with the heater.

void bed::temperatureError()
{
  sprintf(talkToHost.string(), "Bed temperature not rising - hard fault.");
  talkToHost.setFatal();
}

#endif
