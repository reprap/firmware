
/**

RepRap GCode interpreter.

IMPORTANT

Before changing this interpreter,read this page:

http://objects.reprap.org/wiki/Mendel_User_Manual:_RepRapGCodes

*/

#include "features.h"
#include "configuration.h"
#include "pins.h"
#include "extruder.h"
#include "vectors.h"
#include "cartesian_dda.h"
#include <string.h>

/* bit-flags for commands and parameters */
#define GCODE_G	(1<<0)
#define GCODE_M	(1<<1)
#define GCODE_P	(1<<2)
#define GCODE_X	(1<<3)
#define GCODE_Y	(1<<4)
#define GCODE_Z	(1<<5)
#define GCODE_I	(1<<6)
#define GCODE_N	(1<<7)
#define GCODE_CHECKSUM	(1<<8)
#define GCODE_F	(1<<9)
#define GCODE_S	(1<<10)
#define GCODE_Q	(1<<11)
#define GCODE_R	(1<<12)
#define GCODE_E	(1<<13)
#define GCODE_T	(1<<14)
#define GCODE_J	(1<<15)


#define PARSE_INT(ch, str, len, val, seen, flag) \
	case ch: \
		len = scan_int(str, &val, &seen, flag); \
		break;

#define PARSE_LONG(ch, str, len, val, seen, flag) \
	case ch: \
		len = scan_long(str, &val, &seen, flag); \
		break;

#define PARSE_FLOAT(ch, str, len, val, seen, flag) \
	case ch: \
		len = scan_float(str, &val, &seen, flag); \
		break;

/* gcode line parse results */
struct GcodeParser
{
    unsigned int seen;
    int G;
    int M;
    int T;
    float P;
    float X;
    float Y;
    float Z;
    float E;
    float I;
    float J;
    float F;
    float S;
    float R;
    float Q;
    int Checksum;
    long N;
    long LastLineNrRecieved;
};


//our command string
char cmdbuffer[COMMAND_SIZE];
char c = '?';
byte serial_count = 0;
boolean comment = false;
// Serial error buffer
//char seBuffer[100];

FloatPoint fp;
FloatPoint sp;

#define DEBUG_ECHO (1<<0)
#define DEBUG_INFO (1<<1)
#define DEBUG_ERRORS (1<<2)

byte SendDebug =  DEBUG_INFO | DEBUG_ERRORS;

        
// The following three inline functions are used for things like return to 0

inline void specialMoveX(const float& x, const float& feed)
{
  sp = where_i_am;
  sp.x = x;
  sp.f = feed;
  qMove(sp);
}

inline void specialMoveY(const float& y, const float& feed)
{
  sp = where_i_am;
  sp.y = y;
  sp.f = feed;
  qMove(sp);
}

inline void specialMoveZ(const float& z, const float& feed)
{
  sp = where_i_am;
  sp.z = z; 
  sp.f = feed;
  qMove(sp);
}

void zeroX()
{
  where_i_am.f = SLOW_XY_FEEDRATE;
  specialMoveX(where_i_am.x - 5, FAST_XY_FEEDRATE);
  specialMoveX(where_i_am.x - 250, FAST_XY_FEEDRATE);
  where_i_am.x = 0;
  where_i_am.f = SLOW_XY_FEEDRATE;
  specialMoveX(where_i_am.x + 1, SLOW_XY_FEEDRATE);
  specialMoveX(where_i_am.x - 10, SLOW_XY_FEEDRATE);                                
  where_i_am.x = 0;
 
  // Wait for movements to finish, then check we hit the stop
 
  while(!qEmpty()) manage();
  if(!(endstop_hits & X_LOW_HIT))
  {
    sprintf(talkToHost.string(), "X endstop not hit - hard fault.");
    talkToHost.setFatal();
  }  
}

void zeroY()
{
  specialMoveY(where_i_am.y - 5, FAST_XY_FEEDRATE);
  specialMoveY(where_i_am.y - 250, FAST_XY_FEEDRATE);
  where_i_am.y = 0;
  where_i_am.f = SLOW_XY_FEEDRATE;
  specialMoveY(where_i_am.y + 1, SLOW_XY_FEEDRATE);
  specialMoveY(where_i_am.y - 10, SLOW_XY_FEEDRATE);                                
  where_i_am.y = 0;
 
  // Wait for movements to finish, then check we hit the stop
  
  while(!qEmpty()) manage();
  if(!(endstop_hits & Y_LOW_HIT))
  {
    sprintf(talkToHost.string(), "Y endstop not hit - hard fault.");
    talkToHost.setFatal();
  }   
   
}

void zeroZ()
{
  where_i_am.f = SLOW_Z_FEEDRATE;
  specialMoveZ(where_i_am.z - 0.5, FAST_Z_FEEDRATE);
  specialMoveZ(where_i_am.z - 250, FAST_Z_FEEDRATE);
  where_i_am.z = 0;
  where_i_am.f = SLOW_Z_FEEDRATE;
  specialMoveZ(where_i_am.z + 1, SLOW_Z_FEEDRATE);
  specialMoveZ(where_i_am.z - 2, SLOW_Z_FEEDRATE);                                
  where_i_am.z = 0;
  
  // Wait for movements to finish, then check we hit the stop

  while(!qEmpty()) manage();
  if(!(endstop_hits & Z_LOW_HIT))
  {
    sprintf(talkToHost.string(), "Z endstop not hit - hard fault.");
    talkToHost.setFatal();
  }     
}

//our feedrate variables.
//float feedrate = SLOW_XY_FEEDRATE;

/* keep track of the last G code - this is the command mode to use
 * if there is no command in the current string 
 */
int last_gcode_g = -1;

boolean abs_mode = true; //0 = incremental; 1 = absolute

float extruder_speed = 0;

int scan_int(char *str, int *valp);
int scan_float(char *str, float *valp);

GcodeParser gc;	/* string parse result */


//init our string processing
inline void init_process_string()
{
  serial_count = 0;
  comment = false;
}

// Get a command and process it

void get_and_do_command()
{         
        c = ' ';
        while(talkToHost.gotData() && c != '\n')
	{
		c = talkToHost.get();
                blink();
                if(c == '\r')
                  c = '\n';
                // Throw away control chars except \n
                if(c >= ' ' || c == '\n')
                {

		  //newlines are ends of commands.
		  if (c != '\n')
		  {
			// Start of comment - ignore any bytes received from now on
			if (c == ';')
				comment = true;
				
			// If we're not in comment mode, add it to our array.
			if (!comment)
				cmdbuffer[serial_count++] = c;
		  }

                }
                // Buffer overflow?
                if(serial_count >= COMMAND_SIZE)
                    init_process_string();
	}

	//if we've got a real command, do it
	if (serial_count && c == '\n')
	{
                // Terminate string
                cmdbuffer[serial_count] = 0;
                
                if(SendDebug & DEBUG_ECHO)
                   sprintf(talkToHost.string(), "Echo: %s", cmdbuffer);
                   
		//process our command!
		process_string(cmdbuffer, serial_count);

		//clear command.
		init_process_string();

                // Say we're ready for the next one
                
                talkToHost.sendMessage(SendDebug & DEBUG_INFO);
                
	}
}



void parse_string(struct GcodeParser * gc, char instruction[ ], int size)
{
	int ind;
	int len;	/* length of parameter argument */

	gc->seen = 0;

	len=0;
	/* scan the string for commands and parameters, recording the arguments for each,
	 * and setting the seen flag for each that is seen
	 */
	for (ind=0; ind<size; ind += (1+len))
	{
		len = 0;
		switch (instruction[ind])
		{
			  PARSE_INT('G', &instruction[ind+1], len, gc->G, gc->seen, GCODE_G);
			  PARSE_INT('M', &instruction[ind+1], len, gc->M, gc->seen, GCODE_M);
			  PARSE_INT('T', &instruction[ind+1], len, gc->T, gc->seen, GCODE_T);
			PARSE_FLOAT('S', &instruction[ind+1], len, gc->S, gc->seen, GCODE_S);
			PARSE_FLOAT('P', &instruction[ind+1], len, gc->P, gc->seen, GCODE_P);
			PARSE_FLOAT('X', &instruction[ind+1], len, gc->X, gc->seen, GCODE_X);
			PARSE_FLOAT('Y', &instruction[ind+1], len, gc->Y, gc->seen, GCODE_Y);
			PARSE_FLOAT('Z', &instruction[ind+1], len, gc->Z, gc->seen, GCODE_Z);
			PARSE_FLOAT('I', &instruction[ind+1], len, gc->I, gc->seen, GCODE_I);
			PARSE_FLOAT('J', &instruction[ind+1], len, gc->J, gc->seen, GCODE_J);
			PARSE_FLOAT('F', &instruction[ind+1], len, gc->F, gc->seen, GCODE_F);
			PARSE_FLOAT('R', &instruction[ind+1], len, gc->R, gc->seen, GCODE_R);
			PARSE_FLOAT('Q', &instruction[ind+1], len, gc->Q, gc->seen, GCODE_Q);
			PARSE_FLOAT('E', &instruction[ind+1], len, gc->E, gc->seen, GCODE_E);
			PARSE_LONG('N', &instruction[ind+1], len, gc->N, gc->seen, GCODE_N);
			PARSE_INT('*', &instruction[ind+1], len, gc->Checksum, gc->seen, GCODE_CHECKSUM);
                        default:
			  break;
		}
	}
}


//Read the string and execute instructions
void process_string(char instruction[], int size)
{
	//the character / means delete block... used for comments and stuff.
	if (instruction[0] == '/')	
		return;

        float fr;
        bool axisSelected;
        
	fp.x = 0.0;
	fp.y = 0.0;
	fp.z = 0.0;
        fp.e = 0.0;
        fp.f = 0.0;

	//get all our parameters!
	parse_string(&gc, instruction, size);
  
  
        // Do we have lineNr and checksums in this gcode?
        if((bool)(gc.seen & GCODE_CHECKSUM) | (bool)(gc.seen & GCODE_N))
        {
          // Check that if recieved a L code, we also got a C code. If not, one of them has been lost, and we have to reset queue
          if( (bool)(gc.seen & GCODE_CHECKSUM) != (bool)(gc.seen & GCODE_N) )
          {
           if(SendDebug & DEBUG_ERRORS)
           {
              if(gc.seen & GCODE_CHECKSUM)
                sprintf(talkToHost.string(), "Serial Error: checksum without line number. Checksum: %d, line received: %s", gc.Checksum, instruction);
              else
                sprintf(talkToHost.string(), "Serial Error: line number without checksum. Linenumber: %ld, line received: %s", gc.N, instruction);
           }
           talkToHost.setResend(gc.LastLineNrRecieved+1);
           return;
          }
          // Check checksum of this string. Flush buffers and re-request line of error is found
          if(gc.seen & GCODE_CHECKSUM)  // if we recieved a line nr, we know we also recieved a Checksum, so check it
          {
            // Calc checksum.
            byte checksum = 0;
            byte count=0;
            while(instruction[count] != '*')
              checksum = checksum^instruction[count++];
            // Check checksum.
            if(gc.Checksum != (int)checksum)
            {
              if(SendDebug & DEBUG_ERRORS)
                sprintf(talkToHost.string(), "Serial Error: checksum mismatch.  Remote (%d) not equal to local (%d), line received: %s", gc.Checksum, (int)checksum, instruction);
              talkToHost.setResend(gc.LastLineNrRecieved+1);
              return;
            }
          // Check that this lineNr is LastLineNrRecieved+1. If not, flush
          if(!( (bool)(gc.seen & GCODE_M) && gc.M == 110)) // unless this is a reset-lineNr command
            if(gc.N != gc.LastLineNrRecieved+1)
            {
                if(SendDebug & DEBUG_ERRORS)
                  sprintf(talkToHost.string(), "Serial Error: Linenumber (%ld) is not last + 1 (%ld), line received: %s", gc.N, gc.LastLineNrRecieved+1, instruction);
                talkToHost.setResend(gc.LastLineNrRecieved+1);
                return;
            }
           //If we reach this point, communication is a succes, update our "last good line nr" and continue
           gc.LastLineNrRecieved = gc.N;
          }
        }


	/* if no command was seen, but parameters were, then use the last G code as 
	 * the current command
	 */
	if ((!(gc.seen & (GCODE_G | GCODE_M | GCODE_T))) && ((gc.seen != 0) && (last_gcode_g >= 0)))
	{
		/* yes - so use the previous command with the new parameters */
		gc.G = last_gcode_g;
		gc.seen |= GCODE_G;
	}

        // Deal with emergency stop as No 1 priority
        
        if ((gc.seen & GCODE_M) && (gc.M == 112))
            shutdown();
        
	//did we get a gcode?
	if (gc.seen & GCODE_G)
  	{
		last_gcode_g = gc.G;	/* remember this for future instructions */
		fp = where_i_am;
		if (abs_mode)
		{
			if (gc.seen & GCODE_X)
				fp.x = gc.X;
			if (gc.seen & GCODE_Y)
				fp.y = gc.Y;
			if (gc.seen & GCODE_Z)
				fp.z = gc.Z;
			if (gc.seen & GCODE_E)
				fp.e = gc.E;
		}
		else
		{
			if (gc.seen & GCODE_X)
				fp.x += gc.X;
			if (gc.seen & GCODE_Y)
				fp.y += gc.Y;
			if (gc.seen & GCODE_Z)
				fp.z += gc.Z;
			if (gc.seen & GCODE_E)
				fp.e += gc.E;
		}

		// Get feedrate if supplied - feedrates are always absolute???
		if ( gc.seen & GCODE_F )
			fp.f = gc.F;
               
                // Process the buffered move commands first
                // If we get one, return immediately

		switch (gc.G)
                {
			//Rapid move
			case 0:
                                fr = fp.f;
                                fp.f = FAST_XY_FEEDRATE;
                                qMove(fp);
                                fp.f = fr;
                                return;
                                
                        // Controlled move; -ve coordinate means zero the axis
			case 1:
                                 qMove(fp);
                                 return;                                  
                                
                        //go home.  If we send coordinates (regardless of their value) only zero those axes
			case 28:
                                axisSelected = false;
                                if(gc.seen & GCODE_X)
                                {
                                  zeroX();
                                  axisSelected = true;
                                }
                                if(gc.seen & GCODE_Y)
                                {
                                  zeroY();
                                  axisSelected = true;
                                }                                
                                if(gc.seen & GCODE_Z)
                                {
                                  zeroZ();
                                  axisSelected = true;
                                }
                                if(!axisSelected)
                                {
                                  zeroX();
                                  zeroY();
                                  zeroZ();
                                }
                                where_i_am.f = SLOW_XY_FEEDRATE;     // Most sensible feedrate to leave it in                    

				return;


                          default:
                                break;
                }
                
		// Non-buffered G commands
                // Wait till the buffer q is empty first
                    
                  waitFor_qEmpty();
                  long endTime;
		  switch (gc.G)
		  {

  			 //Dwell
			case 4:
                                endTime = millis() + (int)(gc.P + 0.5);
				while(millis() < endTime) manage();  
				break;

			//Inches for Units
			case 20:
                                setUnits(false);
				break;

			//mm for Units
			case 21:
                                setUnits(true);
				break;

			//Absolute Positioning
			case 90: 
				abs_mode = true;
				break;

			//Incremental Positioning
			case 91: 
				abs_mode = false;
				break;

			//Set position as fp
			case 92: 
                                setPosition(fp);
				break;

			default:
				if(SendDebug & DEBUG_ERRORS)
                                  sprintf(talkToHost.string(), "Dud G code: G%d", gc.G);
                                talkToHost.setResend(gc.LastLineNrRecieved+1);
		  }
	}



        
	//find us an m code.
	if (gc.seen & GCODE_M)
	{
            // Wait till the q is empty first
            waitFor_qEmpty();
		switch (gc.M)
		{
			
                        
			case 0:
                                shutdown();
				break;
				/*
				 case 1:
				 //todo: optional stop
				 break;

				 case 2:
				 //todo: program end
				 break;
				 */

// Now, with E codes, there is no longer any idea of turning the extruder on or off.
// (But see valve on/off below.)

/*
			//turn extruder on, forward
			case 101:
				ex[extruder_in_use]->setDirection(1);
				ex[extruder_in_use]->setSpeed(extruder_speed);
				break;

			//turn extruder on, reverse
			case 102:
				ex[extruder_in_use]->setDirection(0);
				ex[extruder_in_use]->setSpeed(extruder_speed);
				break;

			//turn extruder off

*/
			//custom code for temperature control
			case 104:
				if (gc.seen & GCODE_S)
				{
					ex[extruder_in_use]->setTemperature((int)gc.S);
				}
				break;

			//custom code for temperature reading
			case 105:
                                talkToHost.setETemp(ex[extruder_in_use]->getTemperature());
#if EXTRUDER_CONTROLLER == EXTRUDER_CONTROLLER_RS485
#if HEATED_BED == HEATED_BED_ON
                                talkToHost.setBTemp(ex[0]->getBedTemperature());
#endif
#endif
#if EXTRUDER_CONTROLLER == EXTRUDER_CONTROLLER_INTERNAL
#if HEATED_BED == HEATED_BED_ON
                                talkToHost.setBTemp(heatedBed.getTemperature());
#endif
#endif
				break;

			//turn fan on
			case 106:
				ex[extruder_in_use]->setCooler(255);
				break;

			//turn fan off
			case 107:
				ex[extruder_in_use]->setCooler(0);
				break;


                        // Set the temperature and wait for it to get there
			case 109:
				ex[extruder_in_use]->setTemperature((int)gc.S);
                                ex[extruder_in_use]->waitForTemperature();
				break;
                        // Starting a new print, reset the gc.LastLineNrRecieved counter
			case 110:
				if (gc.seen & GCODE_N)
			          gc.LastLineNrRecieved = gc.N;
				break;
			case 111:
				SendDebug = gc.S;
				break;
			case 112:	// STOP!
				shutdown();
				break;

// If there's an S field, use that to set the PWM, otherwise use the pot.
                       case 108: // Depricated
                       case 113:
                                #if MOTHERBOARD == 2
                                 if (gc.seen & GCODE_S)
                                     ex[extruder_in_use]->setPWM((int)(255.0*gc.S + 0.5));
                                  else
                                     ex[extruder_in_use]->usePotForMotor();
                                #endif
				break;

			//custom code for returning current coordinates
			case 114:
                                talkToHost.setCoords(where_i_am);
				break;

			//Reserved for returning machine capabilities in keyword:value pairs
			//custom code for returning Firmware Version and Capabilities 
			case 115:
                                talkToHost.capabilities();
				break;



                        // TODO: make this work properly
                        case 116:
                             ex[extruder_in_use]->waitForTemperature();
				break;

			//custom code for returning zero-hit coordinates
			case 117:
                                talkToHost.setCoords(zeroHit);
				break;

// The valve (real, or virtual...) is now the way to control any extruder (such as
// a pressurised paste extruder) that cannot move using E codes.

                        // Open the valve
                        case 126:
                                ex[extruder_in_use]->valveSet(true, (int)(gc.P + 0.5));
                                break;
                                
                        // Close the valve
                        case 127:
                                ex[extruder_in_use]->valveSet(false, (int)(gc.P + 0.5));
                                break;
                                                                
                        case 140:
				if (gc.seen & GCODE_S)
				{
        
#if EXTRUDER_CONTROLLER == EXTRUDER_CONTROLLER_RS485
#if HEATED_BED == HEATED_BED_ON
					ex[0]->setBedTemperature((int)gc.S);
#endif
#endif
#if EXTRUDER_CONTROLLER == EXTRUDER_CONTROLLER_INTERNAL
#if HEATED_BED == HEATED_BED_ON
  					heatedBed.setTemperature((int)gc.S);
#endif
#endif				
                                }
				break;

                        case 141: //TODO: set chamber temperature
                                break;
                                
                        case 142: //TODO: set holding pressure
                                break;                                

			default:
				if(SendDebug & DEBUG_ERRORS)
                                  sprintf(talkToHost.string(), "Dud M code: M%d", gc.M);
                                talkToHost.setResend(gc.LastLineNrRecieved+1);
		}

                

	}

// Tool (i.e. extruder) change?
                
        if (gc.seen & GCODE_T)
        {
            waitFor_qEmpty();
            newExtruder(gc.T);
        }
}

int scan_float(char *str, float *valp, unsigned int *seen, unsigned int flag)
{
	float res;
	int len;
	char *end;
     
	res = (float)strtod(str, &end);
      
	len = end - str;

	if (len > 0)
	{
		*valp = res;
		*seen |= flag;
	}
	else
		*valp = 0;
          
	return len;	/* length of number */
}

int scan_int(char *str, int *valp, unsigned int *seen, unsigned int flag)
{
	int res;
	int len;
	char *end;

	res = (int)strtol(str, &end, 10);
	len = end - str;

	if (len > 0)
	{
		*valp = res;
		*seen |= flag;
	}
	else
		*valp = 0;
          
	return len;	/* length of number */
}

int scan_long(char *str, long *valp, unsigned int *seen, unsigned int flag)
{
	long res;
	int len;
	char *end;

	res = strtol(str, &end, 10);
	len = end - str;

	if (len > 0)
	{
		*valp = res;
		*seen |= flag;
	}
	else
		*valp = 0;
          
	return len;	/* length of number in ascii world */
}

void setupGcodeProcessor()
{
  gc.LastLineNrRecieved = -1;
}

