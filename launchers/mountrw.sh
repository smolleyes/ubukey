#!/bin/bash
user=`ls /home | sed 's/.*\///'`
if [ ! $(cat '/proc/cmdline' | grep persistent) ]; then
	if [[ ! "$(sudo mount -l | grep "/media/casper-rw$HOME")" && -e /media/casper-rw$HOME ]]; then
		zenity --info --text "Partition casper-rw va être utilisée en tant que dossier home
pour l'utilisateur "$user"..."
		sudo mount --bind /media/casper-rw$HOME $HOME
		zenity --info --text "La session X doit être relancée pour appliquer les changements
		
Cliquez \"Valider\" pour continuer"
		sudo kill `cat /tmp/.X0-lock`
	else
		zenity --info --text "Partition casper-rw déjà montée sur "$HOME" 
ou pas de /media/casper-rw/home/"$user" (jamais executé le mode persistent?)..."
	fi
else
	zenity --warning --text "Vous ne pouvez pas éxécuter cette fonction 
avec un session persistente active, seulement en mode live."

fi

exit 0
