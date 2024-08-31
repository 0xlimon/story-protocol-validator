#!/bin/bash


printHeader() {
    echo -e "\e[36m   ___       _      _                       \e[0m"
    echo -e "\e[36m  / _ \\     | |    (_)                      \e[0m"
    echo -e "\e[36m | | | |_  _| |     _ _ __ ___   ___  _ __  \e[0m"
    echo -e "\e[36m | | | \\ \\/ / |    | | '_ ' _ \\ / _ \\| '_ \\ \e[0m"
    echo -e "\e[36m | |_| |>  <| |____| | | | | | | (_) | | | |\e[0m"
    echo -e "\e[36m  \\___//_/\\_\\______|_|_| |_| |_|\\___/|_| |_|\e[0m"
    echo -e "\e[36m                                            \e[0m"
    echo -e "\e[36m                                            \e[0m"
    echo -e "\e[36m  https://github.com/0xlimon\e[0m"
    echo -e "\e[36m******************************************************\e[0m"
}

printHeader


# ANSI colors for prettier output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Installing dependencies ===${NC}"
sudo apt update
sudo apt-get update
sudo apt install curl git make jq build-essential gcc unzip wget lz4 aria2 -y

echo -e "${BLUE}=== Downloading Story-Geth binary ===${NC}"
wget https://story-geth-binaries.s3.us-west-1.amazonaws.com/geth-public/geth-linux-amd64-0.9.2-ea9f0d2.tar.gz
tar -xzvf geth-linux-amd64-0.9.2-ea9f0d2.tar.gz
[ ! -d "$HOME/go/bin" ] && mkdir -p $HOME/go/bin
if ! grep -q "$HOME/go/bin" $HOME/.bash_profile; then
  echo 'export PATH=$PATH:$HOME/go/bin' >> $HOME/.bash_profile
fi
sudo cp geth-linux-amd64-0.9.2-ea9f0d2/geth $HOME/go/bin/story-geth
source $HOME/.bash_profile
story-geth version

echo -e "${BLUE}=== Downloading Story binary ===${NC}"
wget https://story-geth-binaries.s3.us-west-1.amazonaws.com/story-public/story-linux-amd64-0.9.11-2a25df1.tar.gz
tar -xzvf story-linux-amd64-0.9.11-2a25df1.tar.gz
[ ! -d "$HOME/go/bin" ] && mkdir -p $HOME/go/bin
if ! grep -q "$HOME/go/bin" $HOME/.bash_profile; then
  echo 'export PATH=$PATH:$HOME/go/bin' >> $HOME/.bash_profile
fi
sudo cp story-linux-amd64-0.9.11-2a25df1/story $HOME/go/bin/story
source $HOME/.bash_profile
story version

echo -e "${YELLOW}Please enter your moniker name:${NC}"
read moniker_name

echo -e "${BLUE}=== Initializing Iliad node ===${NC}"
story init --network iliad --moniker "$moniker_name"

echo -e "${BLUE}=== Creating story-geth service file ===${NC}"
sudo tee /etc/systemd/system/story-geth.service > /dev/null <<EOF
[Unit]
Description=Story Geth Client
After=network.target

[Service]
User=root
ExecStart=/root/go/bin/story-geth --iliad --syncmode full
Restart=on-failure
RestartSec=3
LimitNOFILE=4096

[Install]
WantedBy=multi-user.target
EOF

echo -e "${BLUE}=== Creating story service file ===${NC}"
sudo tee /etc/systemd/system/story.service > /dev/null <<EOF
[Unit]
Description=Story Consensus Client
After=network.target

[Service]
User=root
ExecStart=/root/go/bin/story run
Restart=on-failure
RestartSec=3
LimitNOFILE=4096

[Install]
WantedBy=multi-user.target
EOF

echo -e "${BLUE}=== Reloading and starting story-geth ===${NC}"
sudo systemctl daemon-reload && \
sudo systemctl start story-geth && \
sudo systemctl enable story-geth

echo -e "${BLUE}=== Reloading and starting story ===${NC}"
sudo systemctl daemon-reload && \
sudo systemctl start story && \
sudo systemctl enable story

echo -e "${GREEN}=== Installation and setup completed successfully ===${NC}"

echo -e "${YELLOW}=== Checking logs ===${NC}"
echo "To view story-geth logs, run the following command:"
echo -e "${GREEN}sudo journalctl -u story-geth -f -o cat${NC}"
echo "Please wait a minute for peers to connect."

echo -e "${YELLOW}=== Checking sync status ===${NC}"
echo "To check the sync status, run the following command:"
echo -e "${GREEN}curl localhost:26657/status | jq${NC}"

echo -e "${BLUE}Waiting for your node...${NC}"
echo -e "When ${GREEN}catching_up${NC} is ${GREEN}false${NC}, you can create your validator."
