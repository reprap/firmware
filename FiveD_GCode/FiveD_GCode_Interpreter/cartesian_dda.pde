#include <stdio.h>
#include "configuration.h"
#include "pins.h"
#include "extruder.h"
#include "vectors.h"
#include "cartesian_dda.h"



cartesian_dda::cartesian_dda()
{
        live = false;
        nullmove = false;
        
// Default is going forward
  
        x_direction = true;
        y_direction = true;
        z_direction = true;
        e_direction = true;
        f_direction = true;
        
// Default to the origin and not going anywhere
  
	target_position.x = 0.0;
	target_position.y = 0.0;
	target_position.z = 0.0;
	target_position.e = 0.0;
        target_position.f = SLOW_XY_FEEDRATE;

// Set up the pin directions
  
	pinMode(X_STEP_PIN, OUTPUT);
	pinMode(X_DIR_PIN, OUTPUT);

	pinMode(Y_STEP_PIN, OUTPUT);
	pinMode(Y_DIR_PIN, OUTPUT);

	pinMode(Z_STEP_PIN, OUTPUT);
	pinMode(Z_DIR_PIN, OUTPUT);

#if MOTHERBOARD > 0
	pinMode(X_ENABLE_PIN, OUTPUT);
	pinMode(Y_ENABLE_PIN, OUTPUT);
	pinMode(Z_ENABLE_PIN, OUTPUT);
#endif

//turn the motors off at the start.

	disable_steppers();

#if ENDSTOPS_MIN_ENABLED == 1
	pinMode(X_MIN_PIN, INPUT);
	pinMode(Y_MIN_PIN, INPUT);
	pinMode(Z_MIN_PIN, INPUT);
#endif

#if ENDSTOPS_MAX_ENABLED == 1
	pinMode(X_MAX_PIN, INPUT);
	pinMode(Y_MAX_PIN, INPUT);
	pinMode(Z_MAX_PIN, INPUT);
#endif
	
        // Default units are mm
        
        set_units(true);
}

// Switch between mm and inches

void cartesian_dda::set_units(bool um)
{
  using_mm = um;
  set_units();
}


void cartesian_dda::set_units()
{
    if(using_mm)
    {
      units.x = X_STEPS_PER_MM;
      units.y = Y_STEPS_PER_MM;
      units.z = Z_STEPS_PER_MM;
      units.e = ex[extruder_in_use]->stepsPerMM();
      units.f = 1.0;
    } else
    {
      units.x = X_STEPS_PER_INCH;
      units.y = Y_STEPS_PER_INCH;
      units.z = Z_STEPS_PER_INCH;
      units.e = ex[extruder_in_use]->stepsPerMM()*INCHES_TO_MM;
      units.f = 1.0;  
    }
}


void cartesian_dda::set_target(const FloatPoint& p)
{
        target_position = p;
        nullmove = false;
        
	//figure our deltas.

        delta_position = fabsv(target_position - where_i_am);
        
        // The feedrate values refer to distance in (X, Y, Z) space, so ignore e and f
        // values unless they're the only thing there.

        FloatPoint squares = delta_position*delta_position;
        distance = squares.x + squares.y + squares.z;
        // If we are 0, only thing changing is e
        if(distance < SMALL_DISTANCE2)
          distance = squares.e;
        // If we are still 0, only thing changing is f
        if(distance < SMALL_DISTANCE2)
          distance = squares.f;
        distance = sqrt(distance);          
                                                                                   			
	//set our steps current, target, and delta

        current_steps = to_steps(units, where_i_am);
	target_steps = to_steps(units, target_position);
	delta_steps = absv(target_steps - current_steps);

	// find the dominant axis.
        // NB we ignore the f values here, as it takes no time to take a step in time :-)

        total_steps = max(delta_steps.x, delta_steps.y);
        total_steps = max(total_steps, delta_steps.z);
        total_steps = max(total_steps, delta_steps.e);
  
        // If we're not going anywhere, flag the fact
        
        if(total_steps == 0)
        {
          nullmove = true;
          where_i_am = p;
          return;
        }    

#ifndef ACCELERATION_ON
        current_steps.f = target_steps.f;
#endif

        delta_steps.f = abs(target_steps.f - current_steps.f);
        
        // Rescale the feedrate so it doesn't take lots of steps to do
        
        t_scale = 1;
        if(delta_steps.f > total_steps)
        {
            t_scale = delta_steps.f/total_steps;
            if(t_scale >= 3)
            {
              target_steps.f = target_steps.f/t_scale;
              current_steps.f = current_steps.f/t_scale;
              delta_steps.f = abs(target_steps.f - current_steps.f);
              if(delta_steps.f > total_steps)
                total_steps =  delta_steps.f;
            } else
            {
              t_scale = 1;
              total_steps =  delta_steps.f;
            }
        } 
        	
	//what is our direction?
        
	x_direction = (target_position.x >= where_i_am.x);
	y_direction = (target_position.y >= where_i_am.y);
	z_direction = (target_position.z >= where_i_am.z);
        e_direction = (target_position.e >= where_i_am.e);
	f_direction = (target_position.f >= where_i_am.f);


	dda_counter.x = -total_steps/2;
	dda_counter.y = dda_counter.x;
	dda_counter.z = dda_counter.x;
        dda_counter.e = dda_counter.x;
        dda_counter.f = dda_counter.x;
  
        where_i_am = p;
        
        return;        
}

// This function is called by an interrupt.  Consequently interrupts are off for the duration
// of its execution.  Consequently it has to be as optimised and as fast as possible.

void cartesian_dda::dda_step()
{  
  if(!live)
   return;

  do
  {
                x_can_step = xCanStep(current_steps.x, target_steps.x, x_direction);
		y_can_step = yCanStep(current_steps.y, target_steps.y, y_direction);
                z_can_step = zCanStep(current_steps.z, target_steps.z, z_direction);
                e_can_step = eCanStep(current_steps.e, target_steps.e, e_direction);
                f_can_step = fCanStep(current_steps.f, target_steps.f, f_direction);
                
                real_move = false;
                
		if (x_can_step)
		{
			dda_counter.x += delta_steps.x;
			
			if (dda_counter.x > 0)
			{
				do_x_step();
                                real_move = true;
				dda_counter.x -= total_steps;
				
				if (x_direction)
					current_steps.x++;
				else
					current_steps.x--;
			}
		}

		if (y_can_step)
		{
			dda_counter.y += delta_steps.y;
			
			if (dda_counter.y > 0)
			{
				do_y_step();
                                real_move = true;
				dda_counter.y -= total_steps;

				if (y_direction)
					current_steps.y++;
				else
					current_steps.y--;
			}
		}
		
		if (z_can_step)
		{
			dda_counter.z += delta_steps.z;
			
			if (dda_counter.z > 0)
			{
				do_z_step();
                                real_move = true;
				dda_counter.z -= total_steps;
				
				if (z_direction)
					current_steps.z++;
				else
					current_steps.z--;
			}
		}

		if (e_can_step)
		{
			dda_counter.e += delta_steps.e;
			
			if (dda_counter.e > 0)
			{
                                
				do_e_step();
                                real_move = true;
				dda_counter.e -= total_steps;
				
				if (e_direction)
					current_steps.e++;
				else
					current_steps.e--;
			}
		}
		
		if (f_can_step)
		{
			dda_counter.f += delta_steps.f;
			
			if (dda_counter.f > 0)
			{
				dda_counter.f -= total_steps;
				if (f_direction)
					current_steps.f++;
				else
					current_steps.f--;
                                feed_change = true;
			} else
                                feed_change = false;
		}

				
      // wait for next step.
      // Use milli- or micro-seconds, as appropriate
      // If the only thing that changed was f keep looping
  
                if(real_move && feed_change)
                {
                  timestep = t_scale*current_steps.f;
                  timestep = calculate_feedrate_delay((float) timestep);
                  setTimer(timestep);
                }
                feed_change = false;
                
  } while (!real_move && f_can_step);
  
  live = (x_can_step || y_can_step || z_can_step  || e_can_step || f_can_step);

// Wrap up at the end of a line

  if(!live)
  {
      disable_steppers();
      setTimer(DEFAULT_TICK);
  }    
  
}


// Run the DDA

void cartesian_dda::dda_start()
{    
  // Set up the DDA
  
  if(nullmove)
    return;

//set our direction pins as well
   
  byte d = 1;
  	
#if INVERT_X_DIR == 1
  if(x_direction)
    d = 0;
#else
  if(!x_direction)
    d = 0;	
#endif
  digitalWrite(X_DIR_PIN, d);
        
  d = 1;
    
#if INVERT_Y_DIR == 1
  if(y_direction)
    d = 0;
#else
  if(!y_direction)
    d = 0;	
#endif
  digitalWrite(Y_DIR_PIN, d);
        
  d = 1;
    
#if INVERT_Z_DIR == 1
  if(z_direction)
     d = 0;
#else
  if(!z_direction)
     d = 0;	
#endif
  digitalWrite(Z_DIR_PIN, d);


  ex[extruder_in_use]->setDirection(e_direction);
  
//turn on steppers to start moving =)
    
  enable_steppers();

  setTimer(DEFAULT_TICK);
  live = true;
  feed_change = true; // force timer setting on the first call to dda_step()
}




void cartesian_dda::enable_steppers()
{
#if MOTHERBOARD > 0
  if(delta_steps.x)
    digitalWrite(X_ENABLE_PIN, ENABLE_ON);
  if(delta_steps.y)    
    digitalWrite(Y_ENABLE_PIN, ENABLE_ON);
  if(delta_steps.z)
    digitalWrite(Z_ENABLE_PIN, ENABLE_ON);
  if(delta_steps.e)
    ex[extruder_in_use]->enableStep();
#endif  
}



void cartesian_dda::disable_steppers()
{
#if MOTHERBOARD > 0
	//disable our steppers
#if DISABLE_X
	digitalWrite(X_ENABLE_PIN, !ENABLE_ON);
#endif
#if DISABLE_Y
	digitalWrite(Y_ENABLE_PIN, !ENABLE_ON);
#endif
#if DISABLE_Z
        digitalWrite(Z_ENABLE_PIN, !ENABLE_ON);
#endif

        ex[extruder_in_use]->disableStep();
        
#endif
}

void cartesian_dda::shutdown()
{
  live = false;
  nullmove = false;
  disable_steppers();
}

