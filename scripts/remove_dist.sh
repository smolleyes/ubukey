#!/bin/bash

DIST=$1
DISTDIR=$2
USER=$3

source /etc/ubukey/config

echo -e "suppression de la distribution $DIST installee dans ${DISTDIR} \n"
if [ -e "$DISTDIR" ]; then
	if [[ `mount | grep ${DISTDIR}/chroot` ]]; then
		echo "Des dossier sont toujours montes dans ${DISTDIR}/chroot/media, nettoyage..."
		#sed -i 's/\/home\/'$USER'/\/root/' "${DISTDIR}"/chroot/etc/passwd
		mv "${DISTDIR}"/chroot/etc/mtab-save "${DISTDIR}"/chroot/etc/mtab
		mv "${DISTDIR}"/chroot/etc/fstab-save "${DISTDIR}"/chroot/etc/fstab
		rm "${DISTDIR}"/chroot/var/lib/dbus/machine-id &>/dev/null
		rm -R "${DISTDIR}"/chroot/usr/share/ubukey &>/dev/null
		if [[ !  `grep -w "\/root" "${DISTDIR}"/chroot/etc/passwd` ]]; then
		echo -e "Probleme avec /etc/passwd..."
		sleep 5
		sed -i 's/\/home\/'$USER'/\/root/' "${DISTDIR}"/chroot/etc/passwd
		fi


		## nettoie et re verifie fichiers de conf
		rm -f "${DISTDIR}"/chroot/etc/skel/*/{ubukey-assist,quit-chroot,gc}.desktop  &>/dev/null
		umount -l -f "${DISTDIR}"/chroot/media/pc-local &>/dev/null
		umount -l -f "${DISTDIR}"/chroot/proc/sys/fs/binfmt_misc binfmt_misc  &>/dev/null
		umount -l -f "${DISTDIR}"/chroot/proc &>/dev/null
		umount -l -f "${DISTDIR}"/chroot/sys &>/dev/null
		umount -l -f "${DISTDIR}"/chroot/dev/pts &>/dev/null
		umount -l -f "${DISTDIR}"/chroot/dev &>/dev/null
		umount -f "${DISTDIR}"/chroot/var/run/dbus &>/dev/null
		rm "${DISTDIR}"/chroot/var/run/* &>/dev/null
		umount -l -f "${DISTDIR}"/chroot/media/pc-local/media &>/dev/null
		umount -l -f "${DISTDIR}"/chroot/media/pc-local/home &>/dev/null
		umount /dev/loop* -l -f &>/dev/null
		if [[ ! `mount | grep "pc-local"` ]]; then
			rm -R "${DISTDIR}"/chroot/media/pc-local &>/dev/null
		fi
		sed -i '/^>/d;/WARNING/d' "${DISTDIR}"/logs/chrootlog.log &>/dev/null

		if [[ $(mount | grep "/proc/sys/fs/binfmt_misc") ]]; then
		umount /proc/sys/fs/binfmt_misc &>/dev/null
		kill -9 `lsof -atw "${DISTDIR}"/chroot | xargs` &>/dev/null
		umount -l -f "${DISTDIR}"/chroot/proc &>/dev/null
		umount -l -f "${DISTDIR}"/chroot/sys &>/dev/null
		fi

		echo -e "Verifie l integritee des fichiers passwd/groups et shadow \n"
		sed -i '/^[^:]*:[^:]*:[1-9][0-9][0-9][0-9]:/d' "${DISTDIR}"/chroot/etc/passwd &>/dev/null
		sed -i '/^[^:]*:[^:]*:[12][0-9][0-9][0-9][0-9]:/d' "${DISTDIR}"/chroot/etc/passwd &>/dev/null
		sed -i '/^[^:]*:[^:]*:[1-9][0-9][0-9][0-9]:/d' "${DISTDIR}"/chroot/etc/group &>/dev/null
		sed -i '/^[^:]*:[^:]*:[12][0-9][0-9][0-9][0-9]:/d' "${DISTDIR}"/chroot/etc/group &>/dev/null
		sed -i '/^[^:]*:[^:]*:[^:]*:'$USER'/d' "${DISTDIR}"/chroot/etc/group &>/dev/null
		sed -i '/'$USER'/d' "${DISTDIR}"/chroot/etc/shadow- &>/dev/null
		sed -i '/'$USER'/d' "${DISTDIR}"/chroot/etc/gshadow- &>/dev/null
		sed -i '/'$USER'/d' "${DISTDIR}"/chroot/etc/gshadow &>/dev/null
		sed -i '/'$USER'/d' "${DISTDIR}"/chroot/etc/shadow &>/dev/null
		sed -i '/'$USER'/d' "${DISTDIR}"/chroot/etc/group &>/dev/null
		sed -i '/'$USER'/d' "${DISTDIR}"/chroot/etc/passwd &>/dev/null
		echo -e "\nnettoyage termine....\n"
		if [[ `mount | grep ${DISTDIR}/chroot` ]]; then
			exit 1
			echo -e "Suppression de $DIST impossible !... ok \n"
		else
			rm -R "${DISTDIR}"
			echo -e "Suppression de $DIST... ok \n"

		fi
	else
		rm -R "${DISTDIR}"
		echo -e "Suppression de $DIST... ok \n"

	fi
fi
