#!/bin/bash
###########
# Permet d'installer les paquets ubiquity pour le wm actuel kde/gnome etc
# 
DESCRIPTION="Permet d'installer les paquets pour l installateur selon votre environnement kde/gnome/lxde/xfce... (utile pour les debootstrap seulement!)"

sessionType=$(sudo cat /etc/ubukey/ubukeyconf | grep -e "distSession" | sed 's/.*distSession=//')

case $sessionType in
gnome)
packages="ubiquity-casper ubiquity-slideshow-ubuntu ubiquity-frontend-gtk ubiquity-ubuntu-artwork"
;;
kde4)
packages="ubiquity-casper ubiquity-slideshow-kubuntu ubiquity-frontend-kde ubiquity-ubuntu-artwork"
;;
xfce4)
packages="ubiquity-casper ubiquity-slideshow-kubuntu ubiquity-frontend-gtk ubiquity-ubuntu-artwork"
;;
lxde)
packages="ubiquity-casper ubiquity-slideshow-ubuntu ubiquity-frontend-gtk ubiquity-ubuntu-artwork"
;;
esac

sudo apt-get -y --force-yes install $packages

echo "Installation terminée !"
sleep 5

zenity --info --title "Fin de l'installation" \
--text "Opérations terminées, validez pour continuer."

kill -9 `ps aux | grep -e "hold" | grep -e [x]term | grep -e "/usr/share/ubukey/addons" | awk '{print $2}' | xargs`
