#!/bin/bash

# Download icaclient debian package, and pass that as the first param to this
# file

# At one point, a gui-like thing will open. There, 'tick' on all the
# certificates by pressing spacebar.

# TODO(rushiagr): might need to install ubuntu's 'openssl' package, or maybe
# some more packages

sudo dpkg --add-architecture i386
sudo apt-get update

sudo dpkg -i $1

sudo apt-get -f install

cd /tmp
wget http://crl.ril.com/others/Reliance-ROOTCA.cer
wget http://crl.ril.com/Reliance-Sub-Enterprise-CA.cer
wget http://crl.ril.com/RILSUBCA01.cer

sudo openssl x509 -inform der -in Reliance-ROOTCA.cer -out Reliance-ROOTCA.crt
sudo openssl x509 -inform der -in Reliance-Sub-Enterprise-CA.cer -out Reliance-Sub-Enterprise-CA.crt
sudo openssl x509 -inform der -in RILSUBCA01.cer -out RILSUBCA01.crt

sudo mkdir -p /usr/share/ca-certificates/extra
sudo cp Reliance-ROOTCA.crt /usr/share/ca-certificates/extra

# Select your cert by pressing space, and press enter
sudo dpkg-reconfigure ca-certificates

sudo cp *.crt /opt/Citrix/ICAClient/keystore/cacerts/
sudo c_rehash /opt/Citrix/ICAClient/keystore/cacerts
