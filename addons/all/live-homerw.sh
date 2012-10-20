#!/bin/bash
############
#
# Script pour monter la partition casper-rw en tant que /home/$user by FRAFA (merci) et bidouille perso
#

DESCRIPTION="Module crée avec frafa qui permet, depuis une session live classique,
de monter la partition /home/loginducd de la partition casper-rw (mode persistent)

Ceci est donc utile pour avoir accés aux documents du mode persistent 
(pas les programmes) sans les contraintes de pilotes etc, de ce même mode..."

echo -e "Création du lanceur... 

Attention !! 

Ce lanceur sera dispo dans la section Utilitaire de votre menu gnome/kde...
Il sera nommé \"home-rw\".

N'utilisez pas ce lanceur dans le chroot, seulement en mode live-cd et aprés avoir utilisé
au moins une fois le mode peristent
"
sleep 15
if [ ! -e /usr/local/bin/mountrw.sh ]; then
	cd /usr/local/bin
	sudo wget -q http://www.ubukey.fr/files/launchers/mountrw.sh
	sudo chmod +x mountrw.sh
fi

if [ ! -e /usr/share/pixmaps/home-rw.png ]; then
	cd /usr/share/pixmaps
	sudo wget -q http://www.ubukey.fr/files/images/home-rw.png
fi
		
if [ ! -e /usr/share/applications/home-rw.png ]; then
FILE="[Desktop Entry]
Encoding=UTF-8
Version=1.0
Type=Application
Terminal=false
Icon[fr_FR]=/usr/local/share/pixmaps/home-rw.png
Exec=/usr/local/bin/mountrw.sh
Name[fr_FR]=Monter home-rw
Comment[fr_FR]=Permet de monter HOME du mode presistent
Name=Monter home-rw
Comment=Permet de monter HOME du mode presistent
Categories=GNOME;Application;Utility;
Icon=/usr/share/pixmaps/home-rw.png" 

echo -e "$FILE" | sudo tee /usr/share/applications/home-rw.desktop &>/dev/null
sudo xdg-desktop-menu install --noupdate /usr/share/applications/home-rw.desktop &>/dev/null
xdg-desktop-menu forceupdate --mode user &>/dev/null
xdg-desktop-menu forceupdate --mode system &>/dev/null

fi

echo -e "Installation du lanceur terminée"
sleep 3

zenity --info --title "Fin de l'installation" \
--text "Opérations terminées, validez pour continuer."

kill -9 `ps aux | grep -e "hold" | grep -e [x]term | grep -e "/usr/share/ubukey/addons" | awk '{print $2}' | xargs`
