/*
 * This class controls the movement of the RepRap machine.
 * It implements a DDA in five dimensions, so the length of extruded 
 * filament is treated as a variable, just like X, Y, and Z.  Speed
 * is also a variable, making accelleration and deceleration automatic.
 *
 * Adrian Bowyer 9 May 2009
 */

#ifndef CARTESIAN_DDA_H
#define CARTESIAN_DDA_H

// Main class for moving the RepRap machine about

class cartesian_dda
{
private:


  bool using_mm;
  FloatPoint units;            // Factors for converting either mm or inches to steps

  FloatPoint target_position;  // Where it's going
  FloatPoint delta_position;   // The difference between the two
  float distance;              // How long the path is
  
  LongPoint current_steps;     // Similar information as above in steps rather than units
  LongPoint target_steps;
  LongPoint delta_steps;
  LongPoint dda_counter;       // DDA error-accumulation variables
  long t_scale;                // When doing lots of t steps, scale them so the DDA doesn't spend for ever on them
  
  volatile bool x_direction;            // Am I going in the + or - direction?
  volatile bool y_direction;
  volatile bool z_direction;
  volatile bool e_direction;
  volatile bool f_direction;

  volatile bool x_can_step;             // Am I not at an endstop?  Have I not reached the target? etc.
  volatile bool y_can_step;
  volatile bool z_can_step;
  volatile bool e_can_step;
  volatile bool f_can_step;

// Variables for acceleration calculations

  volatile long total_steps;            // The number of steps to take along the longest movement axis
  
  long timestep;               // microseconds
  bool nullmove;               // this move is zero length
  volatile bool real_move;     // Flag to know if we've changed something physical
  volatile bool feed_change;   // Flag to know if feedrate has changed
  volatile bool live;          // Flag for when we're plotting a line

// Internal functions that need not concern the user

  // Take a single step

  void do_x_step();               
  void do_y_step();
  void do_z_step();
  void do_e_step();
  
  // Can this axis step?
  
  bool xCanStep(long current, long target, bool dir);
  bool yCanStep(long current, long target, bool dir);
  bool zCanStep(long current, long target, bool dir);
  bool eCanStep(long current, long target, bool dir);
  bool fCanStep(long current, long target, bool dir);
  
  // Read a limit switch
  
  //bool read_switch(byte pin, bool inv);
  
  // Work out the number of microseconds between steps
  
  long calculate_feedrate_delay(const float& feedrate);
  
  // Switch the steppers on and off
  
  void enable_steppers();
  void disable_steppers();
  
  
public:

  cartesian_dda();
  
  // Set where I'm going
  
  void set_target(const FloatPoint& p);
  
  // Start the DDA
  
  void dda_start();
  
  // Do one step of the DDA
  
  void dda_step();
  
  // Are we running at the moment?
  
  bool active();
  
  // Are we extruding at the moment?
  
  bool extruding();
  
  // True for mm; false for inches
  
  void set_units(bool using_mm);
  void set_units();
  bool get_units();
  
  FloatPoint returnUnits();
  
  // Kill - stop all activity and turn off steppers
  
  void shutdown();
  
};

// Short functions inline to save memory; particularly useful in the Arduino

inline FloatPoint cartesian_dda::returnUnits()
{
  return units;
}

inline bool cartesian_dda::get_units()
{
  return using_mm;
}

inline bool cartesian_dda::active()
{
  return live;
}

inline bool cartesian_dda::extruding()
{
  return live && (current_steps.e != target_steps.e);
}


inline void cartesian_dda::do_x_step()
{
	digitalWrite(X_STEP_PIN, HIGH);
	digitalWrite(X_STEP_PIN, LOW);
}

inline void cartesian_dda::do_y_step()
{
	digitalWrite(Y_STEP_PIN, HIGH);
	digitalWrite(Y_STEP_PIN, LOW);
}

inline void cartesian_dda::do_z_step()
{
	digitalWrite(Z_STEP_PIN, HIGH);
	digitalWrite(Z_STEP_PIN, LOW);
}

inline void cartesian_dda::do_e_step()
{
        ex[extruder_in_use]->sStep();
}

inline long cartesian_dda::calculate_feedrate_delay(const float& feedrate)
{  
        
	// Calculate delay between steps in microseconds.  Here it is in English:
        // (feedrate is in mm/minute, distance is in mm)
	// 60000000.0*distance/feedrate  = move duration in microseconds
	// move duration/total_steps = time between steps for master axis.

	return round( (distance*60000000.0) / (feedrate*(float)total_steps) );	
}


inline bool cartesian_dda::xCanStep(long current, long target, bool dir)
{
//stop us if we're on target

	if (target == current)
		return false;

//stop us if we're home and still going lower

#if ENDSTOPS_MIN_ENABLED == 1
#if X_ENDSTOP_INVERTING
	if(!dir && !digitalRead(X_MIN_PIN) )
        {
                zeroHit.x = current;
		return false;
        }
#else
	if(!dir && digitalRead(X_MIN_PIN) )
        {
                zeroHit.x = current;
		return false;
        }
#endif
#endif

//stop us if we're at max and still going higher

#if ENDSTOPS_MAX_ENABLED == 1
#if X_ENDSTOP_INVERTING
	if(dir && !digitalRead(X_MAX_PIN) )
		return false;
#else
	if(!dir && digitalRead(X_MAX_PIN) )
		return false;
#endif
#endif

// All OK - we can step
  
	return true;
}

inline bool cartesian_dda::yCanStep(long current, long target, bool dir)
{
//stop us if we're on target

	if (target == current)
		return false;

//stop us if we're home and still going lower

#if ENDSTOPS_MIN_ENABLED == 1
#if Y_ENDSTOP_INVERTING
	if(!dir && !digitalRead(Y_MIN_PIN) )
        {
                zeroHit.y = current;
		return false;
        }
#else
	if(!dir && digitalRead(Y_MIN_PIN) )
        {
                zeroHit.y = current;
		return false;
        }
#endif
#endif

//stop us if we're at max and still going higher

#if ENDSTOPS_MAX_ENABLED == 1
#if Y_ENDSTOP_INVERTING
	if(dir && !digitalRead(Y_MAX_PIN) )
		return false;
#else
	if(!dir && digitalRead(Y_MAX_PIN) )
		return false;
#endif
#endif

// All OK - we can step
  
	return true;
}

inline bool cartesian_dda::zCanStep(long current, long target, bool dir)
{
//stop us if we're on target

	if (target == current)
		return false;

//stop us if we're home and still going lower

#if ENDSTOPS_MIN_ENABLED == 1
#if Z_ENDSTOP_INVERTING
	if(!dir && !digitalRead(Z_MIN_PIN) )
        {
                zeroHit.z = current;
		return false;
        }
#else
	if(!dir && digitalRead(Z_MIN_PIN) )
        {
                zeroHit.z = current;
		return false;
        }
#endif
#endif

//stop us if we're at max and still going higher

#if ENDSTOPS_MAX_ENABLED == 1
#if Z_ENDSTOP_INVERTING
	if(dir && !digitalRead(Z_MAX_PIN) )
		return false;
#else
	if(!dir && digitalRead(Z_MAX_PIN) )
		return false;
#endif
#endif

// All OK - we can step
  
	return true;
}

inline bool cartesian_dda::eCanStep(long current, long target, bool dir)
{
//stop us if we're on target

	return !(target == current);
}

inline bool cartesian_dda::fCanStep(long current, long target, bool dir)
{
//stop us if we're on target

	return !(target == current);
}
#endif
