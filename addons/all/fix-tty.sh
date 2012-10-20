#!/bin/bash
###########
# Permet d'avoir le fond d'ecran actif direct au chargement de gdm
# 
DESCRIPTION="Permet d'adapter la langue des consoles virtuelles ou tty (important)"

zenity --info --text "Les paquets console-data et console-setup vont être reinstallés
attention aux choix que vous faites ;)"

if [[ ! `dpkg -l | grep -w "console-data"` ]]; then
sudo apt-get install -y --force-yes --reinstall console-data
else
sudo dpkg-reconfigure console-data
fi

if [[ ! `dpkg -l | grep -w "console-setup"` ]]; then
sudo apt-get install -y --force-yes --reinstall console-setup
else
sudo dpkg-reconfigure console-setup
fi

zenity --info --title "Fin de l'installation" \
--text "Opérations terminées, validez pour continuer."

kill -9 `ps aux | grep -e "hold" | grep -e [x]term | grep -e "/usr/share/ubukey/addons" | awk '{print $2}' | xargs`
