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


#define IN1_HIGH asm(" sbi 11, 6") //PORTD|=0x40 // 0b0100 0000
#define IN1_LOW asm(" cbi 11, 6") //PORTD&=0xBF  // 0b1011 1111
#define IN1_ENABLE asm(" sbi 10, 6") //DDRD&=0x40  // 0b0100 0000

#define IN2_HIGH asm(" sbi 11, 7") //PORTD|=0x80 // 0b1000 0000
#define IN2_LOW asm(" cbi 11, 7") //PORTD&=0x7F  // 0b0111 1111
#define IN2_ENABLE asm(" sbi 10, 7") //DDRD&=0x40  // 0b1000 0000

#define IN3_HIGH asm(" sbi 5, 0")//PORTB|=0x01 // 0b0000 0001
#define IN3_LOW asm(" cbi 5, 0")//PORTB&=0xFE  // 0b1111 1110
#define IN3_ENABLE asm(" sbi 4, 0") //DDRB&=0x01  // 0b0000 0001

#define IN4_HIGH asm(" sbi 5, 1")//PORTB|=0x02 // 0b0000 0010
#define IN4_LOW asm(" cbi 5, 1")//PORTB&=0xFD  // 0b1111 1101
#define IN4_ENABLE asm(" sbi 4, 1") //DDRB&=0x02  // 0b1000 0000

#define ENA_HIGH asm(" sbi 11, 5")//PORTD|=0x08 // 0b0000 1000
#define ENA_LOW asm(" cbi 11, 5")//PORTD&=0xF7  // 0b1111 0111
#define ENA_ENABLE asm(" sbi 10, 5") //DDRD&=0x08  // 0b1000 0000

#define ENB_HIGH asm(" sbi 5, 3")//PORTB|=0x08 // 0b0000 1000
#define ENB_LOW asm(" cbi 5, 3")//PORTB&=0xF7  // 0b1111 0111
#define ENB_ENABLE asm(" sbi 4, 3") //DDRB&=0x08  // 0b1000 0000

#define LED_HIGH asm(" sbi 5, 5")//PORTB|=0x20 // 0b0010 0000
#define LED_LOW asm(" cbi 5, 5")//PORTB&=0xF7  // 0b1111 0111
#define LED_ENABLE asm(" sbi 4, 5") //DDRB&=0x20  // 0b0010 0000

#define TRIG_HIGH asm(" sbi 8, 5")//PORTC|=0x20 // 0b0010 0000
#define TRIG_LOW asm(" cbi 8, 5")//PORTC&=0xDF  // 0b1101 1111
#define TRIG_ENABLE asm(" sbi 7, 5") //DDRC&=0x20  // 0b1000 0000

//#define SERVO_HIGH asm(" sbi 11, 3")//PORTD &= 0b0000 1000
//#define SERVO_LOW asm(" cbi 11, 3")//PORTD &= 0b1111 0111
//#define SERVO_ENABLE asm(" sbi 10, 3") //DDRD &= 0b0000 1000

#define ECHO_ENABLE asm(" cbi 7, 4") //DDRC&=0x20  // 0b1000 0000

#define START_LOOP asm("_loopStart:");
#define RESTART_LOOP asm("  JMP _loopStart");

#define START_PULSE_CHECK asm("_pulseCheckStart:");
#define SKIP_TO_PULSE_CHECK asm(" JMP _pulseCheckStart");

uint8_t btOutput;
int intent, extent;
uint8_t cache[8] = {0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00};
bool checkedLastTime = false;
bool shouldBrake;
Servo servo;
uint8_t cycleCount = 0;
uint8_t ledState = 0xFF;

ISR(USART_RX_vect)
{
  uint8_t uart_rx = UDR0;
  uint8_t intent = uart_rx / 32;
  uint8_t extent = uart_rx & 0x1F;
  cache[intent] = extent;

  if (intent == 7) cache[intent] = uart_rx;
  
  if (intent > 4 || (shouldBrake && intent != 2 && intent != 3)){
    // Power was adjusted
  } else {
    if (intent == 1){
      if (extent) IN1_HIGH;
      else IN1_LOW;
    } else if (intent == 2){
      if (extent) IN2_HIGH;
      else IN2_LOW;
    } else if (intent == 3){
      if (extent) IN3_HIGH;
      else IN3_LOW;
    } else if (intent == 4){
      if (extent) IN4_HIGH;
      else IN4_LOW;
    }
  }
}

int getDistance() {
  TRIG_LOW;
  delayMicroseconds(2);
  TRIG_HIGH;
  delayMicroseconds(10);
  TRIG_LOW;
  delayMicroseconds(2);
  return (int)pulseIn(ECHO_PIN, HIGH, 1300) / 58;
}

void brake(){
  ENA_HIGH;
  ENB_HIGH;
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

uint8_t steeringAngle(){
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
//  Serial.begin(9600);
  UBRR0H = (unsigned char) (103>>8);
  UBRR0L = (unsigned char) 103;
  
  UCSR0B = (1<<RXEN0) | (1<<TXEN0);
  UCSR0C = (1<<USBS0) | (3<<UCSZ00);
  
  // Enable Serial completion interrupt
  cli();
  UCSR0B |= (1<<RXCIE0);
  sei();
  
  TRIG_ENABLE;
  ECHO_ENABLE;
  IN1_ENABLE;
  IN2_ENABLE;
  IN3_ENABLE;
  IN4_ENABLE;
  ENA_ENABLE;
  ENB_ENABLE;
  LED_ENABLE;
  
  servo.attach(SERVO_PIN);
}

int main(void){
  init();
  setup();

  START_LOOP;
  unsigned long start = micros();
  if (cycleCount == 0){
    if (ledState) LED_HIGH;
    else LED_LOW;
    ledState = ~ledState;
  }
  cycleCount = (cycleCount + 1) % 0x1F;

  if (!(cycleCount%4)){
    int dist = getDistance();  
    // Check if we should brake.
    shouldBrake = abs(dist) <= 20 && abs(dist) != 0;
  }
  
  checkedLastTime = !checkedLastTime;

  if (shouldBrake){
    // Ensure we shouldn't be braking or going in reverse
    if ( cache[0x07] != 0xE0 && (cache[0x02]&0x1F != 0x00 || cache[0x03]&0x1F != 0x00) ){
      // Just don't do anything I guess
    } else {
      brake();
      RESTART_LOOP;
    }
  }

  servo.write(steeringAngle());

  if(cache[0x07]){
    // IN1 has been updated
    performTask(cache[0x07] & 0x1F);
    RESTART_LOOP;
  }

  if (cycleCount < cache[0x05]) ENA_HIGH;
  else ENA_LOW;

  if (cycleCount < cache[0x06]) ENB_HIGH;
  else ENB_LOW;

//  Serial.println(micros() - start);

  RESTART_LOOP;
  return 0;
}
