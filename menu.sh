#!/bin/bash
# Variables related to output-text style
 RED='\033[0;31m'
 BLUE='\033[0;34m'
 ORANGE='\033[0;33m'
 GREEN='\033[0;32m'
 NC='\033[0m' # No Color
# Stop on the first sign of trouble
set -e
if [ $UID != 0 ]; then
    echo -e "${RED}ERROR: Operation not permitted. Forgot sudo?${NC}"
    exit 1
fi
echo
echo -e "${GREEN}Comm. Tests installer${NC}"
echo
echo -e "${GREEN}OPTIONS${NC}"
echo
printf "Choose an option (1-4): "
printf "LoRa (1) "
printf "Bluetooth (2) "
printf "nRF (3) "
printf "EXIT (4) : "
read OPTION
if [ $OPTION == "1" ]; then
    echo -e "${RED}LoRa${NC}"
    pushd /script-tests/script-installation-lora-box
    sudo ./install.sh
    popd
fi
if [ $OPTION == "2" ]; then
    echo -e "${BLUE}Bluetooth${NC}"
    pushd /script-tests/script-installation-bluetooth
    sudo ./install_blue.sh
    popd
fi
if [ $OPTION == "3" ]; then
    echo -e "${RED}3${NC}"
fi
echo
echo -e "${RED}THE END${NC}"
