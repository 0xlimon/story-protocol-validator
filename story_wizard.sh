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

echo -e "${BLUE}=== Downloading Story-Geth binary v0.11.0 ===${NC}"
cd $HOME
wget https://github.com/piplabs/story-geth/releases/download/v0.11.0/geth-linux-amd64
[ ! -d "$HOME/go/bin" ] && mkdir -p $HOME/go/bin
if ! grep -q "$HOME/go/bin" $HOME/.bash_profile; then
  echo "export PATH=$PATH:/usr/local/go/bin:~/go/bin" >> ~/.bash_profile
fi
chmod +x geth-linux-amd64
mv $HOME/geth-linux-amd64 $HOME/go/bin/story-geth
source $HOME/.bash_profile
story-geth version

echo -e "${BLUE}=== Downloading Story binary v0.13.0 ===${NC}"
cd $HOME
rm -rf story-linux-amd64
wget https://github.com/piplabs/story/releases/download/v0.13.0/story-linux-amd64
[ ! -d "$HOME/go/bin" ] && mkdir -p $HOME/go/bin
if ! grep -q "$HOME/go/bin" $HOME/.bash_profile; then
  echo "export PATH=$PATH:/usr/local/go/bin:~/go/bin" >> ~/.bash_profile
fi
chmod +x story-linux-amd64
sudo cp $HOME/story-linux-amd64 $HOME/go/bin/story
source $HOME/.bash_profile
story version

echo -e "${YELLOW}Please enter your moniker name:${NC}"
read moniker_name

echo -e "${BLUE}=== Initializing Odyssey node ===${NC}"
story init --network odyssey --moniker "$moniker_name"

echo -e "${BLUE}=== Creating story-geth service file ===${NC}"
sudo tee /etc/systemd/system/story-geth.service > /dev/null <<EOF
[Unit]
Description=Story Geth Client
After=network.target

[Service]
User=root
ExecStart=/root/go/bin/story-geth --odyssey --syncmode full
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
sudo systemctl enable story-geth && \
sudo systemctl status story-geth

echo -e "${BLUE}=== Reloading and starting story ===${NC}"
sudo systemctl daemon-reload && \
sudo systemctl start story && \
sudo systemctl enable story && \
sudo systemctl status story

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
