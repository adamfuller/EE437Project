//#include <SoftwareSerial.h>

#define RECV_PIN  12
#define ECHO_PIN  A4  
#define TRIG_PIN  A5
#define ENA_PIN  5
#define ENB_PIN  11
#define IN1_PIN  6
#define IN2_PIN  7
#define IN3_PIN  8
#define IN4_PIN  9

int pinToChange;
String btOutput;

//SoftwareSerial bluetooth(7, 8);


int getDistance() {
  digitalWrite(TRIG_PIN, LOW);
  delayMicroseconds(2);
  digitalWrite(TRIG_PIN, HIGH);
  delayMicroseconds(10);
  digitalWrite(TRIG_PIN, LOW);
  return (int)pulseIn(ECHO_PIN, HIGH) / 58;
}

String getBtData(){
  String data = "";
  char input;
  while (Serial.available() && (( input = Serial.read() ) != '_' )) data += input;
  return data;
}

void adjustOutput(int pin, String val){
//  Serial.print("adjustOutput: ");
//  Serial.print(pin);
  
  val.toUpperCase();
  bool enable = val.indexOf("TRUE") >= 0 || val.indexOf("HIGH") >= 0;
  if (enable){
//    Serial.println(" HIGH");
    digitalWrite(pin, HIGH);
  } else {
//    Serial.println(" LOW");
    digitalWrite(pin, LOW);
  }
}

void adjustDutyCycle(int pin, double val){
//  Serial.print("adjustDutyCycle: ");
//  Serial.print(pin);
//  Serial.print(" ");
  
  
  if (val > 1.0){
    analogWrite(pin, val);
//    Serial.println(val);
  } else {
    analogWrite(pin, (int)(val * 255) );
//    Serial.println((int) (val * 255) );
  }
}

void setup() {
  // put your setup code here, to run once:
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
  pinToChange = ENA_PIN;
  btOutput += getBtData();

  if (btOutput.indexOf("_") < 0) return;
  if (btOutput != NULL || btOutput != ""){
    Serial.print("btOutput: " );
    Serial.println(btOutput);
//    Serial.print("Index of EN: " );
//    Serial.println(btOutput.indexOf("EN"));
    if (btOutput.indexOf("EN") >= 0){
      // Control enable pins
      
      
      if (btOutput.indexOf("B") >= 0) pinToChange = ENB_PIN;
      
      String indicatorString = btOutput.substring(3, btOutput.length());
      adjustOutput(pinToChange, indicatorString);
      
    } else {
      // One of the controller's INX pins
      
      int pinNum = btOutput.substring(2, 3).toInt();
      String valString = btOutput.substring(3, btOutput.length());
      double val = valString.toDouble();
      
      switch(pinNum){
        case 1:
          pinToChange = IN1_PIN;
          break;
        case 2:
          pinToChange = IN2_PIN;
          break;
        case 3:
          pinToChange = IN3_PIN;
          break;
         case 4:
          pinToChange = IN4_PIN;
          break;
         default:
          break;
      }

      adjustDutyCycle(pinToChange, val);
      
    }
  }
  btOutput = "";
}
