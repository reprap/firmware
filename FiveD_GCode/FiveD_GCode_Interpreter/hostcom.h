#ifndef HOSTCOM_H
#define HOSTCOM_H
/*
  Class to handle sending messages from and back to the host.
  NOWHERE ELSE in this program should anything send to Serial.print()
  or get anything from Serial.read().
  
  All communication is in printable ASCII characters.  Messages sent back
  to the host computer are terminated by a newline and look like this:
  
  xx [line number to resend] [T:93.2 B:22.9] [C: X:9.2 Y:125.4 Z:3.7 E:1902.5] [Some debugging or other information may be here]
  
  where xx can be one of:
  
  ok
  rs
  !!
  
  ok means that no error has been detected.
  rs means resend, and must be followed by the line number to resend.
  !! means that a hardware fault has been detected.  The RepRap machine will
       shut down immediately after it has sent this message.
       
  The T: and B: values are the temperature of the currently-selected extruder 
  and the bed respectively, and are only sent in response to a request using the
  appropriate M code.
  
  C: means that coordinates follow.  Those are the X: Y: etc values.  These are only 
  sent in response to a request using the appropriate M code.

  The most common response is simply:

  ok  
       
  When the machine boots up it sends the string
  
  start
  
  once to the host before sending anything else.  This should not be replaced or augmented
  by version numbers and the like.  We should implement an M code to request those.
       
 */

// Can't get lower than absolute zero...

#define NO_TEMP -300

extern void shutdown();

class hostcom
{
public:
  hostcom();
  char* string();
  void setETemp(int et);
  void setBTemp(int bt);
  void setCoords(const FloatPoint& where);
  void setResend(long ln);
  void setFatal();
  void sendMessage(bool doMessage);
  void start();
  
// Wrappers for the comms interface

  void putInit();
  void put(char* s);
  void put(const float& f);
  void put(const long& l);
  void put(int i);
  void putEnd();
  byte gotData();
  char get();
  
private:
  void reset();
  void sendtext(bool noText);
  char message[RESPONSE_SIZE];
  int etemp;
  int btemp;
  float x;
  float y;
  float z;
  float e;
  long resend;
  bool fatal;
  bool sendCoordinates;  
};

inline hostcom::hostcom()
{
  fatal = false;
  reset();
}

// Wrappers for the comms interface

inline void hostcom::putInit() {  Serial.begin(HOST_BAUD); }
inline void hostcom::put(char* s) { Serial.print(s); }
inline void hostcom::put(const float& f) { Serial.print(f); }
inline void hostcom::put(const long& l) { Serial.print(l); }
inline void hostcom::put(int i) { Serial.print(i); }
inline void hostcom::putEnd() { Serial.println(); }
inline byte hostcom::gotData() { return Serial.available(); }
inline char hostcom::get() { return Serial.read(); }


// called after each message has been sent

inline void hostcom::reset()
{
  etemp = NO_TEMP;
  btemp = NO_TEMP;
  message[0] = 0;
  resend = -1;
  sendCoordinates = false;
  // Don't reset fatal.
}

// Called once when the machine boots

inline void hostcom::start()
{
  putInit();
  put("start");
  putEnd();  
}

// Return the place to write messages into.  Typically this is used in lines like:
// sprintf(talkToHost.string(), "Echo: %s", cmdbuffer);

inline char* hostcom::string()
{
  return message;
}

// Set the extruder temperature to be returned.

inline void hostcom::setETemp(int et)
{
  etemp = et;
}

// Set the bed temperature to be returned

inline void hostcom::setBTemp(int bt)
{
  btemp = bt;
}

// Set the machine's coordinates to be returned

inline void hostcom::setCoords(const FloatPoint& where)
{
  x = where.x;
  y = where.y;
  z = where.z;
  e = where.e;
  sendCoordinates = true;
}

// Request a resend of line ln

inline void hostcom::setResend(long ln)
{
  resend = ln;
}

// Flag that a fatal error has occurred (such as a temperature sensor failure).

inline void hostcom::setFatal()
{
  fatal = true;
}

// Send the text stored (if any) to the host.

inline void hostcom::sendtext(bool doMessage)
{
  if(!doMessage)
    return;
  if(!message[0])
    return;
  put(" ");
  put(message);
}

// Master function to return messages to the host

inline void hostcom::sendMessage(bool doMessage)
{
  if(fatal)
  {
    put("!!");
    sendtext(true);
    putEnd();
    shutdown();
    return; // Technically redundant - shutdown never returns.
  }
  
  if(resend < 0)
    put("ok");
  else
  {
    put("rs ");
    put(resend);
  }
    
  if(etemp > NO_TEMP)
  {
    put(" T:");
    put(etemp);
  }
  
  if(btemp > NO_TEMP)
  {
    put(" B:");
    put(btemp);
  }
  
  if(sendCoordinates)
  {				
    put(" C: X:");
    put(x);
    put(" Y:");
    put(y);
    put(" Z:");
    put(z);
    put(" E:");
    put(e);
  }
  
  sendtext(doMessage);
  
  putEnd();
  
  reset(); 
}


#endif
