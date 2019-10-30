
  /*
   * Swiching from the for-loop to purely if-statements
   * reduced the over all time to only a third.
   * From 546 uS to 172 uS, for the for-loop and if-statements respectively
   * 
   * By switching the extent calculations to only use integer math
   * the time was reduced further 
   * from 172uS to 84 uS
   * 
   * By changing the steeringAngle calculations to use integer math
   * and only use 1 byte of precision the time was reduced
   * from 84 uS to 80uS
   * The program at this point is approximately 6 times as fast
   *    (when not checking the distance sensor)
   * 
   */
   
#include <Servo.h>

#define ECHO_PIN  A4 // PC4
#define TRIG_PIN  A5 // PC5
#define ENA_PIN   5
#define ENB_PIN   11
#define IN1_PIN   6 // Right forward
#define IN2_PIN   7 // Right backward
#define IN3_PIN   8 // Left backward
#define IN4_PIN   9 // Left forward
#define SERVO_PIN     3 

// asm(" sbi 11, 7") sets bit 7 of address 11

#define IN1_HIGH asm(" sbi 11, 6") //PORTD|=0x40 // 0b0100 0000
#define IN1_LOW asm(" cbi 11, 6") //PORTD&=0xBF  // 0b1011 1111

#define IN2_HIGH asm(" sbi 11, 7") //PORTD|=0x80 // 0b1000 0000
#define IN2_LOW asm(" cbi 11, 7") //PORTD&=0x7F  // 0b0111 1111

#define IN3_HIGH asm(" sbi 5, 0")//PORTB|=0x01 // 0b0000 0001
#define IN3_LOW asm(" cbi 5, 0")//PORTB&=0xFE  // 0b1111 1110

#define IN4_HIGH asm(" sbi 5, 1")//PORTB|=0x02 // 0b0000 0010
#define IN4_LOW asm(" cbi 5, 1")//PORTB&=0xFD  // 0b1111 1101

#define ENA_HIGH asm(" sbi 11, 5")//PORTD|=0x08 // 0b0000 1000
#define ENA_LOW asm(" cbi 11, 5")//PORTD&=0xF7  // 0b1111 0111

#define ENB_HIGH asm(" sbi 5, 3")//PORTB|=0x98 // 0b0000 1000
#define ENB_LOW asm(" cbi 5, 3")//PORTB&=0xF7  // 0b1111 0111

#define TRIG_HIGH asm(" sbi 8, 5")//PORTC|=0x20 // 0b0010 0000
#define TRIG_LOW asm(" cbi 8, 5")//PORTC&=0xDF  // 0b1101 1111

#define START_LOOP asm("_loopStart:");
#define RESTART_LOOP asm("  JMP _loopStart");

#define START_PULSE_CHECK asm("_pulseCheckStart:");
#define SKIP_TO_PULSE_CHECK asm(" JMP _pulseCheckStart");

uint8_t btOutput;
uint8_t cache[8] = {0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00};
Servo servo;
bool shouldBrake = false;

uint8_t cycleCount = 0;
uint8_t ledState = 0xFF;

bool pulseSent = false;
unsigned long pulseStart = 0;

bool sendPulse(){
  TRIG_LOW;
  delayMicroseconds(2);
  TRIG_HIGH;
  delayMicroseconds(10);
  TRIG_LOW;
  delayMicroseconds(2);
  pulseSent = true;
  pulseStart = micros();
}

void brake(){
  ENA_LOW;
  ENB_LOW;
  IN1_LOW;
  IN2_LOW;
  IN3_LOW;
  IN4_LOW;
}

void spinRight(){
  ENA_HIGH;
  ENB_HIGH;
  IN1_LOW;
  IN2_HIGH;
  IN3_LOW;
  IN4_HIGH;
}

void spinLeft(){
  ENA_HIGH;
  ENB_HIGH;
  IN1_HIGH;
  IN2_LOW;
  IN3_HIGH;
  IN4_LOW;
}

uint8_t steeringAngle()
{
  uint8_t leftPower = (cache[0x06] & 0x1F);
  uint8_t rightPower = (cache[0x05] & 0x1F);

  return (rightPower > leftPower) 
  ? (87 + (rightPower - leftPower) * 3) 
  : (93 - (leftPower - rightPower) * 3);
}

void performTask(uint8_t task){
  if (task == 0x00) brake();
  else if (task == 0x01) spinRight();
  else if (task == 0x02) spinLeft();
  else if (task == 0x0F) cache[0x07] = 0x00;
}

void setup() {
  Serial.begin(9600);

  // Digital inputs
  pinMode(ECHO_PIN, INPUT);

  // Digital outputs
  pinMode(TRIG_PIN, OUTPUT);
  pinMode(IN1_PIN, OUTPUT);
  pinMode(IN2_PIN, OUTPUT);
  pinMode(IN3_PIN, OUTPUT);
  pinMode(IN4_PIN, OUTPUT);
  
  // Analog outputs
  pinMode(ENA_PIN, OUTPUT);
  pinMode(ENB_PIN, OUTPUT);

  pinMode(LED_BUILTIN, OUTPUT);

  digitalWrite(ENA_PIN, HIGH);
  digitalWrite(ENB_PIN, HIGH);


  // Servo setup
  servo.attach(SERVO_PIN);
}

int main(void){

  init();

  setup();

  START_LOOP;
  
  if (cycleCount == 0){
    digitalWrite(LED_BUILTIN, ledState);
    ledState = ~ledState;
  }
  cycleCount++;

  // Check for next command(s)
  for (uint8_t i = 0; i<10 && Serial.available(); i++){
    btOutput = Serial.read();
    cache[(btOutput & 0xE0) >> 5] = btOutput;
  }

  if (shouldBrake || !cycleCount%3){
    
    if (shouldBrake){
      // Ensure we aren't attempting to go in reverse
      if ( !(cache[0x07] != 0xE0 && ((cache[0x02]&0x1F) || (cache[0x03]&0x1F))) ){
        brake();

        if (!pulseSent) sendPulse(); 
        SKIP_TO_PULSE_CHECK;
      }
    }

    if (!pulseSent) sendPulse();
  }

  servo.write(steeringAngle());

  if(cache[0x07] & 0xE0){
    // IN1 has been updated
    performTask(cache[0x07] & 0x1F);
//    Serial.print(cache[0x07]);

    // Set the command as used by clearing the last 3 bits
//    cache[0x07] &= 0x1F;
    
    SKIP_TO_PULSE_CHECK;
  }

  if (cycleCount < ((cache[0x05] & 0x1F) * 8)) ENA_HIGH;
  else ENA_LOW;

  if (cycleCount < ((cache[0x06] & 0x1F) * 8)) ENB_HIGH;
  else ENB_LOW;

  if(cache[0x01] & 0xE0){
    // IN1 has been updated
    if (cache[0x01] & 0x1F) IN1_HIGH;
    else IN1_LOW;
//    Serial.print(cache[0x1]);

    // Set the command as used by clearing the last 3 bits
    cache[0x01] &= 0x1F;
  }

  if(cache[0x02] & 0xE0){
    // IN2 has been updated
    if (cache[0x02] & 0x1F) IN2_HIGH;
    else IN2_LOW;
//    Serial.print(cache[0x02]);

    // Set the command as used by clearing the last 3 bits
    cache[0x02] &= 0x1F;
  }

  if(cache[0x03] & 0xE0){
    // IN3 has been updated
    if (cache[0x03] & 0x1F) IN3_HIGH;
    else IN3_LOW;
//    Serial.print(cache[0x03]);

    // Set the command as used by clearing the last 3 bits
    cache[0x03] &= 0x1F;
  }

  if(cache[0x04] & 0xE0){
    // IN4 has been updated
    if (cache[0x04] & 0x1F) IN4_HIGH;
    else IN4_LOW;
//    Serial.print(cache[0x04]);

    // Set the command as used by clearing the last 3 bits
    cache[0x04] &= 0x1F;
  }
  
  START_PULSE_CHECK;
  
  if (PINC & 0x10 && pulseSent){
    unsigned long width = 0;
    // wait for the pulse to stop
   while (PINC & 0x10 && width++ < 1583);

   // 1200 Is the braking limit of about 20cm
   shouldBrake = width < 1200;
   
   pulseSent = false;
  }

  if (micros() - pulseStart > 2583){
    pulseSent = false;
  }

  RESTART_LOOP;
  return 0;
}
