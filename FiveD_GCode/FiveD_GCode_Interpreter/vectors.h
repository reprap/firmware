// Structs to hold points in 5D space.


#ifndef VECTORS_H
#define VECTORS_H

#define round(x) ((x)>=0?(long)((x)+0.5):(long)((x)-0.5))

struct LongPoint;

// Real-world units
struct FloatPoint
{
	float x;   // Coordinate axes
	float y;
	float z;
        float e;   // Extrude length
        float f;   // Feedrate
        FloatPoint();
        FloatPoint(const LongPoint& a);
};

inline FloatPoint::FloatPoint()
{
  x = 0;
  y = 0;
  z = 0;
  e = 0;
  f = 0;
}  


inline FloatPoint operator+(const FloatPoint& a, const FloatPoint& b)
{
  FloatPoint result;
  result.x = a.x + b.x;
  result.y = a.y + b.y;
  result.z = a.z + b.z;
  result.e = a.e + b.e;
  result.f = a.f + b.f;
  return result;
}  

inline FloatPoint operator-(const FloatPoint& a, const FloatPoint& b)
{
  FloatPoint result;
  result.x = a.x - b.x;
  result.y = a.y - b.y;
  result.z = a.z - b.z;
  result.e = a.e - b.e;
  result.f = a.f - b.f;
  return result;
} 


// NB - the next gives neither the scalar nor the vector product

inline FloatPoint operator*(const FloatPoint& a, const FloatPoint& b)
{
  FloatPoint result;
  result.x = a.x * b.x;
  result.y = a.y * b.y;
  result.z = a.z * b.z;
  result.e = a.e * b.e;
  result.f = a.f * b.f;
  return result;
} 

// Can't use fabs for this as it's defined somewhere in a #define

inline FloatPoint fabsv(const FloatPoint& a)
{
  FloatPoint result;
  result.x = fabs(a.x);
  result.y = fabs(a.y);
  result.z = fabs(a.z);
  result.e = fabs(a.e);
  result.f = fabs(a.f);
  return result;
} 


// Integer numbers of steps
struct LongPoint
{
	long x;   // Coordinates
	long y;
	long z;
        long e;   // Extrusion
        long f;   // Feedrate
};

inline LongPoint operator+(const LongPoint& a, const LongPoint& b)
{
  LongPoint result;
  result.x = a.x + b.x;
  result.y = a.y + b.y;
  result.z = a.z + b.z;
  result.e = a.e + b.e;
  result.f = a.f + b.f;
  return result;
}  

inline LongPoint operator-(const LongPoint& a, const LongPoint& b)
{
  LongPoint result;
  result.x = a.x - b.x;
  result.y = a.y - b.y;
  result.z = a.z - b.z;
  result.e = a.e - b.e;
  result.f = a.f - b.f;
  return result;
} 


inline LongPoint absv(const LongPoint& a)
{
  LongPoint result;
  result.x = abs(a.x);
  result.y = abs(a.y);
  result.z = abs(a.z);
  result.e = abs(a.e);
  result.f = abs(a.f);
  return result;
} 


inline LongPoint roundv(const FloatPoint& a)
{
  LongPoint result;
  result.x = round(a.x);
  result.y = round(a.y);
  result.z = round(a.z);
  result.e = round(a.e);
  result.f = round(a.f);
  return result;
} 

inline LongPoint to_steps(const FloatPoint& units, const FloatPoint& position)
{
        return roundv(units*position);
}

inline FloatPoint from_steps(const FloatPoint& units, const LongPoint& position)
{
        FloatPoint inv = units;
        inv.x = 1.0/inv.x;
        inv.y = 1.0/inv.y;
        inv.z = 1.0/inv.z;
        inv.e = 1.0/inv.e;
        inv.f = 1.0/inv.f;
        return roundv(inv*position);
}

inline FloatPoint::FloatPoint(const LongPoint& a)
{
  x = a.x;
  y = a.y;
  z = a.z;
  e = a.e;
  f = a.f;
}  

#endif
