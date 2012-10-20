#!/bin/bash
###########

DESCRIPTION="Ce module vous permet de copier directement tous les paquets
installés sur votre systéme local dans le live-cd...

Votre sources.list actuel sera utilisé pour cela et les paquets
seront mis à jour par la même occasion ....
"

echo -e "Prépare le dossier apt avec votre sources.list, cle et liste de paquets à copier \n"
sleep 3
## alors on deplace le sources.list du script 
sudo mv /etc/apt/sources.list /etc/apt/sources.list.script
sudo mv /etc/apt/trusted.gpg /etc/apt/trusted.gpg.script
## et copie le sources.list etc injectes precedement
sudo cp -f /etc/ubukey/sources/{sources.list,trusted.gpg,pkglist.selections} /etc/apt/
## met a jour avec le nouveau sources.list etc
echo -e "Copie ok, mise a jour des sources...\n "
sleep 2
sudo apt-get update 
## et on clone...
echo -e "Clonage de votre liste de paquets
Attention cette opération peut-être longue..."
sleep 3

sudo sed -i 's/nvidia.*//g;s/xorg-driver-fglrx.*//g;s/fglrx.*//g' /etc/apt/pkglist.selections &>/dev/null
sudo dpkg --set-selections < /etc/apt/pkglist.selections && apt-get -y dselect-upgrade --allow-unauthenticated

echo ""
echo -e "Installation terminée...

Vos fichiers sources.list et cle gpg seront conservés au passage"
sleep 5
sudo apt-get clean &>/dev/null
## nettoie fichiers desinstalles mais pas la conf donc toujours apparents
sudo dpkg -l |grep ^rc |awk '{print $2}' | xargs dpkg -P &>/dev/null 
sudo rm /etc/apt/*.script &>/dev/null

echo -e "Nettoyage ok, sortie ..."
sleep 2

zenity --info --title "Fin de l'installation" \
--text "Opérations terminées, validez pour continuer."

kill -9 `ps aux | grep -e "hold" | grep -e [x]term | grep -e "/usr/share/ubukey/addons" | awk '{print $2}' | xargs`
