/*
 Test program for checking RepRap electronic's inputs (opto-endstops
 and temperatur sensors) via Arduino serial link.

 With this Arduino sketch, you can test the functioning of these
 inputs without any RepRap host software. So this enables you to
 check the sensors part of your wiring.

 This program sends the data read from these inputs to Arduino IDE's
 serial console. Set the defines below as they are defined in your
 "pins.h" file of the FiveD firmware. Then compile and upload this
 sketch and start the Arduino serial console (with 19200 Baud) to
 observe the values of your sensors as you test them.

 Created 2010-09-28 by Peer Janssen
*/


//This should use an #include "pins.h", but for some reason this
//didn't work for me, so the defines are copied into this file.
//This include defines the following constants used here:

//Digital input pins:

#define X_MIN_PIN (byte)45
#define X_MAX_PIN (byte)21 //seems to be wrong for Arduino Mega
#define Y_MIN_PIN (byte)44
#define Y_MAX_PIN (byte)26
#define Z_MIN_PIN (byte)37
#define Z_MAX_PIN (byte)1  //seems to be wrong for Arduino Mega

//Analog input pins:

#define BED_TEMPERATURE_PIN (byte)1
#define EXTRUDER_0_TEMPERATURE_PIN (byte)0
#define EXTRUDER_1_TEMPERATURE_PIN (byte)2


void setup()
{
  // start serial port at 19200 bps:
  Serial.begin(19200);
  pinMode(X_MIN_PIN, INPUT);
  pinMode(X_MAX_PIN, INPUT);
  pinMode(Y_MIN_PIN, INPUT);
  pinMode(Y_MAX_PIN, INPUT);
  pinMode(Z_MIN_PIN, INPUT);
  pinMode(Z_MAX_PIN, INPUT);

}

void loop()
{
    // read and send digital inputs
    Serial.print("Xmin: ");
    Serial.print(digitalRead(X_MIN_PIN), DEC);
    Serial.print(" - Xmax: ");
    Serial.print(digitalRead(X_MAX_PIN), DEC);
    Serial.print(" - Ymin: ");
    Serial.print(digitalRead(Y_MIN_PIN), DEC);
    Serial.print(" - Ymax: ");
    Serial.print(digitalRead(Y_MAX_PIN), DEC);
    Serial.print(" - Zmin: ");
    Serial.print(digitalRead(Z_MIN_PIN), DEC);
    Serial.print(" - Zmax: ");
    Serial.print(digitalRead(Z_MAX_PIN), DEC);

    // read and send analog inputs
    Serial.print(" -- Bed: ");
    Serial.print(analogRead(BED_TEMPERATURE_PIN), DEC);
    delay(10);
    Serial.print(" - E0: ");
    Serial.print(analogRead(EXTRUDER_0_TEMPERATURE_PIN), DEC);
    delay(10);
    Serial.print(" - E1: ");
    Serial.print(analogRead(EXTRUDER_1_TEMPERATURE_PIN), DEC);
    Serial.print("\n");
    delay(300);
} 

