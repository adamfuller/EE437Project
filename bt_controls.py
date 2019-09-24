import time
import subprocess
import sys
import os
# from datetime import datetime
# from datetime import timedelta
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

# sensor_stopper pins used
trigger_pin = 11
echo_pin = 13

IN1_pin = 3
IN2_pin = 5
IN3_pin = 7
IN4_pin = 8
ENA_pin = 10
ENB_pin = 12

phone_mac_address = "80:4E:70:C1:DC:51"
channel = 1

GPIO.setmode(GPIO.BOARD)  # number in parenthesis from pinout bash command

GPIO.setup(IN1_pin, GPIO.OUT)
GPIO.setup(IN2_pin, GPIO.OUT)
GPIO.setup(IN3_pin, GPIO.OUT)
GPIO.setup(IN4_pin, GPIO.OUT)
GPIO.setup(ENA_pin, GPIO.OUT)
GPIO.setup(ENB_pin, GPIO.OUT)

IN1_control = GPIO.PWM(IN1_pin, 1000)
IN2_control = GPIO.PWM(IN2_pin, 1000)
IN3_control = GPIO.PWM(IN3_pin, 1000)
IN4_control = GPIO.PWM(IN4_pin, 1000)

IN1_control.start(0)
IN2_control.start(0)
IN3_control.start(0)
IN4_control.start(0)
GPIO.output(ENA_pin, GPIO.HIGH)
GPIO.output(ENB_pin, GPIO.HIGH)


def init_bluetooth():
    os.system("sudo bluetoothctl power on")
    os.system("sudo bluetoothctl agent on")
    PAIR(phone_mac_address)
    os.system("sudo sdptool add SP")
    # os.system()

# Controller accessible functions


def PAIR(mac):
    os.system("sudo bluetoothctl pair " + mac)


def IN1(val):
    adjustDutyCycle(IN1_control, float(val))


def IN2(val):
    adjustDutyCycle(IN2_control, float(val))


def IN3(val):
    adjustDutyCycle(IN3_control, float(val))


def IN4(val):
    adjustDutyCycle(IN4_control, float(val))


def ENA(val):
    adjustOutput(ENA_pin, val)


def ENB(val):
    adjustOutput(ENB_pin, val)


def adjustOutput(pin, val):
    val = val.upper()
    enable = "TRUE" in val or "HIGH" in val
    if enable:
        GPIO.output(pin, GPIO.HIGH)
    else:
        GPIO.output(pin, GPIO.LOW)


def adjustDutyCycle(obj, val):
    if val > 1.0:
        obj.ChangeDutyCycle(val)
    else:
        obj.ChangeDutyCycle(val * 100)


controls = {
    "IN1": IN1,
    "IN2": IN2,
    "IN3": IN3,
    "IN4": IN4,
    "ENA": ENA,
    "ENB": ENB,
    "PAIR": PAIR,
}


primary_command = "sudo rfcomm listen /dev/rfcomm0 " + \
    str(channel) + " picocom -c /dev/rfcomm0 --omap crcrlf"

if __name__ == "__main__":
    print("Starting Main")
    init_bluetooth()

    while True:
        try:
            p = subprocess.Popen(primary_command, shell=True,
                                 stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
            for l in iter(p.stdout.readline, b""):
                # print(l)
                if "Couldn't execute command picocom" in l:
                    command2 = "sudo apt-get install picocom"
                    p2 = subprocess.Popen(
                        command2, shell=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
                    break

                line_contents = l.replace(
                    "\n", "").replace("\r", "").split(" ")

                prefix = line_contents[0]
                if (prefix in controls):
                    print(l)
                    if (len(line_contents) > 1):
                        data = line_contents[1]
                        controls[prefix](data)
                    else:
                        controls[prefix](None)

                time.sleep(0.01)
        except:
            print("oops")

    # If the device escapes the while loop for any reason cleanup the IO
    IN1_control.stop()
    IN2_control.stop()
    IN3_control.stop()
    IN4_control.stop()
    GPIO.cleanup()
