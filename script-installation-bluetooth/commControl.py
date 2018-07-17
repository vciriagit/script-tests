#!/usr/bin/env python
import serial
import os
import time
import logging
import logging.handlers as handlers
import RPi.GPIO as GPIO
from logging.handlers import TimedRotatingFileHandler
import numbers

# Serial port for Bluetooth
SERIAL_PORT_0 = '/dev/rfcomm0'

# be sure to set this to the same rate used on the Arduino
SERIAL_RATE = 9600

# bind command
BIND_CMD_0 = 'sudo rfcomm bind /dev/rfcomm0 20:13:04:23:07:06'
 #Linvor  --> 20:13:04:23:07:06

# sleep before start
START_SLEEP = 5
# sleep after serial error
SLEEP_SERIAL_ERROR = 15

ERRORCOUNTER = 0
import RPi.GPIO as GPIO
def main():

    logSetup()
    bluetoothSetup()

    i=0
    while (i<3):
        bluetoothDataTest()
	time.sleep(5)
	i = i + 1
    return

def handleErrors(errornumber, sleeptime):
    global ERRORCOUNTER
    ERRORCOUNTER = ERRORCOUNTER + 1
    print "Error number: " + str(errornumber)
    print "Handle Error: " + str(ERRORCOUNTER) + " of 5"
    if ERRORCOUNTER > 4:
        print "Too many errors. System is going to reboot in 60 seconds ..."
        time.sleep(60)
        os.system('sudo reboot')
    else:
        print "Wait for " + str(sleeptime) + " seconds"
        time.sleep(sleeptime)

def logSetup():
    file=open("AEInnovaComm.log","a")
    file.write("Bluetooth log\r\n")
    file.close()

def bluetoothSetup():
    # ensure release rfcomm0
    cmd = 'sudo rfcomm release 0'
    os.system(cmd)
    #print cmd
    print str(START_SLEEP) + " seconds to start..."
    time.sleep(START_SLEEP)
    # binding
    os.system(BIND_CMD_0)

def bluetoothDataTest():
    global var1
    var1 = "X"
    global var2
    var2 = "X"

    try:
        global ser
        ser = serial.Serial(SERIAL_PORT_0, SERIAL_RATE)
        ser.write(b'm') #command to send every 20 seconds
        time.sleep(2)
        line = ser.readline()
        data = line.split() #node response: 2 elements
        var1 = data[0]
        var2 = data[1]
        if var1=="X" or var2=="X":
            print "ERROR receiving data"
        else:
            print "Receiving data from bluetooth OK..."

        print "Var1: "+var1
        print "Var2: "+var2

    except Exception as e:
        print str(e)
        print time.strftime("%Y-%m-%d %H:%M:%S")+" - Bluetooth Serial Error"
        handleErrors(1, SLEEP_SERIAL_ERROR)
        return

    ################   STORE DATA TO LOG FILE   ################
    file=open("AEInnovaComm.log","a")
    file.write(time.strftime("%Y-%m-%d %H:%M:%S")+"\tVar1: "+var1+"\tVar2: "+var2+"\r\n")
    file.close()

if __name__ == "__main__":
    main()
