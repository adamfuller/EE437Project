
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

uint8_t cache[8] = {0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00};
Servo servo;
bool shouldBrake = false;

uint8_t cycleCount = 0;
uint8_t ledState = 0xFF;

bool pulseSent = false;
unsigned long pulseStart = 0;
unsigned long width = 0;


ISR(USART_RX_vect)
{
  uint8_t uart_rx = UDR0;
  cache[uart_rx >> 5] = uart_rx;
  if (width) width++;
}

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
//  cache[0x01] = 0x00;
//  cache[0x02] = 0x00;
//  cache[0x03] = 0x00;
//  cache[0x04] = 0x00;
//  cache[0x05] = 0x00;
//  cache[0x06] = 0x00;
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

  // BEGIN UART init
  // Setup serial for 9600 Baud rate
  UBRR0H = (unsigned char) (103>>8);
  UBRR0L = (unsigned char) 103;
  
  UCSR0B = (1<<RXEN0) | (1<<TXEN0);
  UCSR0C = (1<<USBS0) | (3<<UCSZ00);
  
  // Enable Serial completion interrupt
  cli();
  UCSR0B |= (1<<RXCIE0);
  sei();

  // END UART init

  // BEGIN GPIO init
  // Enable IO
  TRIG_ENABLE;
  ECHO_ENABLE;
  IN1_ENABLE;
  IN2_ENABLE;
  IN3_ENABLE;
  IN4_ENABLE;
  ENA_ENABLE;
  ENB_ENABLE;
  LED_ENABLE;
  
  // END GPIO init
  
  // Servo setup
  servo.attach(SERVO_PIN);
}

int main(void){

  setup();

  START_LOOP;
  
//  if (cycleCount == 0){
//    if (ledState) LED_HIGH;
//    else LED_LOW;
//    ledState = ~ledState;
//  }
  cycleCount++;

  if (shouldBrake || !cycleCount%3){

    // Ensure we aren't attempting to go in reverse
    if ( shouldBrake && (!(cache[0x02] & 0x1F) || !(cache[0x03]&0x1F) ) ){
      brake();
      LED_HIGH;
          
      if (!pulseSent) sendPulse(); 
      
      
      SKIP_TO_PULSE_CHECK;
    }
    LED_LOW;
    
    if (!pulseSent) sendPulse();
  }

  servo.write(steeringAngle());

  if(cache[0x07] & 0xE0){
    // IN1 has been updated
    performTask(cache[0x07] & 0x1F);
    
    SKIP_TO_PULSE_CHECK;
  }

  if (cycleCount < ((cache[0x05] & 0x1F) * 8)) ENA_HIGH;
  else ENA_LOW;

  if (cycleCount < ((cache[0x06] & 0x1F) * 8)) ENB_HIGH;
  else ENB_LOW;

  if (cache[0x01] & 0x1F) IN1_HIGH;
  else IN1_LOW;

  if (cache[0x02] & 0x1F) IN2_HIGH;
  else IN2_LOW;

  if (cache[0x03] & 0x1F) IN3_HIGH;
  else IN3_LOW;
    
  if (cache[0x04] & 0x1F) IN4_HIGH;
  else IN4_LOW;
  
  START_PULSE_CHECK;
  
  if (PINC & 0x10 && pulseSent){
    width = 0;
    // wait for the pulse to stop
   while (PINC & 0x10 && width++ < 1183);
   // 1200 Is the braking limit of about 20cm
   shouldBrake = width < 800;
   
   pulseSent = false;
   width = 0;
  }

  if (micros() - pulseStart > 2583){
    pulseSent = false;
  }

  RESTART_LOOP;
  return 0;
}
