import time
# import subprocess
# import sys
# import os
# from datetime import datetime
from datetime import timedelta
import RPi.GPIO as GPIO


# bt_controls pins
IN1_pin = 3
IN2_pin = 5
IN3_pin = 7
IN4_pin = 8
ENA_pin = 10
ENB_pin = 12

trigger_pin = 11  # Output
echo_pin = 15  # Input

GPIO.setmode(GPIO.BOARD)  # number in parenthesis from pinout bash command

# Setup pins
GPIO.setup(echo_pin, GPIO.IN)
GPIO.setup(trigger_pin, GPIO.OUT)

echo_start_time = time.time()
echo_end_time = time.time()

has_been_triggered = False


def echo_start_callback(channel):
    global echo_start_time
    echo_start_time = time.time()
    print("echo pin triggered")


def echo_end_callback(channel):
    global echo_end_time, has_been_triggered
    echo_end_time = time.time()
    has_been_triggered = True
    print("echo ended")


def send_pulse():
    GPIO.output(trigger_pin, GPIO.HIGH)
    time.sleep(0.00001)
    GPIO.output(trigger_pin, GPIO.LOW)


# Initiate callbacks
GPIO.add_event_detect(echo_pin, GPIO.RISING, callback=echo_start_callback)
GPIO.add_event_detect(echo_pin, GPIO.FALLING, callback=echo_end_callback)

if __name__ == "__main__":
    print("Main")
    while(True):
        try:
            # print("Start")
            time.sleep(0.001)
            # Trigger output
            send_pulse()
            # wait for echo callback
            while(not has_been_triggered):
                time.sleep(0.001)
            # dx = v/2/dt
            # v = 34300/2 = 17150 (cm/s)
            # dx = 17150 / (echo_time - trigger_time)
            # if dx is less than braking_distance
            #   start braking
            dx = 17150 / (echo_start_time - echo_end_time)
            print(str(dx))
        except:
            print("oops")
        time.sleep(0.001)

    GPIO.cleanup()
