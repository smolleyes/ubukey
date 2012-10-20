#!/bin/bash

USER=$1

if [ ! -e "/usr/local/bin/multisystem" ]; then
    cd /tmp
    wget http://liveusb.info/multisystem/install-depot-multisystem.sh.tar.bz2
    tar xvf install-depot-multisystem.sh.tar.bz2
    chmod +x install-depot-multisystem.sh
    sed -i '/nohup sudo -u/d' install-depot-multisystem.sh
    ./install-depot-multisystem.sh
fi

sudo -u "$USER" -i multisystem
