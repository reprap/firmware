/*
 * Class to handle internal communications in the machine via RS485
 *
 * Adrian Bowyer 3 July 2009
 *
 */
 
 /* 
 
   A data packet looks like this:
 
     * * T F S A d a t a $
     
         0 1 2 3 4 . . .
     
   All these are printable characters.  * is the start character; it is not included in the string that is the result of 
   reading the packet.  There may be more than one to allow the comms to stabilise.  T (to) is the one-char name of the destination, 
   F (from) is the one-char name of the source, d a t a is a char string containing the message.  The checksum is S; this is
   calculated by adding all the bytes of the message (T F A and data, but not itself nor the start and end characters), taking the last six bits
   of the count, and adding that to the '0' character.  A is either RS485_ACK or RS485_ERROR.  The packet is terminated by a single $ character.    The total length of 
   a packet with all of that should not exceed RS485_BUF_LEN (defined in configuration.h) characters.  When a packet is received 
   the $ character is replaced by 0, thus forming a standard C string.
   
   Error returns: bool functions return true for success, false for failure.
 
 */
 
#ifndef INTERCOM_H
#define INTERCOM_H

#if MOTHERBOARD > 1

// Locations in a packet

#define P_TO 0
#define P_FROM 1
#define P_SUM 2
#define P_ACK 3
#define P_DATA 4

// Our RS485 driver and timeout

#if RS485_MASTER == 1
 #define rs485Interface Serial1
 #define TIMEOUT 3
#else
 #define rs485Interface Serial
 #define TIMEOUT (MILLI_CORRECTION*3)     // 3 ms, but TIMER0 has been messed with in the slave
#endif

// Communication speed

//#define RS485_BAUD 115200
#define RS485_BAUD 1000000

// The acknowledge, start, end, error and checksum characters

#define RS485_ACK 'A'
#define RS485_START '*'
#define RS485_END '$'
#define RS485_ERROR '!'
#define RS485_CHECK '0'

#define RS485_START_BYTES 3  // The number of start characters to send at the beginning of a packet
#define RS485_STABILISE 5    // Microseconds taken to stabilise after changing state
#define RS485_RETRIES 3      // Number of times to retry on error

// Size of the transmit and receive buffers

#define RS485_BUF_LEN 20

enum rs485_state
{
  RS485_TALK,
  RS485_TALK_TIMEOUT,
  RS485_LISTEN,
  RS485_LISTEN_TIMEOUT
};

class intercom
{
  public:
  
#if RS485_MASTER == 1
    intercom();
#else
    intercom(extruder* e);
#endif

// The master processing function.  Call this in a fast loop, or from a fast repeated interrupt

    void tick();

// Send string to device to and wait for a reply.

    char* sendPacketAndGetReply(char to, char* string);

// Send a packet and check it was received

    bool sendPacketAndCheckAcknowledgement(char to, char* string);
 
// We are busy if we are talking, or in the middle of receiving a packet

    bool busy(); 
  
  private:
  
    char inBuffer[RS485_BUF_LEN];
    volatile byte inPointer;
    char outBuffer[RS485_BUF_LEN];
    volatile byte outPointer;
    volatile bool inPacket;
    volatile bool packetReceived;
    volatile rs485_state state;
    //char reply[RS485_BUF_LEN];
    long wait_zero;
#if !(RS485_MASTER == 1)
    extruder* ex;
#endif

// Reset everything to the initial state

void reset();
  
// Reset the output buffer and its associated variables

void resetOutput();

// Reset the input buffer and its associated variables

void resetInput();

// The checksum for a string is the least-significant six bits of the sum
// of the string's bytes added to the character RS485_CHECK.  It can thus take
// one of sixty-four values, all printable.  This function sets the checsum byte
// in a string, assumed to be a packet.

void checksum(char* string);

// Check the checksum of a string

bool checkChecksum(char* string);

// Build a packet to device to from an input string.  See intercom.h for the
// packet structure.  ack should either be RS485_ACK or RS485_ERROR.

void buildPacket(char to, char ack, char* string);

// Switch to listen mode

bool listen();

// Switch to talk mode

bool talk();

// Something useful has happened; reset the timeout time

void resetWait();

// Have we waited too long for something to happen?

bool tooLong();

// Send string to device to.

bool queuePacket(char to, char ack, char* string);

// Wait for a packet to arrive.  The packet will be in inBuffer[ ]

bool waitForPacket();

// This function is called when a packet has been received

void processPacket();


// *********************************************************************************

// Error functions

// The output buffer has overflowed

void outputBufferOverflow();

// The input buffer has overflowed

void inputBufferOverflow();

// An attempt has been made to start sending a new message before
// the old one has been fully sent.

void talkCollision();

// An attempt has been made to get a new message before the old one has been
// fully received or before the last transmit is finished.

void listenCollision();

// An attempt has been made to queue a new message while the system is busy.

void queueCollision();

// (Part of) the data structure has become corrupted

void corrupt();

// We have been trying to send a message, but something is taking too long

void talkTimeout();

// We have been trying to receive a message, but something has been taking too long

void listenTimeout();

// We have been waiting too long for an incomming packet

void waitTimeout();

// Some queuing error has occurred

void queueError();

// Waiting for a packet error

void waitError();

// Dud checksum

void checksumError();

// Dud acknowledgement

void ackError();

};

extern intercom talker;

#endif
#endif
