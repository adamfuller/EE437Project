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
trigger_listener_pin = 13  # Input - connected to trigger_pin
echo_pin = 15  # Input

GPIO.setmode(GPIO.BOARD)  # number in parenthesis from pinout bash command

trigger_time = time.time()
echo_time = time.time()

has_been_triggered = False
is_waiting_for_echo = False


def echo_callback():
    global echo_time
    echo_time = time.time()
    print("echo pin triggered")


def trigger_callback():
    global trigger_time
    trigger_time = time.time()
    print("trigger pin high")


GPIO.add_event_detect(echo_pin, GPIO.RISING, callback=echo_callback)
GPIO.add_event_detect(trigger_listener_pin, GPIO.RISING,
                      callback=trigger_callback)

if __name__ == "__main__":
    print("Main")
    while(True):
        try:
            print("Start")
            # Trigger output
            # set is_waiting_for_echo to True
            # wait for echo callback
            # ∆x = v/2/∆t
            # ∆t = echo_time - trigger_time
            # v = 34300/2 = 17150 (cm/s)
            # ∆x = 17150 / (echo_time - trigger_time)
            # if ∆x is less than braking_distance
            #   start braking
        except:
            print("oops")
