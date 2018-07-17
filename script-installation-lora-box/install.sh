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
echo -e "${GREEN}LoRa Box installer${NC}"
echo
# Check dependencies
echo -e "${ORANGE}Updating OS...${NC}"
apt update
apt -y upgrade
echo
echo -e "${ORANGE}Activating SPI port on Raspberry Pi${NC}"
pushd /boot
sed -i -e 's/#dtparam=spi=on/dtparam=spi=on/g' ./config.txt
popd

##Script to control power off with button or not
#echo "Adding a script to power off RPi using pin 26"
#pushd /usr/local/bin
#if [ ! -f powerBtn.py ]
#then
	#wget https://raw.githubusercontent.com/rnicolas/Simple-Raspberry-Pi-Shutdown-Button/master/powerBtn.py
	#sed -i -e '$i \python /usr/local/bin/powerBtn.py &\n' /etc/rc.local
#fi
#popd

# Request gateway configuration data
# There are two ways to do it, manually specify everything
# or rely on the gateway EUI and retrieve settings files from remote (recommended)
echo -e "${BLUE}Gateway configuration:${NC}"
# Try to get gateway ID from MAC address
# First try eth0, if that does not exist, try wlan0
GATEWAY_EUI_NIC="eth0"
if [[ `grep "$GATEWAY_EUI_NIC" /proc/net/dev` == "" ]]; then
    GATEWAY_EUI_NIC="wlan0"
fi
if [[ `grep "$GATEWAY_EUI_NIC" /proc/net/dev` == "" ]]; then
    echo -e "${RED}ERROR: No network interface found. Cannot set gateway ID${NC}"
    exit 1
fi
GATEWAY_EUI=$(ip link show $GATEWAY_EUI_NIC | awk '/ether/ {print $2}' | awk -F\: '{print $1$2$3"FFFE"$4$5$6}')
GATEWAY_EUI=${GATEWAY_EUI^^} # to upper
echo -e "${BLUE}Detected EUI $GATEWAY_EUI from $GATEWAY_EUI_NIC${NC}"

# Setting personal configuration of LoRaWAN Gateway
printf "       Host name [lora-box]:"
read NEW_HOSTNAME
if [[ $NEW_HOSTNAME == "" ]]; then NEW_HOSTNAME="lora-box"; fi
printf "       Descriptive name [RPi-iC880A]:"
read GATEWAY_NAME
if [[ $GATEWAY_NAME == "" ]]; then GATEWAY_NAME="RPi-iC880A"; fi
printf "       Contact email: "
read GATEWAY_EMAIL
printf "       Latitude [0]: "
read GATEWAY_LAT
if [[ $GATEWAY_LAT == "" ]]; then GATEWAY_LAT=0; fi
printf "       Longitude [0]: "
read GATEWAY_LON
if [[ $GATEWAY_LON == "" ]]; then GATEWAY_LON=0; fi
printf "       Altitude [0]: "
read GATEWAY_ALT
if [[ $GATEWAY_ALT == "" ]]; then GATEWAY_ALT=0; fi
# Change hostname if needed
CURRENT_HOSTNAME=$(hostname)
if [[ $NEW_HOSTNAME != $CURRENT_HOSTNAME ]]; then
    echo -e "${BLUE}Updating hostname to '$NEW_HOSTNAME'...${NC}"
    hostname $NEW_HOSTNAME
    echo $NEW_HOSTNAME > /etc/hostname
    sed -i "s/$CURRENT_HOSTNAME/$NEW_HOSTNAME/" /etc/hosts
fi
echo
echo -e "${ORANGE}Installing LoRaWAN packet_forwarder...${NC}"
# Install LoRaWAN packet forwarder repositories
INSTALL_DIR="/opt/lora-box"
if [ ! -d "$INSTALL_DIR" ]; then mkdir $INSTALL_DIR; fi
pushd $INSTALL_DIR
# Build LoRa gateway app
if [ ! -d lora_gateway ]; then
    git clone https://github.com/Lora-net/lora_gateway.git
    pushd lora_gateway
else
    pushd lora_gateway
    git reset --hard
    git pull
fi
make
popd
# Build packet forwarder
if [ ! -d packet_forwarder ]; then
    git clone https://github.com/Lora-net/packet_forwarder.git
    pushd packet_forwarder
else
    pushd packet_forwarder
    git pull
    git reset --hard
fi
make
popd
# Symlink packet forwarder
if [ ! -d bin ]; then mkdir bin; fi
if [ -f ./bin/lora_pkt_fwd ]; then rm ./bin/lora_pkt_fwd; fi
ln -s $INSTALL_DIR/packet_forwarder/lora_pkt_fwd/lora_pkt_fwd ./bin/lora_pkt_fwd
cp -f ./packet_forwarder/lora_pkt_fwd/global_conf.json ./bin/global_conf.json
LOCAL_CONFIG_FILE=$INSTALL_DIR/bin/local_conf.json
# Remove old config file
if [ -e $LOCAL_CONFIG_FILE ]; then
	rm $LOCAL_CONFIG_FILE
fi
printf "       Server Address ['localhost']:"
read NEW_SERVER
if [[ $NEW_SERVER == "" ]]; then NEW_SERVER="localhost"; fi
echo -e "{\n\t\"gateway_conf\": {\n\t\t\"gateway_ID\": \"$GATEWAY_EUI\",\n\t\t\"server_address\": \"$NEW_SERVER\",\n\t\t\"serv_port_up\": 1700,\n\t\t\"serv_port_down\": 1700,\n\t\t\"ref_latitude\": $GATEWAY_LAT,\n\t\t\"ref_longitude\": $GATEWAY_LON,\n\t\t\"ref_altitude\": $GATEWAY_ALT,\n\t\t\"contact_email\": \"$GATEWAY_EMAIL\",\n\t\t\"description\": \"$GATEWAY_NAME\" \n\t}\n}" >$LOCAL_CONFIG_FILE
popd
echo -e "${BLUE}Gateway EUI is: $GATEWAY_EUI${NC}"
echo -e "${BLUE}The hostname is: $NEW_HOSTNAME${NC}"
echo -e "${BLUE}The Gateway is pointing to: $NEW_SERVER${NC}"
echo
echo -e "${GREEN}Installation completed.${NC}"
# Start packet forwarder as a service
cp ./start.sh $INSTALL_DIR/bin/
pushd $INSTALL_DIR/bin/
chmod +x start.sh
popd
cp ./lora-box.service /etc/systemd/system/
systemctl enable lora-box.service
apt install -y apt-transport-https
apt update
apt upgrade

echo -e "${GREEN}Installing dependencies${NC}"
apt install -y mosquitto mosquitto-clients redis-server redis-tools postgresql

## mosquitto configuration
# Create a password file for your mosquitto users, starting with a “root” user.
# The “-c” parameter creates the new password file. The command will prompt for
# a new password for the user.
#mosquitto_passwd -c /etc/mosquitto/passwd loraroot
# Add users for the various MQTT protocol users
#read LORA_GW_PASSWD
#if [[ $LORA_GW_PASSWD == "" ]]; then
#	LORA_GW_PASSWD='loragwpasswd'
#fi
#mosquitto_passwd -b /etc/mosquitto/passwd loragw $LORA_GW_PASSWD
#read LORA_SERVER_PASSWD
#if [[ $LORA_SERVER_PASSWD == "" ]]; then
#	LORA_SERVER_PASSWD='loraserverpasswd'
#fi
#mosquitto_passwd -b /etc/mosquitto/passwd loraserver $LORA_SERVER_PASSWD
#read LORA_APP_SERVER_PASSWD
#if [[ $LORA_APP_SERVER_PASSWD == "" ]]; then
#	LORA_APP_SERVER_PASSWD='loraappserverpasswd'
#fi
#mosquitto_passwd -b /etc/mosquitto/passwd loraappserver $LORA_APP_SERVER_PASSWD
# Secure the password file
#chmod 600 /etc/mosquitto/passwd
#pushd /etc/mosquitto/conf.d/
#if [ ! -f local.conf ]; then
#	echo "allow_anonymous false" > local.conf
#	echo "password_file /etc/mosquitto/passwd" > local.conf
#fi
#systemctl restart mosquitto

#psql script to create users and databases.
echo -e "${GREEN}Creating postgresql users and databases...${NC}"
echo -e "${ORANGE}Type here the password for postgresql user loraserver_ns ['dbpassword']${NC}"
read DB_PASSWORD_NS
if [[ $DB_PASSWORD_NS == "" ]]; then
	DB_PASSWORD_NS='dbpassword'
fi
sudo -u postgres psql -c "create role loraserver_ns with login password '$DB_PASSWORD_NS';"
sudo -u postgres psql -c "create database loraserver_ns with owner loraserver_ns;"
echo -e "${ORANGE}Type here the password for postgresql user loraserver_as ['dbpassword']${NC}"
read DB_PASSWORD_AS
if [[ $DB_PASSWORD_AS == "" ]]; then
	DB_PASSWORD_AS='dbpassword'
fi
sudo -u postgres psql -c "create role loraserver_as with login password '$DB_PASSWORD_AS';"
sudo -u postgres psql -c "create database loraserver_as with owner loraserver_as;"
echo -e "${ORANGE}Creating extension pg_trgm in LoRa App Server Database...${NC}"
sudo -u postgres psql -d loraserver_as -c "create extension pg_trgm;"
echo -e "${GREEN}Installing LoRa Gateway Bridge${NC}"
DISTRIB_ID="debian"
DISTRIB_CODENAME="stretch"
pushd /etc/apt/sources.list.d/
#Check if loraserver repository is added into sources
if [ ! -f loraserver.list ]; then
  apt install dirmngr
  apt update
	apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 1CE2AFD36DBCCA00
	echo "deb https://repos.loraserver.io/${DISTRIB_ID} ${DISTRIB_CODENAME} testing" | tee loraserver.list
fi
popd
apt update
apt install -y lora-gateway-bridge
echo -e "${GREEN}Installing LoRaWAN Server${NC}"
apt install -y loraserver
echo -e "${GREEN}Installing LoRa Application Server${NC}"
apt install -y lora-app-server
#Add users and passwords to postgres URL server
sed -i 's/localhost\/loraserver_as?sslmode=disable/loraserver_as:dbpassword@localhost\/loraserver_as?sslmode=disable/' /etc/lora-app-server/lora-app-server.toml
sed -i 's/localhost\/loraserver_ns?sslmode=disable/loraserver_ns:dbpassword@localhost\/loraserver_ns?sslmode=disable/' /etc/loraserver/loraserver.toml
JWT_SECRET=$(openssl rand -base64 32)
sed -i 's/jwt_secret=""/jwt_secret="$JWT_SECRET"/' /etc/lora-app-server/lora-app-server.toml
echo -e "${ORANGE}The system will reboot in 30 seconds...${NC}"
sleep 30
shutdown -r now
