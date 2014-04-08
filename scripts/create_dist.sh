#!/bin/bash

WORK=$1
USER=$2

source /home/$SUDO_USER/.config/ubukey/sessionConf

function create_dist()
{

	## check ubukey link
	if [ ! -e "/usr/share/ubukey" ]; then
		ln -s "$(pwd)/.." /usr/share/ubukey
	fi

	## menu selection choix distrib a preparer
	DISTCHOICE=`zenity --width=600 --height=500 --title "Choix Distribution a preparer" --list \
		--radiolist --column "Choix" --column "Distribution" --column "Description" \
		--text "Choisissez le type de distribution a utiliser

	<span color=\"red\">Information:</span>
	Si vous comptez utiliser un iso perso ou d'une autre distribution
	Choisissez son equivalence (gnome, kde, xfce etc...)
	" \
		FALSE "Raring-ringtail" "Ubuntu raring i386" \
		FALSE "Raring-ringtail-64" "Ubuntu raring 64 bits" \
		FALSE "Raring-kubuntu" "Kubuntu raring i386" \
		FALSE "Raring-kubuntu-64" "Kubuntu raring 64 bits" \
		FALSE "Raring-lubuntu" "Lubuntu raring i386" \
		FALSE "Raring-lubuntu-64" "Lubuntu raring 64 bits" \
		FALSE "Raring-xubuntu" "Xubuntu raring i386" \
		FALSE "Raring-xubuntu-64" "Xubuntu raring 64 bits" \
		FALSE "Quantal-quetzal" "Ubuntu Quantal i386" \
		FALSE "Quantal-quetzal-64" "Ubuntu Quantal 64 bits" \
		FALSE "Quantal-kubuntu" "Kubuntu Quantal i386" \
		FALSE "Quantal-kubuntu-64" "Kubuntu Quantal 64 bits" \
		FALSE "Quantal-lubuntu" "Lubuntu Quantal i386" \
		FALSE "Quantal-lubuntu-64" "Lubuntu Quantal 64 bits" \
		FALSE "Quantal-xubuntu" "Xubuntu Quantal i386" \
		FALSE "Quantal-xubuntu-64" "Xubuntu Quantal 64 bits" \
		FALSE "Precise-pangolin" "Ubuntu precise pangolin" \
		FALSE "Precise-pangolin-64" "Ubuntu precise pangolin 64 bits" \
		FALSE "Precise-kubuntu" "Kubuntu precise pangolin" \
		FALSE "Precise-kubuntu-64" "Kubuntu precise pangolin 64 bits" \
		FALSE "Precise-lubuntu" "Lbuntu precise pangolin" \
		FALSE "Precise-lubuntu-64" "Lubuntu precise pangolin 64 bits" \
		FALSE "Precise-xubuntu" "Xubuntu precise pangolin" \
		FALSE "Precise-xubuntu-64" "Xubuntu precise pangolin 64 bits" \
		FALSE "Custom" "Preparer vos distribution par debootstrap (Expert!)"
	`
	# cd /tmp
	# rm MD5* >/dev/null
	# wget http://cdimage.ubuntu.com/daily-live/current/MD5SUMS
	# MD5SUM=$(cat MD5SUMS | grep desktop-i386 | awk '{print $1}')
	case $DISTCHOICE in
		Raring-ringtail)
		ISOURL="http://releases.ubuntu.com/13.04/ubuntu-13.04-desktop-i386.iso"
		ISONAME="ubuntu-13.04-desktop-i386.iso"
		ISOTYPE="gnome"
		MD5SUM="5d5d1a7da2a0659b163d4f8bd70fbe6f"
		;;
		Raring-ringtail-64)
		ISOURL="http://releases.ubuntu.com/13.04/ubuntu-13.04-desktop-amd64.iso"
		ISONAME="ubuntu-13.04-desktop-amd64.iso"
		ISOTYPE="gnome"
		MD5SUM="8d72e2db7e72e13813731eab37a14d26"
		;;
		Raring-kubuntu)
		ISOURL="http://cdimage.ubuntu.com/kubuntu/releases/13.04/release/kubuntu-13.04-desktop-i386.iso"
		ISONAME="kubuntu-13.04-desktop-i386.iso"
		ISOTYPE="kde4"
		MD5SUM="3db062392b1978bbdb8422aee2724a69"
		;;
		Raring-kubuntu-64)
		ISOURL="http://cdimage.ubuntu.com/kubuntu/releases/13.04/release/kubuntu-13.04-desktop-amd64.iso"
		ISONAME="kubuntu-13.04-desktop-amd64.iso"
		ISOTYPE="kde4"
		MD5SUM="a3d32a4dc840c20c70ae4839341ef605"
		;;
		Raring-xubuntu)
		ISOURL="http://cdimage.ubuntu.com/xubuntu/releases/13.04/release/xubuntu-13.04-desktop-i386.iso"
		ISONAME="xubuntu-13.04-desktop-i386.iso"
		ISOTYPE="xfce4"
		MD5SUM="1048df77899ca8d9d6ba23427b4d6259"
		;;
		Raring-xubuntu-64)
		ISOURL="http://cdimage.ubuntu.com/xubuntu/releases/13.04/release/xubuntu-13.04-desktop-amd64.iso"
		ISONAME="xubuntu-13.04-desktop-amd64.iso"
		ISOTYPE="xfce4"
		MD5SUM="8b7d7168b67c58307fa46d683d98c68e"
		;;
		Raring-lubuntu)
		ISOURL="http://cdimage.ubuntu.com/lubuntu/releases/13.04/release/lubuntu-13.04-desktop-i386.iso"
		ISONAME="lubuntu-13.04-desktop-i386.iso"
		ISOTYPE="lxde"
		MD5SUM="486d94f51b42b401ab72ca8fcedb2e97"
		;;
		Raring-lubuntu-64)
		ISOURL="http://cdimage.ubuntu.com/lubuntu/releases/13.04/release/lubuntu-13.04-desktop-amd64.iso"
		ISONAME="lubuntu-13.04-desktop-amd64.iso"
		ISOTYPE="lxde"
		MD5SUM="4b8abeb5d1fb8caf314fe5e1e839193a"
		;;
		Quantal-quetzal)
		ISOURL="http://ubuntu.mirrors.proxad.net/quantal/ubuntu-12.10-desktop-i386.iso"
		ISONAME="ubuntu-12.10-desktop-i386.iso"
		ISOTYPE="gnome"
		MD5SUM="b4191c1d1d6fdf358c154f8bf86b97dd"
		;;
		Quantal-quetzal-64)
		ISOURL="http://ubuntu.mirrors.proxad.net/quantal/ubuntu-12.10-desktop-amd64.iso"
		ISONAME="ubuntu-12.10-desktop-amd64.iso"
		ISOTYPE="gnome"
		MD5SUM="7ad57cadae955bd04019389d4b9c1dcb"
		;;
		Quantal-kubuntu)
		ISOURL="http://cdimage.ubuntu.com/kubuntu/releases/12.10/release/kubuntu-12.10-desktop-i386.iso"
		ISONAME="kubuntu-12.10-desktop-i386.iso"
		ISOTYPE="kde4"
		MD5SUM="56cfb4036802f1619961d22c1a763103"
		;;
		Quantal-kubuntu-64)
		ISOURL="http://cdimage.ubuntu.com/kubuntu/releases/12.10/release/kubuntu-12.10-desktop-amd64.iso"
		ISONAME="kubuntu-12.10-desktop-amd64.iso"
		ISOTYPE="kde4"
		MD5SUM="dc63881988af54677ab3084d031a12b6"
		;;
		Quantal-xubuntu)
		ISOURL="http://cdimage.ubuntu.com/xubuntu/releases/12.10/release/xubuntu-12.10-desktop-i386.iso"
		ISONAME="xubuntu-12.10-desktop-i386.iso"
		ISOTYPE="xfce4"
		MD5SUM="bd87be6626efa4ebf7678f5e2c942b57"
		;;
		Quantal-xubuntu-64)
		ISOURL="http://cdimage.ubuntu.com/xubuntu/releases/12.10/release/xubuntu-12.10-desktop-amd64.iso"
		ISONAME="xubuntu-12.10-desktop-amd64.iso"
		ISOTYPE="xfce4"
		MD5SUM="f5f80e22cb1c80232efcbd8e2c5955f8"
		;;
		Quantal-lubuntu)
		ISOURL="http://cdimage.ubuntu.com/lubuntu/releases/quantal/release/lubuntu-12.10-desktop-i386.iso"
		ISONAME="lubuntu-12.10-desktop-i386.iso"
		ISOTYPE="lxde"
		MD5SUM="a7fed6c40b4969d4a3c9c0a9ee228cf2"
		;;
		Quantal-lubuntu-64)
		ISOURL="http://cdimage.ubuntu.com/lubuntu/releases/12.10/release/lubuntu-12.10-desktop-amd64.iso"
		ISONAME="lubuntu-12.10-desktop-amd64.iso"
		ISOTYPE="lxde"
		MD5SUM="bddb521817360540c0e54616427c003e"
		;;
		Precise-pangolin)
		ISOURL="http://ubuntu.mirrors.proxad.net/12.04/ubuntu-12.04-desktop-i386.iso"
		ISONAME="ubuntu-12.04-desktop-i386.iso"
		ISOTYPE="gnome"
		MD5SUM="d791352694374f1c478779f7f4447a3f"
		;;
		Precise-pangolin-64)
		ISOURL="http://ubuntu.mirrors.proxad.net/12.04/ubuntu-12.04-desktop-amd64.iso"
		ISONAME="ubuntu-12.04-desktop-amd64.iso"
		ISOTYPE="gnome"
		MD5SUM="128f0c16f4734c420b0185a492d92e52"
		;;
		Precise-kubuntu)
		ISOURL="http://cdimage.ubuntu.com/kubuntu/releases/12.04/release/kubuntu-12.04-desktop-i386.iso"
		ISONAME="kubuntu-12.04-desktop-i386.iso"
		ISOTYPE="kde4"
		MD5SUM="11cd581db5740a62d58eeb39824fc11f"
		;;
		Precise-kubuntu-64)
		ISOURL="http://cdimage.ubuntu.com/kubuntu/releases/12.04/release/kubuntu-12.04-desktop-amd64.iso"
		ISONAME="kubuntu-12.04-desktop-amd64.iso"
		ISOTYPE="kde4"
		MD5SUM="7fbb273e8764aeb307fecfaccb9e742f"
		;;
		Precise-xubuntu)
		ISOURL="http://cdimage.ubuntu.com/xubuntu/releases/12.04/release/xubuntu-12.04-desktop-i386.iso"
		ISONAME="xubuntu-12.04-desktop-i386.iso"
		ISOTYPE="xfce4"
		MD5SUM="52fddd81e75bb421a5435a42ca9ec6df"
		;;
		Precise-xubuntu-64)
		ISOURL="http://cdimage.ubuntu.com/xubuntu/releases/12.04/release/xubuntu-12.04-desktop-amd64.iso"
		ISONAME="xubuntu-12.04-desktop-amd64.iso"
		ISOTYPE="xfce4"
		MD5SUM="724224b8d62c7bccecdee6b82850c0e6"
		;;
		Precise-lubuntu)
		ISOURL="http://cdimage.ubuntu.com/lubuntu/releases/12.04/release/lubuntu-12.04-desktop-i386.iso"
		ISONAME="lubuntu-12.04-desktop-i386.iso"
		ISOTYPE="lxde"
		MD5SUM="0fc9564b8fde8ff56100c3d7814fa884"
		;;
		Precise-lubuntu-64)
		ISOURL="http://cdimage.ubuntu.com/lubuntu/releases/12.04/release/lubuntu-12.04-desktop-amd64.iso"
		ISONAME="lubuntu-12.04-desktop-amd64.iso"
		ISOTYPE="lxde"
		MD5SUM="fca2034b89e8a0acd6536d41ccec061c"
		;;
		Custom)
		/bin/bash $UBUKEYDIR/scripts/debootstrap_dist.sh "$WORK"
		exit 1
		;;

		*)
		exit 1
		;;

	esac ## fin choix dist

	## defini repertoire de travail et lance creation environnement
	distName
	createEnv

}


function distName {
	choix=`zenity --width=350 --height=80 --title "Nom du projet" --text "Indiquez un nom pour votre projet

	Un dossier du meme nom avec tous les elements de votre live-cd sera ensuite cree
	et servira d'environnement de travail.
	" --entry `
	case $? in
		0)
		DIST="$(echo "$choix" | sed -e 's/ /_/g')"
		DISTDIR="${WORK}/distribs/$DIST" ;;
		1)
		exit 1 ;;
		*)
		exit 1 ;;
	esac
}


##########################################################
## check de l environnement de base : image pour le chroot, dossiers de base cdrom usb etc
function createEnv()
{
	if [ ! -e "${DISTDIR}" ]; then
		echo "Creation du dossier ${DISTDIR}"
		mkdir "${DISTDIR}"

		## creer fichier conf de chaque distrib
		touch "${DISTDIR}"/config
		echo "[$DIST]
		distSession=$ISOTYPE
		Kernel=`uname -r`
		debootstrap=false" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' | tee -a "${DISTDIR}"/config &>/dev/null
		echo -e "creation du dossier de configuration... ok\n"
		chown "$USER" "${DISTDIR}"/config &>/dev/null
	fi

	cd "${DISTDIR}"

	## creation des dossiers de base
	echo "Creation/verification des dossiers de base pour $DIST"
	dirlist="usb old cdrom chroot temp save logs"
	for i in $dirlist ; do
		if [ ! -e "$i" ]; then
			echo  "cretion du dossier $i"
			mkdir "${DISTDIR}"/"$i" &>/dev/null
		fi
	done

	## dialog iso
	getCd

	## mount du cd de base
	echo -e "Tout est pret, mount du cdrom $ISONAME \n"
	sleep 3
	mount "$ISO" "${DISTDIR}"/old -o loop

	## copies dans dossier cdrom / nettoie
	SOURCE="${DISTDIR}/old"
	DESTINATION="${DISTDIR}/cdrom"
	TAILLE=$(($(du -sB 1 ${SOURCE} --exclude="filesystem.squashfs" | awk '{print $1}')/1000/1000))
	echo -e "Copie le contenu de base du fichier iso (sans le squashfs) dans le dossier cdrom, Taille: $TAILLE Mb \n"
	sleep 3
	rsync -aH --exclude="filesystem.squashfs" "${SOURCE}"/. "${DESTINATION}"/. &>/dev/null

	echo -e "Copie de la base du cdrom... ok \n"
	rm -rf "${DISTDIR}"/cdrom/programs
	chmod 755 -R "${DISTDIR}"/cdrom

	## si pas de copie direct demandee
	if [ -z "$DIRECT_COPY" ]; then

		## copie dans le chroot / demonte squashfs
		echo  -e "Copie du squashfs... \n"
		unsquashfs -i -d "${DISTDIR}"/chroot -f "${SOURCE}"/casper/filesystem.squashfs

		echo -e "Copie du squashfs terminÃ©e... ok \n"
		## demonte live-cd de base
		umount "${DISTDIR}"/old &>/dev/null
	fi

	SOURCE=""
	DESTINATION=""

	## copies le necessaire dans dossier usb
	echo -e "Prepare dossier usb...\n"
	sleep 3
	cp -R "${DISTDIR}"/cdrom/. "${DISTDIR}"/usb/.

	rm -Rf "${DISTDIR}"/usb/isolinux
	mv "${DISTDIR}"/usb/casper/initrd.* "${DISTDIR}"/usb/ &>/dev/null
	mv "${DISTDIR}"/usb/casper/vmlinuz "${DISTDIR}"/usb/

	if [ -z "$DIRECT_COPY" ]; then

		echo -e "La preparation de l'environnement pour la distrib $DIST est terminee,
		Les fichiers se trouvent dans :
		${DISTDIR} \n
		"
		sleep 5
	else
		echo -e "Preparation du dossier temporaire avant copie sur cle ok ! \n"
	fi

}


function getCd()
{
	## download le cd de base
	GETCD=$(zenity --width=500 --height=200 --title "Selection fichier image" --list --text "Choisissez votre option" --radiolist --column "Choix" --column "Action" --column "Description"  \
		TRUE "Select" "Indiquer ou se trouve le fichier iso" \
		FALSE "Download" "Telecharger l'iso de la distrib selectionnee" )
	case $GETCD in
		Select) SELECTED="`zenity --file-selection --filename=/home/$USER/ --title "Choisissez un fichier iso"`"
		case $? in
			0)
			echo
			echo -e "Fichier selectionne: "$SELECTED" \n"
			ISO="$SELECTED"
			ISONAME="`basename "$SELECTED"`"
			;;
			1) getCd
			;;
		esac
		;;## fin Selected
		Download)
		download="$ISOURL"
		## down du resultat
		echo  "Download du cd de base "$download""
		sleep 3
		cd "${WORK}"/isos
		test -e "$ISONAME" && rm "$ISONAME"
		testConnect
		wget -c -nd $download 2>&1 | sed -u 's/\([ 0-9]\+K\)[ \.]*\([0-9]\+%\) \(.*\)/\2\n#Transfert : \1 (\2) Ã  \3/' | zenity --progress  --auto-close  --width 400  --title="Telechargement de l'iso" --text="Telechargement de l'image "$ISONAME" en cours..."
		ISO=""${WORK}"/isos/"$ISONAME""
		## copie cd en sauvegarde si besoin

		;;## fin Download
		*) exit 1
		;;
	esac

	## verifie le md5sum
	echo -e "Verification du md5sum... \n"
	if [ $ISONAME == "natty-desktop-i386.iso" ]; then
		cd /tmp
		rm MD5SUMS &>/dev/null
		wget http://cdimage.ubuntu.com/daily-live/current/MD5SUMS &>/dev/null
		MD5SUM=$(cat MD5SUMS | grep i386.iso | awk '{print $1}')
	fi
	DOWNSUM="`md5sum "$ISO" | awk {'print $NR'} `"

	if [[ "$DOWNSUM" != "$MD5SUM" ]]; then
		zenity --error --text "Iso corrompu, le md5sum ne correspond pas !

		Md5sum original : $MD5SUM
		Votre iso : $DOWNSUM

		Continuez pour choisir ce que vous voulez faire :)
		"

		zenity --question --text "Choix de l'action a  effectuer

		Cliquez sur \"Valider\" pour continuer de force :

		Par exemple si vous utilisez un iso que vous avez
		cree precedemment ou tele©charge ailleur...
		Que vous avez deja  teste et que tout est fonctionnel.

		Si par contre, si vous venez de le telecharger l'iso par ce script
		alors cliquez \"annuler\" pour revenir au menu principal"

		case $? in
			0)
			echo -e "Ok, on continue avec votre fichier iso...\n"
			;;
			1)
			echo -e ""
			choose_action
			;;
		esac

	else
		echo -e "Md5sum original : $MD5SUM"
		echo -e "Md5sum fichier iso : $DOWNSUM  \n"
		echo -e "Votre fichier iso est valide, Md5sum ok ! \n"
	fi

}

## ptite fonction pour zenity a cause de dd pas de verbose...
function makeProgress() {
	until [[ ! `ps aux | grep -e "$1"` ]]; do
		echo "ok"
		sleep 1
	done
}

function testConnect()
{
	testconnexion=`wget www.google.fr -O /tmp/test &>/dev/null 2>&1`
	if [ $? != 0 ]; then
		sleep 5
		echo  "Pause, vous etes deconnecte !, en attente de reconnexion"
		testConnect
	fi
}


create_dist
