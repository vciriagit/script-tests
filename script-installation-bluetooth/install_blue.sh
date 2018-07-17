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
echo -e "${BLUE}Bluetooth Gateway installer${NC}"
echo
printf "Please, first check that your Bluetooth Node is connected:(y/n)?"
read NODE_CONNECTED
if [ $NODE_CONNECTED == "n" ]; then
    echo -e "${RED}ERROR: Please, connect your Bluetooth Node (see blueconnection.txt)${NC}"
    exit 1
fi
# Check dependencies
echo -e "${ORANGE}Updating OS...${NC}"
apt update
apt -y upgrade
echo
echo -e "${ORANGE}Installing dependencies...${NC}"
apt install -y python3
echo -e "${ORANGE}Executing commControl.py...${NC}"
python commControl.py &
#echo -e "${ORANGE}Editing rc.local...${NC}"
#sed -i 's/exit 0/sudo python \/home\/pi\/blueinstaller\/commControl.py \& & /' /etc/rc.local
#echo -e "${BLUE}THE END. The system will reboot in 30 s ...${NC}"
#sleep 30
#shutdown -r now
echo -e "${BLUE}THE END${NC}"
