source /etc/ubukey/config

rm /tmp/usbscan &>/dev/null
rm /tmp/hallist &>/dev/null
## refresh blkid
blkid -g

usbdev=$(sudo blkid | grep -e "extlinux-ro" | awk '{print $1}' | sed 's/.*\///' | sed 's/://' | sed 's/[0-9]//')

if [ -z "$usbdev" ]; then

## passe a la detection par hal direct....
devlist=$(cat /proc/mounts | grep sd | awk '{print $1}' | sed "s/'//g" | sed 's/.*\///g' | sort | tee /tmp/hallist)

(zenity --warning --text "Merci de brancher la clé que vous souhaitez utiliser ...

Si celle-ci est déjà branchée et/ou n'a jamais ete utilisée pour ce script
merci de la debrancher, patienter le temps que la détection se fasse
et rebrancher finalement comme indiqué...

Cette fenêtre sera fermée automatiquement une fois votre clé détectée." &) 2>/dev/null

while [ -z "$usbdev" ]; do
		usbscan=$(cat /proc/mounts | grep sd | awk '{print $1}' | sed "s/'//g" | sed 's/.*\///g' | sort | tee /tmp/usbscan)
		scan=$(diff -n /tmp/hallist /tmp/usbscan | grep "^sd")
		scan2=$(diff -n /tmp/usbscan /tmp/hallist | grep "^sd")
		if [[ -z "$scan" && -z "$scan2" ]]; then
			echo "en attente..."
			sleep 2
		else
			if [ -z "$scan2" ]; then
			usbdev=$(echo -e "$scan" | xargs | awk '{print $1}' | sed 's/[0-9]//')
			else
			usbdev=$(echo -e "$scan2" | xargs | awk '{print $1}' | sed 's/[0-9]//')
			fi
			break 
		fi
done
killall -q -9 zenity

else
	if [[ "`cat /proc/mounts | grep -e ""$usbdev"1" | awk '{print $2}'`" = "/cdrom" ]]; then
	echo -e "clé avec partition extlinux-ro bien détectée mais déjà en cours d'utilisation 
sur session live-usb, relance l'assistant de détéction de la clé à préparer \n"
	sleep 3
	usbdev=""
	scanKey
	fi
	
	echo ""
	echo -e "Clé usb déjà préparée, partition extlinux-ro dispo sur /dev/"$usbdev" \n"
	sleep 2
fi

## sur verif...
while [[ ! $(cat /proc/mounts | grep -e "$usbdev") ]]; do
	echo -e "cle détectée sur /dev/$usbdev, Rebranchez la pour continuer..."
	sleep 10
done
