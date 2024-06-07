# main | v2.7.1 | v2.7.0 | v2.6.6 | v2.6.4
OPEN5GS_VERSION="v2.7.1"

# Installing MongoDB
sudo apt update
sudo apt install -y gnupg
curl -fsSL https://pgp.mongodb.com/server-6.0.asc | sudo gpg -o /usr/share/keyrings/mongodb-server-6.0.gpg --dearmor
echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-6.0.gpg] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/6.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-6.0.list
sudo apt update
sudo apt install -y mongodb-org
sudo systemctl start mongod
sudo systemctl enable mongod


# Creating OGSTUN interface
sudo sh -c "cat << EOF > /etc/systemd/network/99-open5gs.network
[Match]
Name=ogstun
[Network]
Address=10.45.0.1/16
Address=2001:db8:cafe::1/48
EOF"
sudo sh -c "cat << EOF > /etc/systemd/network/99-open5gs.netdev
[NetDev]
Name=ogstun
Kind=tun
EOF"
sudo systemctl restart systemd-networkd


# Installing Open5gs
sudo apt install -y python3-pip python3-setuptools python3-wheel ninja-build build-essential flex bison git cmake libsctp-dev libgnutls28-dev libgcrypt-dev libssl-dev libidn11-dev libmongoc-dev libbson-dev libyaml-dev libnghttp2-dev libmicrohttpd-dev libcurl4-gnutls-dev libnghttp2-dev libtins-dev libtalloc-dev meson

cd ~/
git clone --branch $OPEN5GS_VERSION https://github.com/open5gs/open5gs.git
cd open5gs
sudo meson build --prefix=`pwd`/install
sudo ninja -C build
cd build
sudo ninja install
cd ../
Yes | echo install/lib/x86_64-linux-gnu >> /etc/ld.so.conf.d/open5gs.conf
sudo ldconfig

# Coping Configs and Binaries to Expected Locations
cd ~/open5gs/install/bin
sudo cp open5gs* /usr/bin/.
cd ~/open5gs/install/etc/
sudo cp -r * /etc/.
ln -sf /etc/open5gs/ ~/core_configs
sudo mkdir -p /var/log/open5gs/
ln -sf /var/log/open5gs ~/core_logs


# Create systemctl services for the core
cd /tmp
CORE_COMPONENETS="amf ausf bsf hss mme nrf nssf pcf pcrf scp sgwc sgwu smf udm udr upf" 

for COMPONENET in $CORE_COMPONENETS
do
    sudo sed -i "s|path: /home/[^/]*/open5gs/install/var/log/open5gs/${COMPONENET}.log|path: /var/log/open5gs/${COMPONENET}.log|" /etc/open5gs/${COMPONENET}.yaml
    FILE_NAME="open5gs-${COMPONENET}d.service"
    tee $FILE_NAME <<EOF
[Unit]
Description=Open5GS ${COMPONENET} Daemon
After=network-online.target

[Service]
Type=simple

Restart=always
ExecStart=/usr/bin/open5gs-${COMPONENET}d -c /etc/open5gs/${COMPONENET}.yaml
RestartSec=2
RestartPreventExitStatus=1
ExecReload=/bin/kill -HUP $MAINPID

[Install]
WantedBy=multi-user.target
EOF
    sudo cp $FILE_NAME /lib/systemd/system/.
done

CORE_COMPONENETS="sepp" 

for COMPONENET in $CORE_COMPONENETS
do
    sudo sed -i "s|path: /home/[^/]*/open5gs/install/var/log/open5gs/${COMPONENET}1.log|path: /var/log/open5gs/${COMPONENET}1.log|" /etc/open5gs/${COMPONENET}1.yaml
    sudo sed -i "s|path: /home/[^/]*/open5gs/install/var/log/open5gs/${COMPONENET}2.log|path: /var/log/open5gs/${COMPONENET}2.log|" /etc/open5gs/${COMPONENET}2.yaml
    FILE_NAME="open5gs-${COMPONENET}d.service"
    tee $FILE_NAME <<EOF
[Unit]
Description=Open5GS ${COMPONENET} Daemon
After=network-online.target

[Service]
Type=simple

Restart=always
ExecStart=/usr/bin/open5gs-${COMPONENET}d -c /etc/open5gs/${COMPONENET}1.yaml
RestartSec=2
RestartPreventExitStatus=1
ExecReload=/bin/kill -HUP $MAINPID

[Install]
WantedBy=multi-user.target
EOF
    sudo cp $FILE_NAME /lib/systemd/system/.
done



CORE_COMPONENETS="amf ausfd bsf hss mme nrf nssf pcf pcrf scp sepp sgwc sgwu smf udm udr upf" 

for COMPONENET in $CORE_COMPONENETS
do
    sudo systemctl start open5gs-${COMPONENET}d.service
    sudo systemctl enable open5gs-${COMPONENET}d.service
done

sudo apt update
sudo apt install -y ca-certificates curl gnupg
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
NODE_MAJOR=20
echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_$NODE_MAJOR.x nodistro main" | sudo tee /etc/apt/sources.list.d/nodesource.list
sudo apt update
sudo apt install -y nodejs

curl -fsSL https://open5gs.org/open5gs/assets/webui/install | sudo -E bash -


# Download dbctl 

sudo curl -o /usr/bin/open5gs-dbctl https://raw.githubusercontent.com/open5gs/open5gs/main/misc/db/open5gs-dbctl
sudo chmod +x /usr/bin/open5gs-dbctl



echo "Installation Done"
