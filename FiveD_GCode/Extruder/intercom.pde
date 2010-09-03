/*
 * Class to handle internal communications in the machine via RS485
 *
 * Adrian Bowyer 3 July 2009
 *
 */

#include "intercom.h"

#if MOTHERBOARD > 1


#if RS485_MASTER == 1
intercom::intercom()
#else
intercom::intercom(extruder* e)
#endif
{
#if !(RS485_MASTER == 1)
  ex = e;
#endif
  pinMode(RX_ENABLE_PIN, OUTPUT);
  pinMode(TX_ENABLE_PIN, OUTPUT);
  digitalWrite(RX_ENABLE_PIN, 0); // Listen is always on
  reset();
}

// Switch to listen mode

bool intercom::listen()
{
   if(inPacket)
   {
      listenCollision();
      return false;
   }
   digitalWrite(TX_ENABLE_PIN, 0);
   state = RS485_LISTEN;
   delayMicrosecondsInterruptible(RS485_STABILISE);
   resetWait();
   return true;
}

// Switch to talk mode

bool intercom::talk()
{
   if(state == RS485_TALK)
   {
      talkCollision();
      return false;
   }
   digitalWrite(TX_ENABLE_PIN, 1);
   state = RS485_TALK;
   delayMicrosecondsInterruptible(RS485_STABILISE);
   while(rs485Interface.available()) rs485Interface.read(); // Empty any junk from the input buffer
   resetWait();
   return true; 
}

// Reset to the initial satate

void intercom::reset()
{
  resetOutput();
  resetInput();
  listen();
}

// Reset the output buffer and its associated variables

void intercom::resetOutput()
{
  outBuffer[0] = 0;
  outPointer = 0;
}

// Reset the input buffer and its associated variables

void intercom::resetInput()
{
  inBuffer[0] = 0;
  inPointer = 0;
  inPacket = false;
  packetReceived = false;  
}

// Something useful has happened; reset the timeout time

void intercom::resetWait()
{
   wait_zero = millis();
}

// Have we waited too long for something to happen?

bool intercom::tooLong()
{
  return (millis() - wait_zero > TIMEOUT);
}


// Set the checksum for a packet.  This is the least-significant 6 bits of the sum
// of the packet's bytes added to the character RS485_CHECK.  It can thus take
// one of 64 values, all printable.

void intercom::checksum(char* packet)
{
  packet[P_SUM] = 1;  // Can't use 0, as that would terminate the packet...
  int cs = 0;
  int i = 0;
  while(packet[i]) 
  {
    cs += packet[i];
    i++;
  }
  cs--;               // Allow for the 1 at the start
  cs &= 0x3F;
  packet[P_SUM] = (char)(RS485_CHECK + cs);
}

// Check the checksum of a packet

bool intercom::checkChecksum(char* packet)
{
  char cs = packet[P_SUM];
  checksum(packet);
  return (cs == packet[P_SUM]);
}

// Build a packet to device to from an input string.  See intercom.h for the
// packet structure.  ack should either be RS485_ACK or RS485_ERROR.

void intercom::buildPacket(char to, char ack, char* string)
{
  byte i, j;
  j = 0;
  while(j < RS485_START_BYTES)
  {
     outBuffer[j] = RS485_START;
     j++;
  }
  outBuffer[j] = to;
  j++;
  outBuffer[j] = MY_NAME;
  j++; // Checksum goes here
  j++;
  outBuffer[j] = ack;
  j++;
  i = 0;
  while(string[i] && j < RS485_BUF_LEN - 4)
  {
    outBuffer[j] = string[i];
    j++;
    i++;
  }
  outBuffer[j] = 0;
  checksum(&outBuffer[RS485_START_BYTES]);
  outBuffer[j] = RS485_END;
  j++;
  outBuffer[j] = 0;
}


// The master processing function.  Call this in a fast loop, or from a fast repeated interrupt

void intercom::tick()
{
  char b = 0;
    
  switch(state)
  {
  case RS485_TALK:
  
      // Has what we last sent (if anything) been echoed?
      
      if(rs485Interface.available())
      {
        b = rs485Interface.read();
        resetWait();
        blink(true);
      } else
      {
        // Have we waited too long for an echo?
        
        if(tooLong())  
        {
          talkTimeout();
          return;  
        }
      }
      
      // Was the echo (if any) the last character of a packet?
      
      if(b == RS485_END)
      {
        // Yes - reset everything and go back to listening
        
        reset();
        return;            
      }
        
      // Do we have anything to send?
  
      b = outBuffer[outPointer];
      if(!b)
        return;
      
      // Yes - send it and reset the timeout timer
      
      rs485Interface.print(b, BYTE);
      outPointer++;
      if(outPointer >= RS485_BUF_LEN)
              outputBufferOverflow();
      resetWait();
      break;
      
  // If we have timed out while sending, reset everything and go
  // back to listen mode
      
  case RS485_TALK_TIMEOUT:
      resetOutput();
      resetInput();
      listen();
      break;
      
  case RS485_LISTEN:
      if(rs485Interface.available())  // Got anything?
      {
        blink(true);
        b = rs485Interface.read();
        switch(b)
        {
        case RS485_START:  // Start character - reset the input buffer
          inPointer = 0;
          inPacket = true;
          break;
        
        case RS485_END:   // End character - terminate, then process, the packet
          if(inPacket)
          {
            inPacket = false;
            inBuffer[inPointer] = 0;
            processPacket();
          }
          break;

        default:     // Neither start or end - if we're in a packet it must be data
                     // if not, ignore it.
          if(inPacket)
          {
            inBuffer[inPointer] = b;
            inPointer++;
            if(inPointer >= RS485_BUF_LEN)
              inputBufferOverflow();
          }
        }
        
        // We just received something, so reset the timeout time
        
        resetWait();
      } else
      {
        
        // If we're in a packet and we've been waiting too long for the next byte
        // the packet has timed out.
        
        if(inPacket && tooLong())
          listenTimeout();
          
        //blink(false);
      }
      break;
        
  case RS485_LISTEN_TIMEOUT:
      resetInput();
      listen();
      break;
      
  default:
      corrupt();
      break;
  }
}

// We are busy if we are talking, or in the middle of receiving a packet

bool intercom::busy()
{
  return (state == RS485_TALK) || inPacket;
}


// Send string to device to.

bool intercom::queuePacket(char to, char ack, char* string)
{
  if(busy())
  {
    queueCollision();
    return false;
  }
  buildPacket(to, ack, string);
  talk();
  return true;
}

// Wait for a packet to arrive.  The packet will be in inBuffer[ ]

bool intercom::waitForPacket()
{
  long timeNow = millis();  // Can't use tooLong() as tick() is using that
  while(!packetReceived)
  {
     tick();
     if(millis() - timeNow > TIMEOUT)
     {
       waitTimeout();
       packetReceived = false;
       return false;
     }
  }
  packetReceived = false;
  return true;
}

// Send a packet and get an acknowledgement - used when no data is to be returned.

bool intercom::sendPacketAndCheckAcknowledgement(char to, char* string)
{
  if(!queuePacket(to, RS485_ACK, string))
  {
    queueError();
    return false;
  }
  
  if(!waitForPacket())
  {
    waitError();
    return false;
  }
  
  if(!checkChecksum(inBuffer))
  {
    checksumError();
    return false;
  }
  
  if(inBuffer[P_ACK] != RS485_ACK)
  {
    ackError();
    return false;
  }
  
  return true;
  
/*  byte retries = 0;
  bool ok = false;
  while((inBuffer[P_TO] != MY_NAME || inBuffer[P_ACK] != RS485_ACK) && retries < RS485_RETRIES && !ok)
  {
    if(queuePacket(to, RS485_ACK, string))
      ok = waitForPacket();
    ok = ok && checkChecksum(inBuffer);
    if(!ok)
     delay(2*TIMEOUT);  // Wait twice timeout, and everything should have reset itself
    retries++;   
  }
  return ok; 
 */ 
}

// Send a packet and get data in reply.  The string returned is just the data;
// it has no packet housekeeping information in.

char* intercom::sendPacketAndGetReply(char to, char* string)
{
  if(!sendPacketAndCheckAcknowledgement(to, string))
    inBuffer[P_DATA] = 0;
  return &inBuffer[P_DATA]; //strcpy(reply, &inBuffer[P_DATA]);
  //return reply;
}

// This function is called when a packet has been received

void intercom::processPacket()
{
  char* erep = 0;
  char err;
  if(inBuffer[P_TO] != MY_NAME)
  {
    resetInput();
    return;
  }  
#if !(RS485_MASTER == 1)

  if(checkChecksum(inBuffer))
  {
    erep = ex->processCommand(&inBuffer[P_DATA]);
    if(erep) 
      queuePacket(inBuffer[P_FROM], RS485_ACK, erep);
  }
  
  if(!erep)
  {
    err = 0;
    queuePacket(inBuffer[P_FROM], RS485_ERROR, &err);
  }
  
  resetInput();
  
#endif
  packetReceived = true;
}


// *********************************************************************************

// Error functions

// The output buffer has overflowed

void intercom::outputBufferOverflow()
{
  outPointer = 0;
#if RS485_MASTER == 1
  strcpy(debugstring, "E1");
#endif  
}


// The input buffer has overflowed

void intercom::inputBufferOverflow()
{
  resetInput();
#if RS485_MASTER == 1
  strcpy(debugstring, "E2");
#endif   
}

// An attempt has been made to start sending a new message before
// the old one has been fully sent.

void intercom::talkCollision()
{
#if RS485_MASTER == 1
  strcpy(debugstring, "E3");
#endif
}

// An attempt has been made to get a new message before the old one has been
// fully received or before the last transmit is finished.

void intercom::listenCollision()
{
#if RS485_MASTER == 1
  strcpy(debugstring, "E4");
#endif  
}

// An attempt has been made to queue a new message while the system is busy.

void intercom::queueCollision()
{
#if RS485_MASTER == 1
  strcpy(debugstring, "E5");
#endif  
}

// (Part of) the data structure has become corrupted

void intercom::corrupt()
{
#if RS485_MASTER == 1
  strcpy(debugstring, "E6");
#endif   
}


// We have been trying to send a message, but something is taking too long

void intercom::talkTimeout()
{
  state = RS485_TALK_TIMEOUT;
#if RS485_MASTER == 1
  strcpy(debugstring, "E7");
#endif    
}

// We have been trying to receive a message, but something has been taking too long

void intercom::listenTimeout()
{
  state = RS485_LISTEN_TIMEOUT;
#if RS485_MASTER == 1
  strcpy(debugstring, "E8");
#endif    
}

// We have been waiting too long for an incomming packet

void intercom::waitTimeout()
{
#if RS485_MASTER == 1
  strcpy(debugstring, "E9");
#endif     
}

void intercom::queueError()
{
#if RS485_MASTER == 1
  strcpy(debugstring, "EA");
#endif     
}


void intercom::waitError()
{
#if RS485_MASTER == 1
  strcpy(debugstring, "EB");
#endif     
}


void intercom::checksumError()
{
#if RS485_MASTER == 1
  strcpy(debugstring, "EC ");
  strcat(debugstring, inBuffer);
#endif     
}

  
void intercom::ackError()
{
#if RS485_MASTER == 1
  strcpy(debugstring, "ED ");
  strcat(debugstring, inBuffer);  
#endif     
}



#endif
