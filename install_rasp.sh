#######################
# Mount USB Harddrives permanently

sudo blkid

## --> COPY value of PARTUUID

sudo nano /etc/fstab

# addlines:
#PARTUUID=68f1ed7b-01    /mnt/usbstorage  ntfs    ntfs    auto,nofail,sync,users,rw       0   0
#PARTUUID=006e39f4-01    /mnt/usbstorage2 ntfs    ntfs    auto,nofail,sync,users,rw       0   0

sudo mkdir -p /mnt/usbstorage
sudo mkdir -p /mnt/usbstorage2

sudo chown root:root /mnt/usbstorage
sudo chmod 777 /mnt/usbstorage

sudo chown root:root /mnt/usbstorage2
sudo chmod 777 /mnt/usbstorage2

### Send harddrives to standby automatically

sudo apt-get install hdparm

### Set spindown timer for external harddrive to 25seconds, otherwise the harddrives would spin continiously
sudo hdparm -S5 /dev/sda
sudo hdparm -S5 /dev/sdb


######################
# Install Samba

sudo apt-get install samba samba-common smbclient

## Check if Samba is up and running

sudo service smbd status
sudo service nmbd status

sudo nano /etc/samba/smb.conf

### -> Add at the end
#[MiniCloud]
#path = /mnt/usbstorage
#writeable=Yes
#create mask=0777
#directory mask=0777
#public=yes

#[MegaCloud]
#path = /mnt/usbstorage2
#writeable=Yes
#create mask=0777
#directory mask=0777
#public=yes


#####################
# Install CUPS and printer (SAMSUNG) drivers and Airprint to print from iPad

sudo apt-get install cups 
sudo apt-get install printer-driver-gutenprint 
sudo apt-get install printer-driver-splix

sudo cupsctl --remote-admin 
sudo lsusb 
sudo cupsctl --share-printers 
sudo cupsctl --remote-printers 
sudo usermod -aG lpadmin pi

sudo apt-get install cups-pdf

sudo apt-get install libcups2-dev

sudo apt-get install python-cups
sudo mkdir /opt/airprint 
cd /opt/airprint 
sudo wget -O airprint-generate.py --no-check-certificate https://raw.github.com/tjfontaine/airprint-generate/master/airprint-generate.py

sudo chmod 755 airprint-generate.py 
sudo ./airprint-generate.py 
sudo mv AirPrint-*.service /etc/avahi/services
sudo ./airprint-generate.py -d /etc/avahi/services

sudo /etc/init.d/avahi-daemon restart
sudo /etc/init.d/cups restart

#####################
# Install Sane

sudo apt install sane-utils
lsusb

## -> Bus 001 Device 005: ID 04e8:3441 Samsung Electronics Co., Ltd

sudo scanimage -L

## -> device `xerox_mfp:libusb:001:005' is a Samsung Samsung SCX-3200 Series multi-function peripheral


## Configure sane-Daemon to accept incoming connections
sudo nano /etc/sane.d/saned.conf

## --> Access list 192.168.0.0/24 --> Accept incoming from all over the network

## Start sane Service
systemctl status saned.socket

sudo systemctl start saned.socket
sudo systemctl enable saned.socket
systemctl status saned.socket

## Configure Backend for network connections
sudo nano /etc/sane.d/net.conf

## add pi IP-Adress e.g.: -> 192.168.0.24 

sudo nano /etc/default/saned

## add: -> RUN=yes

sudo sane-find-scanner

sudo ls -l /dev/bus/usb/001 # <- USB depends on where the device is connected

## Output shows you the owner of the scanner -> usualls "lp"

## Add owner of the scanner (lp) to the the saned group
sudo adduser saned lp


## Disable WiFi OR LAN in raspberry pi (desktop)

####################
# Install Shiny-Server

# Install R Shiny Server (stable) on Raspberry Pi 4, tested December 22, 2019
# References: https://github.com/rstudio/shiny-server/issues/347
# and: https://www.rstudio.com/products/shiny/download-server/
# and: https://cloud.r-project.org/bin/linux/debian/#debian-stretch-stable
# and: https://github.com/rstudio/shiny-server/wiki/Building-Shiny-Server-from-Source

# Start at home directory
cd

# Update/Upgrade Raspberry Pi
sudo apt-get -y update && sudo apt-get -y upgrade

# Install R
sudo apt-get -y install r-base

# Install system libraries (dependences for some R packages)
sudo apt-get -y install libssl-dev libcurl4-openssl-dev libboost-atomic-dev

## Uninstall/Reinstall Pandoc (Shouldn't be initially installed)
sudo apt-get -y remove pandoc
sudo apt-get -y install pandoc

## Install dependencies of package later
sudo su - -c "R -e \"install.packages('Rcpp', repos='https://cran.rstudio.com/')\""
sudo su - -c "R -e \"install.packages('BH', repos='https://cran.rstudio.com/')\""

# Install R Packages
git clone https://github.com/r-lib/later.git
sed -i -e 's/PKG_LIBS = -pthread/PKG_LIBS = -pthread -lboost_atomic/g' later/src/Makevars.in
sudo R CMD INSTALL later

sudo su - -c "R -e \"install.packages('httpuv', repos='https://cran.rstudio.com/')\""
sudo su - -c "R -e \"install.packages('shiny', repos='https://cran.rstudio.com/')\""
sudo su - -c "R -e \"install.packages('plotly', repos='https://cran.rstudio.com/')\""
sudo su - -c "R -e \"install.packages('rmarkdown', repos='https://cran.rstudio.com/')\""

# Install cmake: https://github.com/rstudio/shiny-server/wiki/Building-Shiny-Server-from-Source

wget http://www.cmake.org/files/v2.8/cmake-2.8.11.2.tar.gz
tar xzf cmake-2.8.11.2.tar.gz
cd cmake-2.8.11.2
./configure
make
sudo make install
sudo apt-get -y update && sudo apt-get -y upgrade

## Return to home directory
cd

# Install Shiny Server as per https://github.com/rstudio/shiny-server/issues/347
## Clone the repository from GitHub
git clone https://github.com/rstudio/shiny-server.git

## Edit external/node/install-node.sh for ARM processor
cd shiny-server/

### update NODE_SHA256 as per: https://nodejs.org/dist/[CURRENTVERSION]/SHASUMS256.txt

sudo nano external/node/install-node.sh

## change Checksum NODE_SHA256, NODE_FILENAME and NODE_URL e.g.:

# NODE_SHA256=bc7d4614a52782a65126fc1cc89c8490fc81eb317255b11e05b9e072e70f141d
#
# download_node () {
#  local NODE_FILENAME="node-v12.14.0-linux-armv7l.tar.xz"
#  local NODE_URL="https://nodejs.org/dist/v12.14.0/${NODE_FILENAME}"
#  local NODE_ARCHIVE_DEST="/tmp/${NODE_FILENAME}"
#  echo "Downloading Node ${NODE_VERSION} from ${NODE_URL}"

## Build shiny-Server

DIR=`pwd`
PATH=$DIR/bin:$PATH
mkdir tmp
cd tmp
PYTHON=`which python`
sudo cmake -DCMAKE_INSTALL_PREFIX=/usr/local -DPYTHON="$PYTHON" ../
sudo make
mkdir ../build

(cd .. && sudo ./external/node/install-node.sh)
(cd .. && ./bin/npm --python="${PYTHON}" install --no-optional)
(cd .. && ./bin/npm --python="${PYTHON}" rebuild)
sudo make install


## Return to home directory
cd

## Copy Shiny Server directory to system location
sudo cp -r shiny-server/ /usr/local/

# Place a shortcut to the shiny-server executable in /usr/bin
sudo ln -s /usr/local/shiny-server/bin/shiny-server /usr/bin/shiny-server

#Create shiny user. On some systems, you may need to specify the full path to 'useradd'
sudo useradd -r -m shiny

# Create log, config, and application directories
sudo mkdir -p /var/log/shiny-server
sudo mkdir -p /srv/shiny-server
sudo mkdir -p /var/lib/shiny-server
sudo chown shiny /var/log/shiny-server
sudo mkdir -p /etc/shiny-server

# Return to Shiny Server directory and set shiny-server.conf
cd shiny-server
sudo cp config/default.config /etc/shiny-server/shiny-server.conf
sudo cp -r /usr/local/shiny-server/ext/pandoc .
sudo rm -r /usr/local/shiny-server/ext/pandoc/
# Setup for start at boot: http://docs.rstudio.com/shiny-server/#systemd-redhat-7-ubuntu-15.04-sles-12
# and: https://www.raspberrypi-spy.co.uk/2015/10/how-to-autorun-a-python-script-on-boot-using-systemd/
sed -i -e "s:ExecStart=/usr/bin/env bash -c 'exec /opt/shiny-server/bin/shiny-server >> /var/log/shiny-server.log 2>&1':ExecStart=/usr/bin/shiny-server:g"  config/systemd/shiny-server.service
sed -i -e 's:/env::'  config/systemd/shiny-server.service
sudo cp config/systemd/shiny-server.service /lib/systemd/system/
sudo chmod 644 /lib/systemd/system/shiny-server.service
sudo systemctl daemon-reload
sudo systemctl enable shiny-server.service

# Final Shiny Server Setup
sudo cp samples/welcome.html /srv/shiny-server/index.html
sudo cp -r samples/sample-apps/ /srv/shiny-server/

sudo shiny-server &
# Return to home directory
cd