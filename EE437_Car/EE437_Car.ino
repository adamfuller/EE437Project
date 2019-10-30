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

uint8_t btOutput;
int intent, extent;
uint8_t cache[8] = {0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00};
bool checkedLastTime = false;
bool shouldBrake;
Servo servo;

int getDistance() {
  digitalWrite(TRIG_PIN, LOW);
  delayMicroseconds(2);
  digitalWrite(TRIG_PIN, HIGH);
  delayMicroseconds(10);
  digitalWrite(TRIG_PIN, LOW);
  return (int)pulseIn(ECHO_PIN, HIGH, 1583) / 58;
}

void brake(){
  analogWrite(ENA_PIN, 0);
  analogWrite(ENB_PIN, 0);
  analogWrite(IN1_PIN, 0);
//  PORTD&=0x3F; // Set IN2 and IN3 low
  analogWrite(IN2_PIN, 0);
  analogWrite(IN3_PIN, 0);
  analogWrite(IN4_PIN, 0);
}

void spinRight(){
  analogWrite(ENA_PIN, 255);
  analogWrite(ENB_PIN, 255);
  analogWrite(IN1_PIN, 0);
  analogWrite(IN2_PIN, 255);
  analogWrite(IN3_PIN, 0);
  analogWrite(IN4_PIN, 255);
}

void spinLeft(){
  analogWrite(ENA_PIN, 255);
  analogWrite(ENB_PIN, 255);
  analogWrite(IN1_PIN, 255);
  analogWrite(IN2_PIN, 0);
  analogWrite(IN3_PIN, 255);
  analogWrite(IN4_PIN, 0);
}

int steeringAngle(){
  int leftPower = (int)((((cache[0x06]) & 0x1F) / 31.0) * 255 );
  int rightPower = (int)((((cache[0x05]) & 0x1F) / 31.0) * 255 );
  if (leftPower == rightPower) return 90;
  return (int)((rightPower * 1.0 / (rightPower + leftPower) * 1.0) * 178) + 1;
}

void performTask(int task){
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
  pinMode(ECHO_PIN, INPUT);
  pinMode(TRIG_PIN, OUTPUT);
  pinMode(IN1_PIN, OUTPUT);
  pinMode(IN2_PIN, OUTPUT);
  pinMode(IN3_PIN, OUTPUT);
  pinMode(IN4_PIN, OUTPUT);
  pinMode(ENA_PIN, OUTPUT);
  pinMode(ENB_PIN, OUTPUT);
  servo.attach(SERVO_PIN);

  pinMode(LED_BUILTIN, OUTPUT);
}

void loop() {
  // Only check to brake every other time
  if (!checkedLastTime){
    int dist = getDistance();  
    // Check if we should brake.
    shouldBrake = abs(dist) <= 20 && abs(dist) != 0;
  }
  
  checkedLastTime = !checkedLastTime;

  // Check for next command(s)
  for (int i = 0; i< 10; i++){
    if (Serial.available()){
      btOutput = Serial.read();
      cache[(btOutput & 0xE0) >> 5] = btOutput;
    } else {
      break;
    }
  }

  if (shouldBrake){

    // Ensure we shouldn't be braking or going in reverse
    if ( cache[0x07] != 0xE0 && (cache[0x02]&0x1F != 0x00 || cache[0x03]&0x1F != 0x00) ){
      analogWrite(IN2_PIN, (int)((((cache[0x02]) & 0x1F) / 31.0) * 255 ));
      analogWrite(IN3_PIN, (int)((((cache[0x03]) & 0x1F) / 31.0) * 255 ));
      analogWrite(ENA_PIN, (int)((((cache[0x05]) & 0x1F) / 31.0) * 255 ));
      analogWrite(ENB_PIN, (int)((((cache[0x06]) & 0x1F) / 31.0) * 255 ));
    } else {
      brake();
    }
    return;
  }

  servo.write(steeringAngle());

  for (intent = 0x01; intent < 0x08; intent++){
    extent = (int)((((cache[intent]) & 0x1F) / 31.0) * 255 );

    // Continue if this command is used (bits 5-7 cleared)
    if ((cache[intent] & 0xE0) == 0x00) continue;
    
    // return the command to the controller ( this is used to reduce sending repeat commands )
    Serial.print(cache[intent]);
    
    switch (intent){
      case 0x01:
        // IN1
        analogWrite(IN1_PIN, extent);
        break;
      case 0x02:
        // IN2
        analogWrite(IN2_PIN, extent);
        break;
      case 0x03:
        // IN3
        analogWrite(IN3_PIN, extent);
        break;
      case 0x04:
        // IN4
        analogWrite(IN4_PIN, extent);
        break;
      case 0x05:
        // ENA
        analogWrite(ENA_PIN, extent);
        break;
      case 0x06:
        // ENB
        analogWrite(ENB_PIN, extent);
        break;
       case 0x07:
        // Multi-command tasks
        performTask(cache[intent] & 0x1F);
        break;
      default:
        break;
    }
    // Set the command as used (clear bits 5-7)
    cache[intent] = cache[intent] & 0x1F;
  }
}
