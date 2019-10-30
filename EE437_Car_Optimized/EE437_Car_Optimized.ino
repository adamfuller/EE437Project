
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

#define TRIG_HIGH asm(" sbi 8, 5")//PORTC|=0x20 // 0b0010 0000
#define TRIG_LOW asm(" cbi 8, 5")//PORTC&=0xDF  // 0b1101 1111

#define START_LOOP asm("_loopStart:");
#define RESTART_LOOP asm("  JMP _loopStart");

uint8_t btOutput;
uint8_t cache[8] = {0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00};
bool checkedLastTime = false;
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
  analogWrite(ENA_PIN, 0);
  analogWrite(ENB_PIN, 0);
  IN1_LOW;
  IN2_LOW;
  IN3_LOW;
  IN4_LOW;
}

void spinRight(){
  analogWrite(ENA_PIN, 255);
  analogWrite(ENB_PIN, 255);
  IN1_LOW;
  IN2_HIGH;
  IN3_LOW;
  IN4_HIGH;
}

void spinLeft(){
  analogWrite(ENA_PIN, 255);
  analogWrite(ENB_PIN, 255);
  IN1_HIGH;
  IN2_LOW;
  IN3_HIGH;
  IN4_LOW;
}

/**
 * Returns the angle at which the car should be heading
 * between 20 and 160 degrees
 */
//uint8_t steeringAngle(){
//  uint8_t leftPower = (cache[0x06] & 0x1F) * 8 ;
//  uint8_t rightPower = (cache[0x05] & 0x1F) * 8 ;
//  if (leftPower == rightPower) return 90;
//  return (uint8_t)(20 + (int) (rightPower * 140) / (int) (rightPower + leftPower));
//}

uint8_t steeringAngle()
{
  uint8_t leftPower = (cache[0x06] & 0x1F);
  uint8_t rightPower = (cache[0x05] & 0x1F);

  return (rightPower > leftPower) 
  ? (87 + (rightPower - leftPower) * 3) 
  : (93 - (leftPower - rightPower) * 3);
}

void performTask(uint8_t task){
  switch (task){
    case 0x00:
      brake();
      break;
    case 0x01:
      spinRight();
      break;
    case 0x02:
      spinLeft();
      break;
    default:
      break;
  }
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
        asm(" JMP _checkForPulse");
      }
    }

    if (!pulseSent) sendPulse();
  }
//  checkedLastTime = !checkedLastTime;

  servo.write(steeringAngle());

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

  if(cache[0x05] & 0xE0){
    // ENA has been updated
    analogWrite(ENA_PIN, (cache[0x05] & 0x1F) * 8);
//    Serial.print(cache[0x05]);

    // Set the command as used by clearing the last 3 bits
    cache[0x05] &= 0x1F;
  }

  if(cache[0x06] & 0xE0){
    // ENB has been updated
    analogWrite(ENB_PIN, (cache[0x06] & 0x1F) * 8);
//    Serial.print(cache[0x06]);

    // Set the command as used by clearing the last 3 bits
    cache[0x06] &= 0x1F;
  }

  if(cache[0x07] & 0xE0){
    // IN1 has been updated
    performTask(cache[0x07] & 0x1F);
//    Serial.print(cache[0x07]);

    // Set the command as used by clearing the last 3 bits
    cache[0x07] &= 0x1F;
  }

  
  asm("_checkForPulse:");
  if (PINC & 0x10 && pulseSent){
    unsigned long width = 0;
    // wait for the pulse to stop
   while (PINC & 0x10 && width++ < 1583);
//   Serial.println(width * 0.034 / 2);

   // 1200 Is the braking limit of about 20cm
   shouldBrake = width < 1200;
   
//   serialEventRun();
   pulseSent = false;
  }

  if (micros() - pulseStart > 2583){
    pulseSent = false;
  }

  RESTART_LOOP;
  return 0;
}
