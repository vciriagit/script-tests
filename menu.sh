#!/bin/bash
# Variables related to output-text style
 RED='\033[0;31m'
 BLUE='\033[0;34m'
 ORANGE='\033[0;33m'
 GREEN='\033[0;32m'
 NC='\033[0m' # No Color
# Stop on the first sign of trouble
set -e
#if [ $UID != 0 ]; then
#    echo -e "${RED}ERROR: Operation not permitted. Forgot sudo?${NC}"
#    exit 1
#fi
clear
echo -e "${GREEN}OPTIONS${NC}"
echo
printf "1 - Install LoRa\n"
printf "2 - Install Bluetooth\n"
printf "3 - nRF [unavailable] \n"
printf "4 - Test LoRa with node\n"
printf "5 - Test Bluetooth with node\n"
printf "6 - Exit\n"
printf "Choose an option (1-6) and press enter: "

read OPTION
if [ $OPTION == "1" ]; then
    clear
    echo -e "${RED}LoRa${NC}"
    pushd ~/script-tests/script-installation-lora-box
    sudo ./install.sh
    popd
fi
if [ $OPTION == "2" ]; then
    clear
    echo -e "${BLUE}Bluetooth${NC}"
    pushd /script-tests/script-installation-bluetooth
    sudo ./install_blue.sh
    popd
fi
if [ $OPTION == "3" ]; then
    echo -e "${RED}3${NC}"
fi
if [ $OPTION == "4" ]; then
    #test lora
    clear
    pushd "lora-test"
    ./node-test-lora
    popd
fi
if [ $OPTION == "5" ]; then
    #test bluetooth
    clear
    pushd "bluetooth-test"
    python commControl.py
    popd
fi

echo
echo -e "${GREEN}THE END${NC}"
