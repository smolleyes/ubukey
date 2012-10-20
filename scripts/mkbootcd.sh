#!/bin/bash

DIST=$1
DISTDIR=$2

source /etc/ubukey/config

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

echo -e "Genere le fichier de conf extlinux"

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
