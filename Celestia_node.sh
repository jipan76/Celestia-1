

#!/bin/bash
echo -e "\033[0;33m"
echo "==========================================================================================================================="
echo " "
echo "  ██████╗ ██████╗ ███╗   ██╗████████╗██████╗ ██╗██████╗ ██╗   ██╗████████╗██╗ ██████╗ ███╗   ██╗██████╗  █████╗  ██████╗ ";
echo " ██╔════╝██╔═══██╗████╗  ██║╚══██╔══╝██╔══██╗██║██╔══██╗██║   ██║╚══██╔══╝██║██╔═══██╗████╗  ██║██╔══██╗██╔══██╗██╔═══██╗";
echo " ██║     ██║   ██║██╔██╗ ██║   ██║   ██████╔╝██║██████╔╝██║   ██║   ██║   ██║██║   ██║██╔██╗ ██║██║  ██║███████║██║   ██║";
echo " ██║     ██║   ██║██║╚██╗██║   ██║   ██╔══██╗██║██╔══██╗██║   ██║   ██║   ██║██║   ██║██║╚██╗██║██║  ██║██╔══██║██║   ██║";
echo " ╚██████╗╚██████╔╝██║ ╚████║   ██║   ██║  ██║██║██████╔╝╚██████╔╝   ██║   ██║╚██████╔╝██║ ╚████║██████╔╝██║  ██║╚██████╔╝";
echo "  ╚═════╝ ╚═════╝ ╚═╝  ╚═══╝   ╚═╝   ╚═╝  ╚═╝╚═╝╚═════╝  ╚═════╝    ╚═╝   ╚═╝ ╚═════╝ ╚═╝  ╚═══╝╚═════╝ ╚═╝  ╚═╝ ╚═════╝ ";
                                                                                                                                                                                                 
echo -e "\033[0;33m"
echo "==========================================================================================================================="                                                                                    
sleep 1



function InstallingRequiredtool {
echo -e "\e[1m\e[32mInstalling required tool ... \e[0m" && sleep 1
sudo apt install curl -y < "/dev/null"
sudo apt update && apt install git sudo unzip wget -y < "/dev/null"
sudo apt install curl tar wget vim clang pkg-config libssl-dev jq build-essential git make ncdu -y < "/dev/null"
}


function InstallingGo {
echo " "
echo -e "\e[1m\e[32mInstalling Go ... \e[0m" && sleep 1
ver="1.18.2"
cd $HOME
wget "https://golang.org/dl/go$ver.linux-amd64.tar.gz"
sudo rm -rf /usr/local/go
sudo tar -C /usr/local -xzf "go$ver.linux-amd64.tar.gz"
rm "go$ver.linux-amd64.tar.gz"
echo "export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin" >> ~/.bash_profile
source ~/.bash_profile
}


function Installingcelestia-app {
echo " "
echo -e "\e[1m\e[32mInstalling Celestia App ... \e[0m" && sleep 1
cd $HOME 
rm -rf celestia-app
git clone https://github.com/celestiaorg/celestia-app.git
cd celestia-app 
git checkout v0.6.0
make install
}


function Createwallet {
echo " "
echo -e "\e[1m\e[32mCreate Celestia Wallet ... \e[0m" && sleep 1
source ~/.bash_profile

if [ ! $CNODENAME ]; then
read -p "Insert node name: " NODENAME && sleep 2
echo 'export CNODENAME='$NODENAME >> $HOME/.bash_profile
fi

if [ ! $CWALLET ]; then
read -p "Insert wallet name: " WALLET && sleep 2
echo 'export CWALLET='${WALLET} >> $HOME/.bash_profile
fi
source $HOME/.bash_profile
celestia-appd config chain-id mamaki
celestia-appd config keyring-backend test
sed -i.bak -e "s/^mode *=.*/mode = \"validator\"/" $HOME/.celestia-app/config/config.toml
}



function SetchainID {
echo " "
echo -e "\e[1m\e[32mSet chain id mamaki and keyring-backend test... \e[0m" && sleep 1
celestia-appd config keyring-backend test
celestia-appd config chain-id mamaki
celestia-appd init ${CNODENAME} --chain-id mamaki && sleep 2
}


function Setupgenesis  {
echo " "
echo -e "\e[1m\e[32mDownload Genesis.json... \e[0m" && sleep 1
curl -s https://raw.githubusercontent.com/celestiaorg/networks/master/mamaki/genesis.json > $HOME/.celestia-app/config/genesis.json
}



function Setseedsandpeers  {
echo " "
echo -e "\e[1m\e[32mSet seeds and peers... \e[0m" && sleep 1
peers=$(curl -sL https://raw.githubusercontent.com/celestiaorg/networks/master/mamaki/peers.txt | tr -d '\n')
bootstrap_peers=$(curl -sL https://raw.githubusercontent.com/celestiaorg/networks/master/mamaki/bootstrap-peers.txt | tr -d '\n')
sed -i.bak -e 's|^bootstrap-peers *=.*|bootstrap-peers = "'"$bootstrap_peers"'"|; s|^persistent_peers *=.*|persistent_peers = "'$peers'"|' $HOME/.celestia-app/config/config.toml
}





function Setpruning {
echo " "
echo -e "\e[1m\e[32mSet Pruning... \e[0m" && sleep 1
sed -i 's|pruning = "default"|pruning = "custom"|g' $HOME/.celestia-app/config/app.toml
sed -i 's|pruning-keep-recent = "0"|pruning-keep-recent = "100"|g' $HOME/.celestia-app/config/app.toml
sed -i 's|pruning-interval = "0"|pruning-interval = "10"|g' $HOME/.celestia-app/config/app.toml
}




function Setsystemd {
echo " "
echo -e "\e[1m\e[32mCreate celestia-appd.service ... \e[0m" && sleep 1
sudo tee /etc/systemd/system/celestia-appd.service > /dev/null << EOF
[Unit]
Description=Celestia Validator Node
After=network-online.target
[Service]
User=$USER
ExecStart=$(which celestia-appd) start
Restart=on-failure
RestartSec=10
LimitNOFILE=10000
[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable celestia-appd
}



function setP2PConfigurationOptions {
echo " "
echo -e "\e[1m\e[32mSet P2P Configuration Options... \e[0m" && sleep 1
use_legacy="false"
pex="true"
max_connections="90"
peer_gossip_sleep_duration="2ms"
sed -i.bak -e "s/^use-legacy *=.*/use-legacy = \"$use_legacy\"/" $HOME/.celestia-app/config/config.toml
sed -i.bak -e "s/^pex *=.*/pex = \"$pex\"/" $HOME/.celestia-app/config/config.toml
sed -i.bak -e "s/^max-connections *=.*/max-connections = \"$max_connections\"/" $HOME/.celestia-app/config/config.toml
sed -i.bak -e "s/^peer-gossip-sleep-duration *=.*/peer-gossip-sleep-duration = \"$peer_gossip_sleep_duration\"/" $HOME/.celestia-app/config/config.toml
}

function Syncsnap {
echo " "
sudo systemctl stop celestia-appd && sleep 5

echo -e "\e[1m\e[32mDownload data from Lasted snap ... \e[0m" && sleep 1
celestia-appd tendermint unsafe-reset-all --home $HOME/.celestia-app --keep-addr-book && sleep 5
cd $HOME
rm -rf ~/.celestia-app/data && sleep 5
mkdir ~/.celestia-app/data 
SNAP_NAME=$(curl -s https://snaps.qubelabs.io/celestia/ | egrep -o ">mamaki.*tar" | tr -d ">") 
wget -O - https://snaps.qubelabs.io/celestia/${SNAP_NAME} | tar xf - -C ~/.celestia-app/data/
sudo systemctl restart celestia-appd
}


function Restart {
echo " "
echo -e "\e[1m\e[32mRestart you node ... \e[0m" && sleep 1
sudo systemctl restart celestia-appd
}


function Checksync {
echo " "
echo -e "\e[1m\e[32mCheck you node sync... \e[0m" && sleep 1
source $HOME/.bash_profile && celestia-appd status 2>&1 | jq .SyncInfo.latest_block_height
source $HOME/.bash_profile && celestia-appd status 2>&1 | jq .SyncInfo.catching_up
}

function Addwallet {
echo " "
echo -e "\e[1m\e[32mCreate you wallet... \e[0m" && sleep 1
echo -e "\e[1m\e[31m **Important** Please write this mnemonic phrase in a safe place. \e[0m" && sleep 1
source $HOME/.bash_profile && celestia-appd keys add $WALLET
echo -e "\e[1m\e[33mYour celestia Wallet address : $(celestia-appd keys show ${WALLET} -a)\e[0m" && sleep 1
echo -e "\e[1m\e[34mYour celestia Validator address : $(celestia-appd keys show ${WALLET} --bech val -a)\e[0m" && sleep 1    
echo 'export CWALLET_ADDRESS='$(celestia-appd keys show ${CWALLET} -a) >> $HOME/.bash_profile
echo 'export CVALOPER_ADDRESS='$(celestia-appd keys show ${CWALLET} --bech val -a) >> $HOME/.bash_profile
}

function Checkbalances {
echo " "
echo -e "\e[1m\e[32mCheck you balance... \e[0m" && sleep 1
source $HOME/.bash_profile && celestia-appd query bank balances $CWALLET_ADDRESS
}


function CreateValidator {
echo " "
echo -e "\e[1m\e[32mCreate Validator ... \e[0m" && sleep 1
celestia-appd tx staking create-validator -y \
  --amount 10000000utia \
  --from $CWALLET_ADDRESS \
  --moniker $CNODENAME \
  --pubkey  $(celestia-appd tendermint show-validator) \
  --commission-rate=0.1 \
  --commission-max-rate=0.2 \
  --commission-max-change-rate=0.01 \
  --min-self-delegation=1000000 \
  --keyring-backend=test \
  --chain-id mamaki
  
  sleep 60
  
celestia-appd tx slashing unjail --from=$CWALLET_ADDRESS --chain-id=mamaki -y
 echo -e "\e[1m\e[34mYour Celestia Validator address : $(celestia-appd keys show ${CWALLET} --bech val -a)\e[0m" && sleep 1
}


function Restoreconfig {
echo " "
echo -e "\e[1m\e[32mRestore Config ... \e[0m" && sleep 1
sudo systemctl stop celestia-appd 
wget -qO $HOME/.celestia-app/config/config.toml https://raw.githubusercontent.com/Contribution-DAO/Celestia/main/config/config.toml
sudo systemctl start celestia-appd
}


function Delete {
echo " "
echo -e "\e[1m\e[32mDelete you node ... \e[0m" && sleep 1
sudo systemctl stop celestia-appd && sudo systemctl disable celestia-appd && sudo rm /etc/systemd/system/celestia-appd.service && sudo systemctl daemon-reload && rm -rf $HOME/.celestia-app && rm -rf $HOME/celestia-app  && rm $(which celestia-appd) 
sudo sed -i '/CWALLET/d' $HOME/.bash_profile
sudo sed -i '/CWALLET_ADDRESS/d' $HOME/.bash_profile
sudo sed -i '/CVALOPER_ADDRESS/d' $HOME/.bash_profile
sudo sed -i '/CNODENAME/d' $HOME/.bash_profile
}






PS3='Please enter your choice (input your option number and press enter): '
options=("Install" "Install + Snap" "Check Sync" "Snapshort" "Check Balance" "Create Validator" "Restart" "Restore Config" "Uninstall" "Quit")

select opt in "${options[@]}"
do
    case $opt in
        "Install")
            echo -e '\e[1m\e[32mYou choose Install without Snapshort ...\e[0m' && sleep 1
InstallingRequiredtool
InstallingGo
Installingcelestia-app
Createwallet
SetchainID
Setupgenesis
Setseedsandpeers
Setpruning
Setsystemd
setP2PConfigurationOptions
Restart
Addwallet
echo -e "\e[1m\e[32mYour Node was Install!\e[0m" && sleep 1
break
;;

"Install + Snap")
            echo -e '\e[1m\e[32mYou choose Install with Snapshort ...\e[0m' && sleep 1
InstallingRequiredtool
InstallingGo
Installingcelestia-app
Createwallet
SetchainID
Setupgenesis
Setseedsandpeers
Setpruning
Setsystemd
setP2PConfigurationOptions
Syncsnap
Restart
Addwallet
echo -e "\e[1m\e[32mYour Node was Install!\e[0m" && sleep 1

;;

"Check Sync")
            echo -e '\e[1m\e[32mYou choose Check Sync ...\e[0m' && sleep 1
Checksync

;;

"Check Balance")
            echo -e '\e[1m\e[32mYou choose Check Balance ...\e[0m' && sleep 1
Checkbalances

;;

"Snapshort")
            echo -e '\e[1m\e[32mYou choose Download Snapshot ...\e[0m' && sleep 1
Syncsnap
echo -e "\e[1m\e[32mDownload Snapshot complete!\e[0m" && sleep 1


;;


"Create Validator")
echo -e '\e[1m\e[32mYou choose Create Validator ...\e[0m' && sleep 1
CreateValidator
echo -e "\e[1m\e[34mYour Celestia Validator address : $(celestia-appd keys show ${WALLET} --bech val -a)\e[0m" && sleep 1

;;

"Restart")
echo -e '\e[1m\e[32mYou choose Restart You Node ...\e[0m' && sleep 1
Restart
echo -e "\e[1m\e[32mRestart You Node complete!\e[0m" && sleep 1


;;

"Restore Config")
echo -e '\e[1m\e[32mYou choose Restore Config.toml ...\e[0m' && sleep 1
Restoreconfig
echo -e "\e[1m\e[32mRestore Config.toml complete!\e[0m" && sleep 1

;;

"Uninstall")
echo -e '\e[1m\e[32mYou choose Uninstall ...\e[0m' && sleep 1
Delete
echo -e "\e[1m\e[32mYour Node was Uninstall complete!\e[0m" && sleep 1
break
;;

"Quit")
break
;;

*) echo -e "\e[91minvalid option $REPLY\e[0m";;
    esac
done
