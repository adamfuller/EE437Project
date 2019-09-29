#define RECV_PIN  12
#define ECHO_PIN  A4  
#define TRIG_PIN  A5
#define ENA_PIN  5
#define ENB_PIN  11
#define IN1_PIN  6 // Right forward
#define IN2_PIN  7 // Right backward
#define IN3_PIN  8 // Left backward
#define IN4_PIN  9 // Left forward

int pinToChange;
int btOutput;
int index = -1;
int intent, extent;
int extentCache[10] = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0};
int extentRawCache[10] = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0};
int intentCache[10] = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0};

int getDistance() {
  digitalWrite(TRIG_PIN, LOW);
  delayMicroseconds(2);
  digitalWrite(TRIG_PIN, HIGH);
  delayMicroseconds(10);
  digitalWrite(TRIG_PIN, LOW);
  return (int)pulseIn(ECHO_PIN, HIGH) / 58;
}

void brake(){
  analogWrite(ENA_PIN, 0);
  analogWrite(ENB_PIN, 0);
  analogWrite(IN1_PIN, 0);
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
      spinLeft();
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
}

void loop() {
  // put your main code here, to run repeatedly:
  int dist = getDistance();
  
  // Check if we should brake.
  bool shouldBrake = abs(dist) <= 20;

  // Check for next command(s)
  while (Serial.available() && index < 9){
    index++;
    btOutput = Serial.read();
    intentCache[index] = (btOutput & 0xE0) >> 5;
    extentCache[index] = (int)(((btOutput & 0x1F) / 31.0) * 255 );
    extentRawCache[index] = btOutput & 0x1F;
  }

  for (int i = index; i >= 0; i--){
    intent = intentCache[index];
    extent = extentCache[index];
    
    switch (intent){
      case 0x01:
        // IN1
        if (shouldBrake){
          analogWrite(IN1_PIN, 0);
        } else {
          analogWrite(IN1_PIN, extent);
        }
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
        if (shouldBrake){
          analogWrite(IN4_PIN, 0);
        } else {
          analogWrite(IN4_PIN, extent);
        }
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
        performTask(extentRawCache[index]);
        index = -1;
        return;
        break;
      default:
        break;
    }
  }
  
  index = -1;
}
