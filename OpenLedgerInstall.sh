#!/bin/bash

# Node Mafia ASCII Art
echo "
     __             _                        __  _        
  /\ \ \  ___    __| |  ___   /\/\    __ _  / _|(_)  __ _ 
 /  \/ / / _ \  / _\` | / _ \ /    \  / _\` || |_ | | / _\` |
/ /\  / | (_) || (_| ||  __// /\/\ \| (_| ||  _|| || (_| |
\_\ \/   \___/  \__,_| \___|\/    \/ \__,_||_|  |_| \__,_|
                                                          
EN Telegram: soon..
RU Telegram: https://t.me/nodemafia
GitHub: https://github.com/NodeMafia
Medium: https://medium.com/@nodemafia
Teletype: https://teletype.in/@nodemafia
Twitter: https://x.com/NodeMafia
"

# Check OS version
echo "Checking OS version..."
OS_VERSION=$(lsb_release -r | awk '{print $2}')
if [ "$OS_VERSION" != "24.04" ]; then
    echo "Warning: This script is designed for Ubuntu 24.04. Your version is $OS_VERSION."
fi

# Check if Docker is installed
echo "Checking if Docker is installed..."
if ! command -v docker &> /dev/null; then
    echo "Docker is not installed. Would you like to install Docker? (y/n)"
    read -r INSTALL_DOCKER
    if [[ "$INSTALL_DOCKER" =~ ^[Yy]$ ]]; then
        echo "Installing Docker..."
        sudo apt remove -y docker docker-engine docker.io containerd runc
        sudo apt install -y apt-transport-https ca-certificates curl software-properties-common
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
        sudo apt update
        sudo apt install -y docker-ce docker-ce-cli containerd.io
        sudo docker --version
    else
        echo "Exiting script. Please install Docker and rerun."
        exit 1
    fi
fi

# Check if screen is installed
echo "Checking if screen is installed..."
if ! command -v screen &> /dev/null; then
    echo "Screen is not installed. Installing screen..."
    sudo apt install -y screen
fi

# Functions for managing OpenLedger
install_openledger() {
    # Install dependencies
    echo "Installing required dependencies..."
    sudo apt-get update
    sudo apt install -y libgtk-3-0 libnotify4 libnss3 libxss1 libxtst6 xdg-utils libatspi2.0-0 libsecret-1-0
    sudo apt-get install -f
    sudo apt-get install -y desktop-file-utils unzip libgbm-dev libasound2

    # Download and unzip OpenLedger
    echo "Downloading OpenLedger..."
    wget https://cdn.openledger.xyz/openledger-node-1.0.0-linux.zip -O openledger-node-1.0.0-linux.zip
    if [ $? -ne 0 ]; then
        echo "Error: Failed to download OpenLedger. Please check the URL."
        exit 1
    fi

    echo "Unzipping OpenLedger package..."
    unzip openledger-node-1.0.0-linux.zip -d openledger
    if [ $? -ne 0 ]; then
        echo "Error: Failed to unzip OpenLedger package. Please check the downloaded file."
        exit 1
    fi

    # Find and install the .deb package
    echo "Looking for the OpenLedger .deb package..."
    DEB_PATH=$(find openledger -name "openledger-node-1.0.0.deb" | head -n 1)

    if [ -z "$DEB_PATH" ]; then
        echo "Error: Unable to locate the .deb package in the extracted files."
        exit 1
    fi

    echo "Installing OpenLedger from $DEB_PATH..."
    cd openledger
    sudo apt install -y "$DEB_PATH"  
    sudo dpkg -i openledger-node-1.0.0.deb
    if [ $? -ne 0 ]; then
        echo "Error: Failed to install OpenLedger. Attempting to configure packages..."
        sudo dpkg --configure -a
    fi

    echo "OpenLedger installation completed successfully."

    # Start OpenLedger in a new screen session
    echo "Starting OpenLedger in a new screen session named 'ol'..."
    screen -S ol -d -m openledger-node --no-sandbox
    echo "OpenLedger is now running in the screen session 'ol'."
}

restart_openledger() {
    echo "Stopping OpenLedger..."
    stop_openledger  
    echo "Restarting OpenLedger..."
    screen -S ol -d -m openledger-node --no-sandbox  
    echo "OpenLedger has been restarted in the screen session 'ol'."
}

stop_openledger() {
    echo "Stopping OpenLedger..."
    screen -S ol -X quit  # screen
    # Killing processes associated with OpenLedger
    pkill -f openledger-node
    echo "All OpenLedger processes have been stopped."
}

remove_openledger() {
    echo "Removing OpenLedger..."
    sudo dpkg -r openledger-node  
    # Removing related files
    rm -rf openledger-node-1.0.0-linux.zip openledger
    echo "OpenLedger has been removed along with its files."
}

# Main menu
echo "Please select an option:"
echo "1. Install OpenLedger"
echo "2. Restart OpenLedger"
echo "3. Stop OpenLedger"
echo "4. Remove OpenLedger"
read -r OPTION

case $OPTION in
    1)
        install_openledger
        ;;
    2)
        restart_openledger
        ;;
    3)
        stop_openledger
        ;;
    4)
        remove_openledger
        ;;
    *)
        echo "Invalid option selected."
        ;;
esac
