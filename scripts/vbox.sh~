#!/bin/bash

DIST=$1
DISTDIR=$2
installType=$3
source /etc/ubukey/config

function chooseMedia() 
{
choix=`zenity --width=550 --height=250 --title "Virtualbox" --list --text "Testez votre distrib avec virtualbox ou passez..." --radiolist --column "Choix" --column "Action" --column "Description"  \
TRUE "Usb" "Tester votre clé usb" \
FALSE "Iso" "Tester le fichier iso"`
case $? in
0)
	case $choix in
		Usb)
			installType="usb"
		;;
		Iso)
			installType="cdrom"
		;;
	esac
;;# fin 0

*)
exit 0
;;

esac

}

##########################################################
## installe qemu et compile kqemu
function startVbox()
{
if [ ! -e "/usr/bin/vboxsdl" ]; then
	testConnect
	echo -e "installation de virtualbox...\n"
	if [ "$CURDIST" == "precise" ]; then
		aptitude -y install virtualbox
	else	
		aptitude -y install virtualbox-ose
	fi
fi

echo -e "Installation de virtualbox ok ! \n"

echo -e "Calcul de la memoire disponible pour executer virtualbox...\n"

freeCheck=$(free -k | grep -e "-/+" | awk '{print $4}')
freeTot=$(( $freeCheck / 1000  - 256 )) 

## calcule si + de 256 / 512  ca suffit...
if [ $freeTot > 512 ]; then
	qMem="512"
fi

if [ $freeTot > 1024 ]; then
	qMem="768"
fi

if [[ $freeTot < 512 && $freeTot > 256 ]]; then
	qMem="256"
fi

echo -e "Vous disposez de "$freeTot"Mo de memoire disponible (marge de 256Mo)
$qMem Mo seront utilisés pour virtualbox...\n"

echo -e "Démarrage de virtualbox...\n"
modprobe vboxnetflt &>/dev/null
sleep 1

rm -R /tmp/test* &>/dev/null
rm -R /root/.VirtualBox &>/dev/null

## loop check cd/usb
for i in `echo $installType`; do

if [ "$i" == "usb" ]; then
	if [ -z "$usbdev" ]; then
		. $UBUKEYDIR/scripts/scankey.sh	
	fi
	
	echo -e "genere les fichiers necessaires a virtualbox pour booter sur usb... \n"
	vboxmanage createvm -name "test-usb" -basefolder "/tmp/test-usb" -register
	vboxmanage internalcommands createrawvmdk -filename "/tmp/test-usb/usb.vmdk" -rawdisk "/dev/"$usbdev"1"
	VBoxManage storagectl "test-usb" --name "IDE Controller" --add ide
	VBoxManage modifyvm "test-usb" --hda "/tmp/test-usb/usb.vmdk" --memory 512 --acpi on --nic1 nat
	VBoxManage startvm "test-usb" 
	while [[ `ps aux | grep [V]irtualBox` ]]; do sleep 5; done
	echo -e "Nettoie la session virtualbox... \n"
	VBoxManage modifyvm "test-usb" --hda none
	VBoxManage unregistervm "test-usb" --delete
	rm -R /tmp/test-usb &>/dev/null
	sed -i '/usb.vmdk/d' /root/.VirtualBox/VirtualBox.xml
	sed -i '/test-usb.xml/d' /root/.VirtualBox/VirtualBox.xml
elif [ "$i" == "cdrom" ]; then
	if [ ! -e "${DISTDIR}"/"$DIST".iso ]; then
		echo -e "Le fichier iso ""$DIST"".iso n'existe pas (pas crée ou renommé...), sortie"
		sleep 3
		exit 1
	else
		echo -e "genere les fichiers necessaires a virtualbox pour booter sur iso... \n"
		VBoxManage createvm -name "test-iso" -basefolder "/tmp/test-iso" -register
		VBoxManage modifyvm "test-iso" --boot1 dvd --memory $qMem --acpi on --nic1 nat
		VBoxManage storagectl "test-iso" --name dvd --add ide
		VBoxManage storageattach "test-iso" --storagectl dvd --port 0 --device 0 --type dvddrive --medium "${DISTDIR}"/"$DIST".iso
		VBoxManage startvm "test-iso" 
		while [[ `ps aux | grep [V]irtualBox` ]]; do sleep 5; done
		echo -e "Nettoie la session virtualbox... \n"
		VBoxManage storagectl "test-iso" --name dvd --remove
		VBoxManage unregistervm "test-iso" --delete
		rm -R /tmp/test-iso &>/dev/null
		sed -i '/.iso/d' /root/.VirtualBox/VirtualBox.xml
		sed -i '/test-iso.xml/d' /root/.VirtualBox/VirtualBox.xml
	fi
else
	echo -e "Probleme avec le type de media, sortie..."
	exit 1
fi
 
done

noQemu="true"

echo -e "\nOpérations terminées !"

}


if [ "$sessionType" == "" ]; then
	chooseMedia
	startVbox
else
	startVbox
fi
