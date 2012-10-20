#!/bin/bash

DIST=$1
DISTDIR=$2

source /etc/ubukey/config

#############################
## Copies des fichiers necessaires sur la cle
function COPIE()
{
echo -e '\E[37;44m'"\033[1m Début de la copie, merci de patienter... \033[0m"
sudo rsync -uravH --delete --exclude="*~" "${SOURCE}/." "${DESTINATION}/."

SOURCE=""
DESTINATION=""

}

function copy_files()
{
## boucle detection cdrom/usb
if [ "$copyType" == "usb" ]; then

## test cle usb presente ou pas sinon sors
if [ -z "$usbdev" ]; then
	exit 0
## test si il y a des partitions sur la cle sinon sors
elif [ -z "$usbpart" ]; then
	exit 0 
fi

#on monte la part /dev/sdx1 de la clé
if [[ ! `mount | grep "custom-usb"` ]]; then
	umount -l -f /media/custom-usb &>/dev/null
	if [ "$usbpartType" = "vfat" ]; then
		mount -t $usbpartType -o rw,users,umask=000 /dev/$usbdev'1' /media/custom-usb
	else
	    mount -t $usbpartType -o rw,users /dev/$usbdev'1' /media/custom-usb
	fi
fi

echo  "Fichiers image et cle ok pour la copie !" 
rm -R "${DISTDIR}"/usb/disctree &>/dev/null
rm -R "${DISTDIR}"/usb/bin &>/dev/null
sudo cp -Rf "${DISTDIR}"/usb/.disk /media/custom-usb/

#Copie des fichiers, tout le dossier usb cle vide
if [[ ! `grep '[a-z]' /media/custom-usb/*` ]] &>/dev/null; then
	echo  "Copie en cours...(copie complete)"
	SOURCE="${DISTDIR}/usb"
	DESTINATION="/media/custom-usb"
elif [[ `diff -q /media/custom-usb/preseed/ "${DISTDIR}"/usb/preseed/ 2>/dev/null` ]]; then
	echo ""
	echo -e "Distribution differente de celle présente sur la clé \n"
	echo -e "Nettoyage de la clé \n"
	if [ -e "/media/custom-usb" ]; then
		rm -R -f /media/custom-usb/* &>/dev/null
	fi
	echo -e "Copie...(copie complete) \n"
	SOURCE="${DISTDIR}/usb"
	DESTINATION="/media/custom-usb"
	
else
echo 
echo  "Copie en cours sur la cle usb...(copie des fichiers manifest et squashfs)"
sleep 2
		rm -R /media/custom-usb/casper/* &>/dev/null
		SOURCE="${DISTDIR}/usb/casper"
		DESTINATION="/media/custom-usb/casper"
fi

## start copy


## copie le filesystem.squashfs quand copie direct demandee
rm -R /tmp/truc &>/dev/null
if [ -n "$DIRECT_COPY" ]; then 
		SOURCE="${DISTDIR}/old/casper/"
		DESTINATION="/media/custom-usb/casper/"
		cp -Rf "${DISTDIR}/usb/." /media/custom-usb
		COPIE 
		#> /tmp/truc >/dev/null 2>&1
else
	COPIE 
	#> /tmp/truc >/dev/null 2>&1
fi
chmod 755 -R /media/custom-usb/* &>/dev/null

## copy initrd and vmlinuz for usb key
sudo cp -f "${DISTDIR}"/usb/initrd.* "${DISTDIR}"/usb/vmlinuz /media/custom-usb &>/dev/null

elif [ "$copyType" == "cdrom" ]; then
rm -R "${DISTDIR}"/cdrom/disctree &>/dev/null
rm -R "${DISTDIR}"/cdrom/bin &>/dev/null

echo "Copie en cours..."
sleep 2
SOURCE="${DISTDIR}/usb/casper"
DESTINATION="${DISTDIR}/cdrom/casper"
COPIE 
#> /tmp/truc

else
	echo -e "Probleme de detection..."
fi
EXCLUDE=""
echo  "Fin de la copie !"
echo 
sleep 5

}

##########################################################
## Prepare Extlinux si necessaire...
function extlinuxconf()
{
#on monte la part /dev/sdx1 de la clé
if [[ ! `mount | grep "custom-usb"` ]]; then
	umount -l -f /media/custom-usb &>/dev/null
	if [ "$usbpartType" = "vfat" ]; then
		mount -t $usbpartType -o rw,users,umask=000 /dev/$usbdev'1' /media/custom-usb
	else
	    mount -t $usbpartType -o rw,users /dev/$usbdev'1' /media/custom-usb
	fi
fi

## modifie syslinux.cfg si besoin
PATH=$PATH:/sbin:/usr/sbin
export $PATH
bootdir="/media/custom-usb"
if [ "$usbpartType" = "ext4" ]; then
	if [ ! -e "$bootdir/ldlinux.sys" ]; then
	    sysConfFile="extlinux.conf"
	    rm /media/custom-usb/syslinux.cfg &>/dev/null
		mkdir -p "$bootdir" &>/dev/null
		if [ ! -e "/media/custom-usb/extlinux.conf" ]; then
			cp -f $UBUKEYDIR/conf_files/extlinux.conf /media/custom-usb/extlinux.conf
		fi

		if [ -e "/media/custom-usb/initrd.lz" ]; then
			sed -i 's/initrd.gz/initrd.lz/g' /media/custom-usb/extlinux.conf
			sed -i 's/.utf8/.UTF-8/g' /media/custom-usb/extlinux.conf
		fi
		echo -e "extlinux va etre installe sur "$bootdir", (disque /dev/"$usbdev") \n"
		extlinux -i "$bootdir"
	else
		echo "Extlinux deja installé"
	fi
else
	if [ ! -e "$bootdir/ldlinux.sys" ]; then
	    sysConfFile="syslinux.cfg"
	    rm /media/custom-usb/extlinux.conf &>/dev/null
		if [ ! -e "/media/custom-usb/syslinux.cfg" ]; then
			cp -f $UBUKEYDIR/conf_files/syslinux.cfg /media/custom-usb/syslinux.cfg
		fi

		if [ -e "/media/custom-usb/initrd.lz" ]; then
			sed -i 's/initrd.gz/initrd.lz/g' /media/custom-usb/syslinux.cfg
			sed -i 's/.utf8/.UTF-8/g' /media/custom-usb/syslinux.cfg
		fi
		echo -e "syslinux va etre installe sur "$bootdir", (disque /dev/"$usbdev") \n"
		syslinux /dev/$usbdev'1'
	else
		echo "Configuration de syslinux deja installée"
	fi
fi
testConnect

## changement image boot ou pas
zenity --question --title "Splash screen" --text "Voulez vous choisir une autre image de fond pour syslinux ?
(Image que vous verrez au boot de votre clé)"
case $? in
0) zenity --question --text "Voulez vous lancer firefox sur gnome-look pour choisir une image ?"
case $? in
0) killall -q -9 firefox-bin
	firefox http://www.gnome-look.org/index.php?xcontentmode=170 ;;
1) echo  "ok on continue" ;;
esac

splash_image=$(zenity --file-selection --filename=/home/$USER/ --title "Maintenant, selectionnez votre image...")
ext=$(echo  $splash_image | sed 's/.*\([^\.]\+\)\.\([^\.]\+\)$/\2/')	
## ok on copie l image
echo -e "Redimensionne l'image "$splash_image" ! \n"
convert -depth 16 -resize "640x480!" $splash_image -quality "100" splash.$ext
rm "${DISTDIR}"/splash* &>/dev/null
sudo cp splash.$ext "${DISTDIR}"
sudo cp "${DISTDIR}"/splash.$ext /media/custom-usb/
sed -i 's/BACKGROUND \/splash.*/BACKGROUND \/splash.'$ext'/' /media/custom-usb/$sysConfFile
zenity --info --text "l'image $splash_image est maintenant mise en place"

;; ## fin choix splash

1) 
if [[ ! `ls /media/custom-usb/ | grep -e "splash"` ]]; then
cp $UBUKEYDIR/images/splash.jpg /media/custom-usb/
convert -depth 16 -resize "640x480!" /media/custom-usb/splash.jpg /media/custom-usb/splash.jpg
sed -i 's/BACKGROUND \/splash.*/BACKGROUND \/splash.jpg/' /media/custom-usb/$sysConfFile
fi
;;

esac

## reverifie locale syslinux.cfg
LOCALUTF=$(env | grep -w "LANG" | sed -e 's/LANG=//' -e 's/.utf8/.UTF-8/g')
LOCALBASE=$(env | grep -w "LANG" | sed -e 's/\..*//' -e 's/LANG=//')
LOCALSIMPLE=$(env | grep -w "LANG" | sed -e 's/\..*//' -e 's/LANG=//' -e 's/_.*//')

if [[ ! `cat /media/custom-usb/syslinux.cfg | grep "locale=$LOCALUTF bootkbd=$LOCALSIMPLE console-setup/layoutcode=$LOCALSIMPLE"` ]]; then
	sed -i "s/locale=.* console/locale=$LOCALUTF bootkbd=$LOCALSIMPLE console-setup\/layoutcode=$LOCALSIMPLE console/g" /media/custom-usb/$sysConfFile &>/dev/null
fi

UMOUNT_SD

}

##########################################################
## Installation du dernier syslinux dispo
function syslinux_build()
{

## check syslinux special pour le script
echo -e "Verification de syslinux... \n"
installed="$(dpkg -l | grep syslinux | awk '{print $2}')"
version="$(dpkg -l | grep syslinux | awk '{print $3}')"

if [[ ! -e "/usr/bin/syslinux" || ! -e "/usr/lib/syslinux" || -z "version" || "$version" == "pre47-1" ]]; then
	echo -e "Téléchargement/reinstallation de sylinux, veuillez patienter... \n"
sleep 3
#download / compile syslinux
rm -R /usr/lib/syslinux &>/dev/null
rm -R /usr/lib64/syslinux &>/dev/null
	cd /tmp
		testConnect
		for i in `dpkg -l | grep syslinux | awk '{print $2}' | xargs`; do
			apt-get -y remove --purge "$i" &>/dev/null
		done
		apt-get -y --force-yes install syslinux extlinux
else
	echo -e "syslinux deja installé... ok \n" 
fi

bootdir="${DISTDIR}/usb"
echo -e "Préparation des fichiers de boot pour usb \n" 
if [[ ! -e "$bootdir/syslinux.cfg" && "$usbpartType" = "vfat" ]]; then
	cp -f $UBUKEYDIR/conf_files/syslinux.cfg "$bootdir/"
elif [[ ! -e "$bootdir/extlinux.conf" && "$usbpartType" = "ext4" ]]; then
    cp -f $UBUKEYDIR/conf_files/extlinux.conf "$bootdir/"
fi

if [ "$X64" == "true" ]; then	
	cp -f /usr/lib64/syslinux/vesamenu.c32 "$bootdir"
	cp -f /usr/lib64/syslinux/menu.c32 "$bootdir"
	cp -f /usr/lib64/syslinux/chain.c32 "$bootdir"
	cp -f /usr/lib64/syslinux/mboot.c32 "$bootdir"	
else
	cp -f /usr/lib/syslinux/vesamenu.c32 "$bootdir"
	cp -f /usr/lib/syslinux/menu.c32 "$bootdir"
	cp -f /usr/lib/syslinux/chain.c32 "$bootdir"
	cp -f /usr/lib/syslinux/mboot.c32 "$bootdir"	
fi

}

##########################################################
## Regenere le fichier filesystem.squashfs et les fichiers manifest
function generate_files()
{
echo "Suppression ancien fichiers squashfs et manifest"
rm "${DISTDIR}"/usb/casper/* &>/dev/null
## remonte image disque
echo  "regenere fichiers manifest"
echo 
chroot "${DISTDIR}"/chroot dpkg-query -W --showformat='${Package} ${Version}\n' > "${DISTDIR}"/usb/casper/filesystem.manifest
cp -f "${DISTDIR}"/usb/casper/filesystem.manifest "${DISTDIR}"/usb/casper/filesystem.manifest-desktop
REMOVE='ubiquity casper live-initramfs user-setup discover1 xresprobe os-prober libdebian-installer4'
for i in $REMOVE 
do
	sudo sed -i "/${i}/d" "${DISTDIR}"/usb/casper/filesystem.manifest-desktop
done
# clean cache apt
rm -R "${DISTDIR}"/chroot/var/lib/apt/lists/*

## default session to boot
rm /tmp/zenity
echo -e 'zenity --list --checklist --width 650 --height 500 --title "Choix de la session par defaut" --column "choix" --column "Session" --text "choisissez la session a demarrer par defaut sur votre live-cd/usb" \\'  | tee /tmp/zenity &>/dev/null
echo -e "FALSE \"xterm\" \\" | tee -a /tmp/zenity &>/dev/null
for i in `ls "${DISTDIR}"/chroot/usr/share/xsessions | grep ".desktop" | sed -e 's/.desktop//'`; do
	echo -e "FALSE \"$i\" \\" | tee -a /tmp/zenity &>/dev/null
done
chmod +x /tmp/zenity
MENU=$(/tmp/zenity)
res="`echo $MENU | sed 's/|/ /g' | awk '{print $1}'`"
if [ -n "$res" ]; then
	chroot "${DISTDIR}/chroot" /usr/lib/lightdm/lightdm-set-defaults -s "$res"
	echo -e "Session $res activee par defaut ...\n"
fi


echo -e "regenere le fichier squashfs \n"
umount -l -f "${DISTDIR}"/chroot/media/pc-local/media &>/dev/null
umount -l -f "${DISTDIR}"/chroot/media/pc-local/home &>/dev/null
cd "${DISTDIR}"/chroot
mksquashfs . "${DISTDIR}"/usb/casper/filesystem.squashfs

cd "${DISTDIR}"
echo -e "Squashfs et fichiers manifest ok ! \n"
sleep 5

# echo -e "Calcule la taille du dossier chroot pour le fichier filesystem.size..."
# printf $(sudo du -sx --block-size=1 chroot | cut -f1) > "${DISTDIR}"/usb/casper/filesystem.size
# if [[ ! -e "${DISTDIR}"/usb/casper/filesystem.size || -z `cat "${DISTDIR}"/usb/casper/filesystem.size` ]]; then
#  echo "can't generate the filesystem.size file, exit..."
#  exit 0
# fi
generate=""
}

##########################################################
## fix mbr de la cle avec syslinux
function mbr()
{
if [ "$X64" = "true" ]; then
	echo -e "Reecris le mbr de la cle avec sylinux \n"
	cat /usr/lib64/syslinux/mbr.bin > /dev/$usbdev
else
	echo -e "Reecris le mbr de la cle avec sylinux \n"
	cat /usr/lib/syslinux/mbr.bin > /dev/$usbdev
fi
}

##########################################################
## Demonter toutes les partions quand necessaire
function UMOUNT_SD()
{
for i in $usbpart; do
	umount /dev/$i &>/dev/null
done
}

##########################################################
## fonction recreer initrd
function make_initrd()
{
echo -e "Mise a jour du fichier initrd.gz, merci de patienter...\n"

cp /etc/hosts "${DISTDIR}"/chroot/etc/
cp /etc/resolv.conf "${DISTDIR}"/chroot/etc/
mount -o rbind /dev "${DISTDIR}"/chroot/dev
chroot "${DISTDIR}"/chroot  &> "${DISTDIR}"/logs/chrootlog.log << "EOF"
mount -t proc none /proc
mount -t sysfs none /sys

function message() {
touch /tmp/chrootlog.log
message="$1"
echo -e "$message" | tee -a /tmp/chrootlog.log &>/dev/null
}

## fix user etrange dans mksquashfs (temp) et mode 755 persistent
sed -i 's/set passwd\/user-uid 999/set passwd\/user-uid 1001/' /usr/share/initramfs-tools/scripts/casper-bottom/25adduser
sed -i 's/rw,noatime,mode=755/rw,noatime/' /usr/share/initramfs-tools/scripts/casper

## maj initiale du kernel
initcheck=$(ls /boot | grep "vmlinuz")
initver=$(ls -al /boot/initrd.* | tail -n1 | sed 's/.*initrd.img-//')
DIST=$(lsb_release -cs)
if [[ -z "$initcheck" || -z "$initver" ]]; then
message "Initrd manquant, reinstallation pour kernel : $initver, merci de patienter... \n"
## nettoie fichiers desinstalles mais pas la conf donc toujours apparents
dpkg -l |grep ^rc |awk '{print $2}' |xargs dpkg -P &>/dev/null 
apt-get update
echo -e "\nReinstallation du kernel, patience svp...\n"
apt-get remove --purge -y linux-headers* linux-image*
apt-get -y --force-yes install --reinstall linux-headers-generic linux-image-generic
else
message "mise a jour en version: $initver, merci de patienter... \n"
update-initramfs -ck all
fi

if [[ ! `dpkg -l | awk '{print $2}' | grep -E "^lzma$"` ]]; then
apt-get -y --force-yes install lzma
fi

## recreate initrd.lz file
rm -R /tmp/tmpdir &>/dev/null
mkdir /tmp/tmpdir
cd /tmp/tmpdir
cp /boot/initrd.img-$initver .
gzip -dc initrd.img-$initver | cpio -id
rm initrd.img*
find . | cpio --quiet --dereference -o -H newc | lzma -7 > /initrd.lz
rm -R /tmp/tmpdir

umount /proc
umount /sys
exit
EOF

umount -f -l "${DISTDIR}"/chroot/dev &>/dev/null
rm "${DISTDIR}"/chroot/etc/hosts &>/dev/null
rm "${DISTDIR}"/chroot/etc/resolv.conf &>/dev/null

INIT=$(ls "${DISTDIR}"/chroot/boot | grep initrd.img | tail -n 1)
INITLZ=$(ls "${DISTDIR}"/chroot/ | grep -e "initrd.lz")
VMLINUZ=$(ls "${DISTDIR}"/chroot/boot | grep vmlinuz | tail -n 1)

if [[ "$INIT" == "" && "$INITLZ" == "" || "$VMLINUZ" == "" ]]; then
	echo -e "Impossible de detecter le fichier initrd.img ou .lz ou vmlinuz manquant, sortie... \n Merci de reporter le probleme"
	exit 0
else
	## demarre creation init usb/iso
	for i in `echo $installType`; do
	echo -e "Mise a jour de l initramfs et vmlinuz : $i"
		if [ "$i" == "usb" ]; then
			rm "${DISTDIR}"/usb/initrd.* &>/dev/null
			rm "${DISTDIR}"/usb/vmlinuz &>/dev/null
			if [[ -n  "$INITLZ" && -e "${DISTDIR}"/chroot/"$INITLZ" ]]; then	
				mv -f "${DISTDIR}"/chroot/"$INITLZ" "${DISTDIR}"/usb/initrd.lz
			else
				cp -f "${DISTDIR}"/chroot/boot/"$INIT" "${DISTDIR}"/usb/initrd.gz
			fi
			cp -f "${DISTDIR}"/chroot/boot/"$VMLINUZ" "${DISTDIR}"/usb/vmlinuz
		elif [ "$i" == "cdrom" ]; then
			rm "${DISTDIR}"/cdrom/casper/initrd.* &>/dev/null
			rm "${DISTDIR}"/cdrom/casper/vmlinuz &>/dev/null
			if [[ -n "$INITLZ" && -e "${DISTDIR}"/chroot/"$INITLZ" ]]; then
				mv -f "${DISTDIR}"/chroot/"$INITLZ" "${DISTDIR}"/cdrom/casper/initrd.lz
			else
				cp -f "${DISTDIR}"/chroot/boot/"$INIT" "${DISTDIR}"/cdrom/casper/initrd.gz
			fi
			cp -f "${DISTDIR}"/chroot/boot/"$VMLINUZ" "${DISTDIR}"/cdrom/casper/vmlinuz
		else
			echo -e "Probleme avec le type d'installation usb/iso, sortie..."
			exit 1
		fi
	done
fi ## fin if presence init 

UMOUNT_SD
umount "${DISTDIR}"/chroot &>/dev/null

}

### fonction detection des process restant et umount image fat
function umountImage()
{
## et on verifie tout ca
process=$(lsof -atw "${DISTDIR}"/chroot | uniq | xargs)
commandes=$(lsof -aw "${DISTDIR}"/chroot | awk '{ print $1 }' | uniq | xargs | sed 's/COMMAND//' )

if [[ ! -z "$process" ]]; then
        kill -9 $process
        echo -e "kill des process \""$process"\" des commandes \""$commandes"\" ok ! \n"
        umountImage
else
        echo -e "demonte l image \n"
        umount -l "${DISTDIR}"/chroot &>/dev/null
fi

echo -e "Image demontee... ok \n"

}

##########################################################
## Fonction clean, kill les process restant empechant de demonter le .img ou la cle
function force_umount()
{ 
cd /tmp
echo -e "Vérification des process restants... \n"
## verif image

umountImage

## verif cle
## essaye deja de demonter normalement../
UMOUNT_SD
## reverifie si ok sinon force
if [[ `mount -l | grep -e "extlinux-ro|casper-rw"` ]]; then

key1=$(lsof -atw /media/extlinux-ro | xargs)
key2=$(lsof -atw /media/casper-rw | xargs)
commands1=$(lsof -aw /media/custom-usb | awk '{ print $1 }' | uniq | xargs | sed 's/COMMAND//')
commands2=$(lsof -aw /media/casper-rw | awk '{ print $1 }' | uniq | xargs | sed 's/COMMAND//')

if [ ! -z $process ]; then
	kill -9 $key1 $key2
	echo -e "kill des process \""$key1"\" \""$key2"\" issus des commandes \""$commands1"\" \""$commands2"\" ok ! \n"
	UMOUNT_SD
fi
fi
echo -e "Umount ok... \n"

## verif des /dev/loop
loopList=$(losetup -a | awk '{print $1}' | sed 's/://g')

for i in $loopList ; do 
	losetup -d "$i" &>/dev/null
done

############################################ Sortie ou test Qemu ############################################ 

if [ -z "$noQemu" ]; then

zenity --question --text "Voulez vous quitter ou verifier votre image avec Virtualbox ? \n
Cliquez \"annuler\" pour quitter ou Valider pour démarrer Virtualbox..."
case $? in
	0)
	/bin/bash $UBUKEYDIR/scripts/vbox.sh $DIST $DISTDIR $copyType
	;;
	1)
	noQemu=""
	;;
esac	
fi

}

genBootCd()
{
if [[ "`uname -m`" = "x86_64" ]]; then
	x64="true"
fi

preseed=$(ls "${DISTDIR}"/usb/preseed | grep "ubu")
LOCALANG=$(env | grep LANG | sed -e 's/.*=//' -e 's/_.*//' -e 's/.utf8/.UTF-8/g' | uniq)

#on cree la structure du cd de boot
mkdir -p "${DISTDIR}"/bootcd/boot/grub

#copier vmlinuz ==> vmlinuz-usb
cp -f "${DISTDIR}"/usb/vmlinuz "${DISTDIR}"/bootcd/boot/vmlinuz-usb

#copier initrd ==> initrd-usb.img
cp -f "${DISTDIR}"/usb/initrd.* "${DISTDIR}"/bootcd/boot/initrd-usb.img &>/dev/null

#on copie stage2_eltorito
if [ -z "$x64" ]; then
	cp /usr/lib/grub/i386-pc/stage2_eltorito "${DISTDIR}"/bootcd/boot/grub/
else
	cp /usr/lib/grub/x86_64-pc/stage2_eltorito "${DISTDIR}"/bootcd/boot/grub/
fi

echo -e "Genere le fichier de conf syslinux"

echo "default 0
timeout 20
color cyan/blue white/blue

title $NOM_DISTRO Live verbose splash
root (cd)
kernel /boot/vmlinuz-usb boot=casper locale=$LOCALANG kbd-chooser/method=$LOCALANG console-setup/layoutcode=$LOCALANG console-setup/variantcode=$LOCALANG console-setup/modelcode=$LOCALANG file=preseed/$preseed initrd=initrd.gz rw verbose splash
initrd /boot/initrd-usb.img

title $NOM_DISTRO persistent verbose splash
root (cd)
kernel /boot/vmlinuz-usb boot=casper locale=$LOCALANG kbd-chooser/method=$LOCALANG console-setup/layoutcode=$LOCALANG console-setup/variantcode=$LOCALANG console-setup/modelcode=$LOCALANG file=preseed/$preseed persistent initrd=initrd.gz rw verbose splash
initrd /boot/initrd-usb.img

" | tee "${DISTDIR}"/bootcd/boot/grub/menu.lst &>/dev/null

#on crée iso cd
echo -e "Création du cd iso... \n"
cd "${DISTDIR}"/bootcd
mkisofs -R -b boot/grub/stage2_eltorito -no-emul-boot -boot-load-size 4 -boot-info-table -o "${DISTDIR}"/cd-boot-liveusb.iso "${DISTDIR}"/bootcd

## nettoyage
echo -e "Nettoyage... \n"
rm -R "${DISTDIR}"/bootcd

#graver cd
chown $USER:$USER "${DISTDIR}"/cd-boot-liveusb.iso &>/dev/null
chmod 644 "${DISTDIR}"/cd-boot-liveusb.iso &>/dev/null

echo -e "Veuillez graver l'image du cd disponible dans :
${DISTDIR}/cd-boot-liveusb.iso

(clic droit, graver un disque sur le fichier .iso) ou votre logiciel de gravure favoris...

UTILISATION:
Avant de démarrer votre PC, insérez simplement le CD ainsi que votre clé USB et bootez... \n
(pensez quand même a regler votre bios si besoin...)"

sleep 5
}

function mkBootCd()
{
if [ -z "$direct" ]; then
zenity --question --title "Creation cd de boot" \
--text "Voulez vous créer un cd de boot ?

Ceci est utile pour les pc dont la carte mère ne permet pas de booter sur cle usb directement..."

case $? in 
0)
genBootCd
;; ## fin veux le cd de boot
1)
;;

esac

else
	genBootCd
	direct="true"
fi

}

function genIso()
{
## recheck syslinux
syslinux_build
lg=$(env | grep ^LANG=.* | sed 's/.*=//;s/\..*//')
mlg=$(env | grep ^LANG=.* | sed 's/.*=//;s/_.*//')

zenity --question --text "voulez vous Recompiler isolinux avec langue $lg par defaut ? (conseillé)"
case $? in
	0)
	echo -e "mise à jour des sources \n"
	apt-get update &>/dev/null
	echo -e "Téléchargement de sources gfxboot-theme-ubuntu... \n"
	dpkg -l | grep dpkg-dev &>/dev/null || apt-get -y install dpkg-dev &>/dev/null
	cd /tmp
	apt-get source gfxboot-theme-ubuntu &>/dev/null
	echo -e "Mise en place et nettoyage... \n"
	rm *.dsc *.tar.gz *.gz *.diff.gz &>/dev/null
	cd gfxboot-theme-ubuntu*
    if [[ `ls po/ | grep -E "$lg"` ]]; then
        LG=$lg
    elif [[ `ls po/ | grep -E "$mlg"` ]]; then
        LG=$mlg
    else
        LG=en
    fi
    echo -e "\ncompile gfxboot avec la langue $LG \n"
    make DEFAULT_LANG=$LG
	sudo cp -af boot/* "${DISTDIR}"/cdrom/isolinux/
	cd "${DISTDIR}"/cdrom/isolinux/
	echo "$LG" | tee langlist &>/dev/null
	
	echo -e "Isolinux $LG ok ! \n"
	;;
	1) ;;
esac

echo -e "Creation d un fichier iso, Nettoyage des fichiers... \n"
	sed -i '/^ui gfxboot/d' "${DISTDIR}"/cdrom/isolinux/isolinux.cfg
	rm "${DISTDIR}"/cdrom/casper/filesystem* &>/dev/null
	cd "${DISTDIR}"/cdrom 
	## copie les fichiers...
if [ ! -e "${DISTDIR}"/usb/casper/filesystem.squashfs ]; then
	 generate_files
fi
	copyType="cdrom"
	copy_files

## image de boot
## changement image boot ou pas
zenity --question --title "Splash screen" --text "Voulez vous choisir une autre image de fond pour isolinux ?
(Image que vous verrez au boot de votre cd)"
case $? in
0) zenity --question --text "Voulez vous lancer firefox sur gnome-look pour choisir une image ?"
case $? in
0) killall -q -9 firefox-bin
firefox http://www.gnome-look.org/index.php?xcontentmode=170
;;
1) echo  "ok on continue"
;;
esac

splash_image=$(zenity --file-selection --filename=/home/$USER/ --title "Maintenant, selectionnez votre image...")	
## ok on copie l image
echo -e "Redimensionne l'image "$splash_image" ! \n"
rm "${DISTDIR}"/cdrom/isolinux/splash.pcx &>/dev/null
convert -resize "640x480!" $splash_image -quality "100" -colors 256 "${DISTDIR}"/cdrom/isolinux/splash.pcx
;;
1) 
;;

esac


## recree initrd
installType="cdrom"
make_initrd

## ajoute aufs par defaut (pquoi encore unionfs ???)
sed -i 's/quiet/union=aufs quiet/g' "${DISTDIR}"/cdrom/isolinux/isolinux.cfg

	## regenere le md5
	cd "${DISTDIR}"/cdrom 
	echo -e "Regenere le md5 dans le cdrom \n"
	find . -type f -print0 |xargs -0 md5sum |tee md5sum.txt
	cd "${DISTDIR}"
	rm *.iso &>/dev/null
	echo ""
	echo -e "Creation de l iso avec mkisofs ... \n" 
	sleep 3
	mkisofs -r -V "$DIST" -cache-inodes -J -l -b isolinux/isolinux.bin -c isolinux/boot.cat -no-emul-boot -boot-load-size 4 -boot-info-table -o "$DIST".iso cdrom
	
	echo -e "Regenere le md5 public de votre iso \n"
	md5sum "$DIST".iso | tee MD5SUM
	
	if [ ! -e "$DIST".iso ]; then
		echo -e "probleme avec la creation de l iso, merci de remonter le bug"
	else
		echo ""$DIST".iso, cree avec succes !"
	fi
echo ""	
echo " #######################################"	
echo " #     Creation de l'iso terminée....  #"
echo " #######################################"
echo""

}

function genUsbKey()
{
## lance detection clef
	getKey
## verify syslinux
testConnect
syslinux_build
## calcul poids image
	usbdirSize
## formatage 
	cleanKey
## Controle de la cle
	check_key
## copie des fichiers sur la cle
	copyType="usb"
	copy_files
## Configure extlinux si necessaire...
	extlinuxconf
## ecris le mbr sur la cle (depuis syslinux)
	mbr
## propose de creer un cd de boot pour booter la cle usb 
	mkBootCd
	
echo ""	
echo " #######################################"	
echo " #          Cle usb terminée....       #"
echo " #######################################"
echo""	

}

function chooseMedia() 
{

choix=`zenity --width=550 --height=250 --title "Choix operation a effectuer" --list --text "Que voulez vous faire ?" --radiolist --column "Choix" --column "Action" --column "Description"  \
TRUE "Usb" "(Re)créer une clé usb bootable" \
FALSE "Boot" "Créer un cd de demarrage pour les cartes meres qui ne 
bootent pas sur usb..." \
FALSE "Iso" "Recréer un fichier iso" \
FALSE "Usb/Iso" "Preparer les deux ..." `
case $? in
0)
	case $choix in
		Usb)
			installType="usb"
			genUsbKey
			## force umount 
			force_umount
		;;
		Boot)
			direct="true"
			mkBootCd
		;;
		Iso)
			installType="cdrom"
			genIso  
			## force umount 
			force_umount
		;;
		Usb/Iso)
			installType="usb cdrom"
			genUsbKey
			genIso
			## force umount 
			force_umount
		;;
	esac
;;# fin 0

1)
noQemu="true"
force_umount 
;;

esac

}

function testConnect() 
{
testconnexion=`wget www.google.fr -O /tmp/test &>/dev/null 2>&1`
if [ $? != 0 ]; then
sleep 5
echo  "Pause, vous êtes déconnecté !, en attente de reconnexion"
testConnect
fi
}

function scanKey()
{

rm /tmp/usbscan &>/dev/null
rm /tmp/hallist &>/dev/null
## refresh blkid
blkid -g

usbdev=$(sudo blkid | grep -e "extlinux-ro" | awk '{print $1}' | sed 's/.*\///' | sed 's/://' | sed 's/[0-9]//')

if [ -z "$usbdev" ]; then

## passe a la detection par hal direct....
devlist=$(cat /proc/partitions | grep sd | awk '{print $4}' | sed "s/'//g" | sed 's/.*\///g' | sort | tee /tmp/hallist)

(zenity --warning --text "Merci de brancher la clé que vous souhaitez utiliser ...

Si celle-ci est déjà branchée et/ou n'a jamais ete utilisée pour ce script
merci de la debrancher, patienter le temps que la détection se fasse
et rebrancher finalement comme indiqué...

Cette fenêtre sera fermée automatiquement une fois votre clé détectée." &) 2>/dev/null

while [ -z "$usbdev" ]; do
		usbscan=$(cat /proc/partitions | grep sd | awk '{print $4}' | sed "s/'//g" | sed 's/.*\///g' | sort | tee /tmp/usbscan)
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
while [[ ! $(cat /proc/partitions | grep -e "$usbdev") ]]; do
	echo -e "cle détectée sur /dev/$usbdev, Rebranchez la pour continuer..."
	sleep 10
done

usbpartType=$(blkid -s TYPE /dev/"$usbdev"1 | awk {'print $2'} | sed 's/TYPE="//;s/"//')
if [ "$usbpartType" = "vfat" ]; then
	usbpartMountType="fat"
	usbpartFormatType="fat32"
else
	usbpartMountType="ext4"
	usbpartFormatType="ext4"
fi

echo -e "\nFormat de partition: $usbpartType \n"
}


##########################################################
## Detection automatique de la cle usb et extractions des infos necessaires 
function getKey()
{
## clean des dossiers au cas ou (cree des bugs) et autres petits checks
umount /media/custom-usb &>/dev/null
umount /media/casper-rw &>/dev/null
umount /media/extlinux-ro &>/dev/null
rm -Rf /media/extlinux-ro &>/dev/null
rm -Rf /media/casper-rw &>/dev/null
chattr -R -i /media/custom-usb/ldlinux.sys &>/dev/null
rm /media/custom-usb/ldlinux.sys
rm -Rf /media/custom-usb &>/dev/null
mkdir /media/custom-usb &>/dev/null
## scan de la cle

scanKey

usbpart=$(cat /proc/partitions | grep $usbdev | awk '{print $4}' | sed "s/^$usbdev$//g;/^$/d" | sort | xargs)

if [[ "$usbdev" && -z "$usbpart" || "$usbpart" = "$usbdev" ]]; then
	echo 
	echo  -e "Votre clé /dev/"$usbdev" est actuellement vierge, on continue... \n"
else
	echo ""
 	echo  "Périphérique détecté sur /dev/"$usbdev"" 
	echo  "Liste des partitions:" $usbpart
	sleep 2
fi

## ptit check etre sur que ca n est pas un disque dur externe qui est apparu par malchance dans le syslog... 
chkfstab=`cat /etc/fstab | grep /dev/$usbdev'1'`
if [ ! -z "$chkfstab" ]; then
echo ""
echo -e "Erreur le disque sélectionné fait partie de fstab,ce script est fait pour des volumes amovibles \
et /dev/$usbdev ne devrait pas figurer dans fstab!... Sortie \n"
exit 0
fi                     

}

##########################################################
## Fonction de controle de la cle, check des labels des partitions du format et leur taille
function check_key()
{
echo ""
echo -e "Contrôle de la clé..."

labelro="extlinux-ro"
labelrw="casper-rw"

FSPART1=`blkid -s TYPE /dev/"$usbdev"1 | awk {'print $2'} | grep $usbpartMountType`
FSPART2=`blkid -s TYPE /dev/"$usbdev"2 | awk {'print $2'} | grep $usbpartMountType`
LBPART1=`blkid /dev/"$usbdev"1 | grep "$labelro"`
LBPART2=`blkid /dev/"$usbdev"2 | grep "$labelrw"`

if [ -z "${FSPART1}" ]; then 
	echo  "Erreur la partition /dev/"$usbdev"1 n'est pas au bon format!"
exit 0
elif [ -z "${FSPART2}" ]; then 
	echo  "Erreur la partition /dev/"$usbdev"2 n'est pas au bon format!"
exit 0
elif [ -z "${LBPART1}" ]; then 
	echo  "Erreur la partition /dev/"$usbdev"1 n'a pas le bon label!"
exit 0
elif [ -z "${LBPART2}" ]; then 
	echo  "Erreur la partition /dev/"$usbdev"2 n'a pas le bon label!"
exit 0
else
	echo 
	echo  "Partition 1 ok : Format \"$usbpartType\", Label: \"$labelro\""
	echo  "Partition 2 ok : Format \"$usbpartType\", Label: \"$labelrw\""
	
	echo 
	echo  "Test des partitions de la clé ok"
	echo 
	sleep 3

fi
UMOUNT_SD
}


##########################################################
## Creation et Formattage des partitions sur la cle usb
function cleanKey()
{
echo  "Sauvegarde du mbr si necessaire"
sleep 2
if [ ! -e "${WORK}/temp/mbr-original.img" &>/dev/null ]; then
	dd if=/dev/"$usbdev" of="${WORK}/temp/mbr-original.img" bs=446 count=1 &>/dev/null 	
	echo  "MBR sauvegarde !"
	echo 
	sleep 2
else
	echo -e "MBR deja sauvegarde...\n"
fi
echo -e "Sauvegarde de la table de partitions... \n"
sleep 2
if [ ! -e "${WORK}/temp/tbpart.out" ]; then	
	sfdisk -d /dev/"$usbdev" | tee "${WORK}"/temp/tbpart.out &>/dev/null 	
	echo 
	echo -e "Liste des partitions de votre clé sauvegardée \n"
	sleep 2
else
	echo -e "Liste des partitions déjà sauvegardée \n"
fi

TOTAL=$(parted /dev/$usbdev unit Mb print | grep "$usbdev" | sed 's/.*://' | tail -n 1 | sed 's/MB//')
TOTALS=$(parted /dev/$usbdev unit s print | grep "$usbdev" | sed 's/.*://' | tail -n 1 | sed 's/s//')
if [ "$PRESIZE" -gt "$TOTAL" ]; then
	zenity --error --title="Erreur fatale !" --text="l'espace libre nécessaire est de $PRESIZE Mb mais vous ne disposez que de $TOTAL Mb sur votre cle... sortie"
	exit 0
fi

if [ -z "$usbpart" ]; then

zenity --question --text "Votre clé \"$usbdev\" est actuellement vierge
et doit être formatée !

Espace disponible sur la clé : $TOTAL MB
 
Si tout est ok, cliquez sur \"Valider\" pour continuer."

case $? in 
0)
dd if=/dev/zero of=/dev/"$usbdev" bs=512 count=1
parted -s /dev/"$usbdev" mklabel msdos
sleep 5
echo 
echo  "fin  du préformatage ..."
echo 
sleep 3

## vide la liste des partitions
usbpart=""
## et execute le formatage de la cle
makeKey
;;
1)
exit 0
;;
esac

else
devname=$(blkid | grep "$usbdev"1 | awk '{print $2}' | sed 's/[A-Z\ = "]//g')
actual=$(parted /dev/"$usbdev" unit Mb print | grep -w "^ 1" | awk {'print $3'} | sed 's/[A-Z\, a-z/]//g')
FSPART1=`blkid -s TYPE /dev/"$usbdev"1 | awk {'print $2'} | grep $usbpartMountType | sed 's/TYPE=\"//;s/\"//'`
FSPART2=`blkid -s TYPE /dev/"$usbdev"2 | awk {'print $2'} | grep $usbpartMountType | sed 's/TYPE=\"//;s/\"//'`

if [[ "$PART1" -gt "$actual" || "$devname" != "extlinux-ro" || "$FSPART1" != "$usbpartType" || "$FSPART2" != "$usbpartType" ]]; then

zenity --question --text "Votre clé \"$usbdev\" doit être reformatée !

Espace disponible sur la clé : $TOTAL MB
Taille actuelle de /dev/${usbdev}1 : $actual MB
Taille du dossier usb : $PRESIZE MB
Taille nécessaire sur /dev/${usbdev}1 : $PART1_SIZE MB
Nom de la partition /dev/${usbdev}1 : $devname

Si vous avez des fichiers importants sur votre clé, 
sauvegardez les avant de continuer ou cliquez \"Annuler\"

Si tout est ok, cliquez sur \"Valider\"."

case $? in 
0)
echo  "Création de la nouvelle table de partition..."
dd if=/dev/zero of=/dev/$usbdev bs=512 count=1
parted -s /dev/$usbdev mklabel msdos
sleep 5
echo 
sleep 3

## vide la liste des partitions
usbpart=""
## et execute le formatage de la cle
makeKey
;;
1)
exit 0
;;
esac
else
echo  "La partition "$usbdev"1 est deja prête, pas besoin de formater"
fi
fi

UMOUNT_SD

}

##########################################################
#calcul taille dispo actuellement sur sdx1 (au cas ou on devrait reformater)
function makeKey()
{

if [ -n "$usbpart" ]; then
	DEBUT=$(parted /dev/"$usbdev"1 unit s print | grep s | awk {'print $2'} | tail -n 1 | sed 's/[a-z\/]//g')
	FIN=$(parted /dev/"$usbdev"1 unit s print | grep s | awk {'print $3'} | tail -n 1 | sed 's/[a-z\/]//g')
else
	usbpart=""$usbdev"1 "$usbdev"2"
fi

if [ -z "$DEBUT" ]; then
	echo  "Aucune partition "$usbdev"1 pour le moment"
else
	echo  "DEBUT : $DEBUT"
fi

if [ -z "$FIN" ]; then
	echo  "Aucune partition "$usbdev"2 pour le moment"
else
	echo  "FIN : $FIN"
fi


## synchronise la table de partition
partprobe /dev/$usbdev
echo 
echo  "Prepare la partition /dev/"$usbdev"1, taille : "$PART1_SIZE" MB"
PART=/dev/$usbdev
#if [ ! -e "/usr/local/bin/sizer" ]; then
#	cd /usr/local/bin
#	wget http://www.penguincape.org/downloads/scripts/ubukey/launchers/sizer &>/dev/null
#	chmod +x sizer
#fi

#FIRSTPART=`sizer $PART $PART1`
#SECTORS=`cat /tmp/diskpart | grep "^secteurs" | sed 's/secteurs : //'`
## print values to log
#cat /tmp/diskpart | tee -a $LOG &>/dev/null

## choix du type de formattage
partType=$(zenity --list --checklist --width 650 --height 500 --title "Partitionnement" \
--column "choix" --column "Session" --text "choisissez le format de partition à utiliser" \ FALSE "ext4" \ FALSE "vfat")

if [ "$partType" = "vfat" ]; then
	usbpartType="vfat"
	usbpartMountType="fat"
	usbpartFormatType="fat32"
else
	usbpartType="ext4"
	usbpartMountType="ext4"
	usbpartFormatType="ext4"
fi

parted -s /dev/$usbdev unit MB mkpart primary $usbpartFormatType 1 $PART1_SIZE -a cyl >/dev/null 2>&1

UMOUNT_SD

echo 
echo  "Prépare la partition /dev/"$usbdev"2"
TOTAL=$(parted /dev/$usbdev unit Mb print | grep "$usbdev" | sed 's/.*://' | tail -n 1 | sed 's/MB//')
SECPART=$(( $TOTAL - $PART1_SIZE ))
## securitee fat...
if [[ $SECPART -gt 3990 ]]; then
	SECPART=$(( $PART1_SIZE + 3990 ))
fi
parted -s /dev/$usbdev unit MB mkpart primary $usbpartFormatType $PART1_SIZE $SECPART -a cyl >/dev/null 2>&1 ## TOTALSSSSS for sectors...
UMOUNT_SD

echo -e "Formate les partitions ..."
if [ "$usbpartFormatType" = "fat32" ]; then
	mkdosfs -F 32 -n extlinux-ro /dev/$usbdev'1' >/dev/null 2>&1 & wait_valid $usbdev'1'
	UMOUNT_SD
	mkdosfs -F 32 -n casper-rw /dev/$usbdev'2' >/dev/null 2>&1 & wait_valid $usbdev'2'
	UMOUNT_SD
else
	mke2fs -T ext4 -b 4096 -L extlinux-ro /dev/$usbdev'1' >/dev/null 2>&1 & wait_valid $usbdev'1'
	UMOUNT_SD
	mke2fs -T ext4 -b 4096 -L casper-rw /dev/$usbdev'2' >/dev/null 2>&1 & wait_valid $usbdev'2'
	UMOUNT_SD	
	echo -e "disable journal for ext4"
	tune2fs -O ^has_journal /dev/$usbdev'1' >/dev/null 2>&1
	tune2fs -O ^has_journal /dev/$usbdev'2' >/dev/null 2>&1

	#zenity --progress --pulsate --text "Formatage de la partition "$usbdev"1" --auto-close #formate et pose label
	#while [[ `ps aux | grep [m]kfs.ext4` ]]; do sleep 3; done
	#zenity --progress --pulsate --text "Formatage de la partition "$usbdev"2" --auto-close #formate et pose label
	#while [[ `ps aux | grep [m]kfs.ext4` ]]; do sleep 3; done
fi

UMOUNT_SD
parted -s /dev/$usbdev set 1 boot on
UMOUNT_SD

}

function wait_valid () {
	part=$1
	sec=0
	sleep 2
	echo -e "\nformatage de /dev/$part en cours..."
	while [ : ] ; do
		check="$(sudo blkid -s TYPE /dev/$part | awk {'print $2'} | grep $usbpartMountType | sed 's/TYPE=\"//;s/\"//')"
		if [ "$check" = "$usbpartType" ]; then
			echo -e "Formatage terminé ! \n"
			break
		elif [ $sec -eq 120 ]; then
			echo -e "formatage impossible sur /dev/$part \n"
			exit 1
		else
			sleep 1
			sec=$(( $sec+1 ))
		fi
	done 
}

##########################################################
## prepare les fichiers dans le dossier usb et extrais la taille pour formatage de la cle 
function usbdirSize()
{
	
if [ -z "$DIRECT_COPY" ]; then
	## verifie si filesystem.squashfs est bien la...
	if [ ! -e "${DISTDIR}"/usb/casper/filesystem.squashfs ]; then
		echo -e "Filesystem.squashfs manquant, le fichier va être recrée \n"
			generate_files
	fi
fi 

## et le initrd a jour
if [ -z "$DIRECT_COPY" ]; then
make_initrd
fi

echo -e "Détection de l'espace nécessaire sur la cle \n"
rm -R "${DISTDIR}/usb/ubuntu" &>/dev/null

## poids dossier usb
USBSIZE=$(($(du -sB 1 "${DISTDIR}/usb" | awk '{print $1}')/1000/1000))

## check si copie directe
if [ -n "$DIRECT_COPY" ]; then
	SQUASHSIZE=$(($(du -sB 1 "$DISTDIR/old/casper/filesystem.squashfs" | awk '{print $1}')/1000/1000))
	PRESIZE=$(( $SQUASHSIZE + $USBSIZE ))
else
	PRESIZE=$USBSIZE
fi

## check final
PART1=$(($PRESIZE + (($PRESIZE*6/100))))
#sleep 3

taille_souhaite="$PART1" #en MB
heads=$(sfdisk -G /dev/"$usbdev" | awk '{print $4}')
sectors=$(sfdisk -G /dev/"$usbdev" | awk '{print $6}')
cylinders=$(sfdisk -G /dev/"$usbdev" | awk '{print $2}')
i=0
while [ $i -lt $cylinders ]; do
i=$(($i+1))
PART1_SIZE=$(($i*$(($heads * $sectors * 512))/1000/1000+1))
if [ $PART1_SIZE -gt $taille_souhaite ]; then
break
fi
done

echo 
echo  "Au moins $PART1_SIZE MB d'espace libre sera nécessaire sur /dev/"$usbdev"1"
echo 

}

if [ ! -e "${DISTDIR}"/usb/casper/filesystem.squashfs ]; then
	 generate_files
fi
chooseMedia
