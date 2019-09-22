import time
import subprocess
import sys
import os
from datetime import datetime
from datetime import timedelta
import RPi.GPIO as GPIO

'''
Power brake:
    ENA - HIGH
    ENB - HIGH
    IN1 - LOW
    IN2 - LOW
    IN3 - LOW
    IN4 - LOW

Free roll:
    ENA - LOW
    ENB - LOW
    IN1 - LOW
    IN2 - LOW
    IN3 - LOW
    IN4 - LOW

'''

IN1_pin = 3
IN2_pin = 5
IN3_pin = 7
IN4_pin = 8
ENA_pin = 10
ENB_pin = 12

phone_mac_address = "80:4E:70:C1:DC:51"
channel = 1

GPIO.setmode(GPIO.BOARD) # number in parenthesis from pinout bash command

GPIO.setup(IN1_pin, GPIO.OUT)
GPIO.setup(IN2_pin, GPIO.OUT)
GPIO.setup(IN3_pin, GPIO.OUT)
GPIO.setup(IN4_pin, GPIO.OUT)

IN1_control = GPIO.PWM(IN1_pin, 1000)
IN2_control = GPIO.PWM(IN2_pin, 1000)
IN3_control = GPIO.PWM(IN3_pin, 1000)
IN4_control = GPIO.PWM(IN4_pin, 1000)

IN1_control.start(0)
IN2_control.start(0)
IN3_control.start(0)
IN4_control.start(0)


def init_bluetooth():
    os.system("sudo bluetoothctl power on")
    os.system("sudo bluetoothctl agent on")
    os.system("sudo bluetoothctl pair " + phone_mac_address)
    os.system("sudo sdptool add SP")
    # os.system()


def IN1(val):
    if val > 1.0:
        IN1_control.ChangeDutyCycle(val)
    else:
        IN1_control.ChangeDutyCycle(val * 100)
        
def IN2(val):
    if val > 1.0:
        IN2_control.ChangeDutyCycle(val)
    else:
        IN2_control.ChangeDutyCycle(val * 100)
        
def IN3(val):
    if val > 1.0:
        IN3_control.ChangeDutyCycle(val)
    else:
        IN3_control.ChangeDutyCycle(val * 100)
        
def IN4(val):
    if val > 1.0:
        IN4_control.ChangeDutyCycle(val)
    else:
        IN4_control.ChangeDutyCycle(val * 100)


controls = {
    "IN1": IN1,
    "IN2": IN2,
    "IN3": IN3,
    "IN4": IN4,
}


primary_command = "sudo rfcomm listen /dev/rfcomm0 " + str(channel) + " picocom -c /dev/rfcomm0 --omap crcrlf"

if __name__ == "__main__":
    print("Starting Main")
    init_bluetooth()

    while True:
        p = subprocess.Popen(primary_command, shell=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
        for l in iter(p.stdout.readline, b""):
            # print(l)
            if "Couldn't execute command picocom" in l:
                command2 = "sudo apt-get install picocom"
                p2 = subprocess.Popen(command2, shell=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
                break

            line_contents = l.replace("\n", "").replace("\r", "").split(" ")

            prefix = line_contents[0]
            if ( prefix in controls ):
                if (len(line_contents) > 1):
                    data = line_contents[1]
                    controls[prefix](float(data))
                else:
                    controls[prefix](None)
            
        time.sleep(0.01)
    IN1_control.stop()
    IN2_control.stop()
    IN3_control.stop()
    IN4_control.stop()
    GPIO.cleanup()