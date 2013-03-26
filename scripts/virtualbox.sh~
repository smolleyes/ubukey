#!/bin/bash

WORK=$1
USER=$2

source /etc/ubukey/config

ACTION=`zenity --width 500 --height 250 --title "Choix du media" --list \
--text "Quel media voulez vous tester? 

Cliquez \"annuler\" pour sortir." \
--radiolist --column "Choix" --column "Action" --column "Description"  \
FALSE "Usb" "Tester votre clé usb, celle ci sera redetectée auparavant..." \
FALSE "Iso" "Tester l iso (celui-ci doit déjà être generé)" `
case $ACTION in
	Usb)
		## demarre qemu
		installType="usb"
		qemuBuild
	;;
	Iso)
		installType="cdrom"
		qemuBuild
	;;
	*)
	exit 0
	;;
esac
;; ## fin Qemu


##########################################################
## installe qemu et compile kqemu
function qemuBuild()
{
if [ ! -e "/usr/bin/vboxsdl" ]; then
	testConnect
	echo -e "installation de virtualbox-ose...\n"
	apt-get -y install virtualbox-ose
fi

echo -e "Installation de virtualbox ok ! \n"

echo -e "Calcul de la memoire disponible pour executer virtualbox...\n"
sleep 2

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

sleep 3

echo -e "Démarrage de virtualbox...\n"
modprobe vboxnetflt &>/dev/null
sleep 1
CURDIST=$(lsb_release -cs)

rm -R /tmp/test-usb &>/dev/null
rm -R /tmp/test-iso &>/dev/null
rm -R /root/.VirtualBox &>/dev/null

## loop check cd/usb
for i in `echo $installType`; do

if [ "$i" == "usb" ]; then
	if [ -z "$usbdev" ]; then
		scanKey	
	fi
	
	echo -e "genere les fichiers necessaires a virtualbox pour booter sur usb... \n"
	vboxmanage createvm -name "test-usb" -basefolder "/tmp" -register
	vboxmanage internalcommands createrawvmdk -filename "/tmp/test-usb/usb.vmdk" -rawdisk "/dev/"$usbdev"1"
	if [[ `echo "$CURDIST" | grep -E "lucid|maverick|natty|oneiric"` ]]; then
echo "ici"
		VBoxManage storagectl "test-usb" --name "IDE Controller" --add ide
		VBoxManage modifyvm "test-usb" --hda "/tmp/test-usb/usb.vmdk" --memory 512 --acpi on --nic1 nat
	else
echo "ici2"	
	VBoxManage modifyvm "test-usb" --hda "/tmp/test-usb/usb.vmdk" --memory $qMem --acpi on --nic1 nat
	fi
	VBoxManage startvm "test-usb" 
	while [[ `ps aux | grep [V]irtualBox` ]]; do sleep 5; done
	echo -e "Nettoie la session virtualbox... \n"
	if [[ `echo "$CURDIST" | grep -E "lucid|maverick|natty|oneiric"` ]]; then
		VBoxManage modifyvm "test-usb" --hda none
	else
		VBoxManage modifyvm "test-usb" --hda none
	fi
	VBoxManage unregistervm "test-usb" --delete
	rm -R /tmp/test-usb
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
		rm -R /tmp/test-iso
		sed -i '/.iso/d' /root/.VirtualBox/VirtualBox.xml
		sed -i '/test-iso.xml/d' /root/.VirtualBox/VirtualBox.xml
	fi
else
	echo -e "Probleme avec le type de media, sortie..."
	exit 1
fi
 
done

noQemu="true"
choose_action

}


