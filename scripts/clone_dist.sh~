#!/bin/bash

DIST="$1"
DISTDIR="$2"
WORK="$3"
old_dist="$DIST"
old_distdir="$DISTDIR"

source /etc/ubukey/config


function distName {
	choix=`zenity --width=350 --height=80 --title "Nom du projet" --text "Indiquez un nom pour votre projet 

	Un dossier du meme nom avec tous les éléments de votre live-cd sera ensuite crée
	et servira d'environnement de travail.
	" --entry `
	case $? in
		0)
		DIST="$(echo "$choix" | sed -e 's/ /_/g')"
		DISTDIR="${WORK}/distribs/$DIST"
		checkSize
		## copie...
		mkdir "${DISTDIR}"
		echo -e "Creation de $DIST, clone de $old_dist en cours...\n"
		rsync -a --stats --progress --filter "- *.iso" --filter "- *.squashfs" "$old_distdir"/. "${DISTDIR}"/. &>/dev/null
		sed -i 's%'$old_dist'%'$DIST'%' "${DISTDIR}"/config
		echo -e "Clonage terminé \n"
		
		;;
		1)
		exit 1 ;; 
		*)
		exit 1 ;;
	esac
}

function checkSize()
{
	echo -e "Calcule la taille du dossier $old_distdir ... \n"
	osize=`du -B MB "$old_distdir" --exclude "*.squashfs,*.iso" | awk '{print $1}' | xargs`
	fcountMB=`echo "$osize" | awk '{print $NF}' | sed -e 's/MB//'`

	if [ -z "$fcountMB" ]; then
		echo -e "Impossible de calculer la taille du dossier $old_distdir \n"
		exit 0
	fi

	chspaceMB=$(df -B MB `dirname "$DISTDIR"` | grep /dev | awk '{print $4}' | sed 's/MB//')

	echo -e "\nL'espace nécessaire pour cloner votre distribution est de:
	${fcountMB}MB 

	L'epace libre sur le disque de destination est de :
	${chspaceMB}MB
	"

	if [ $chspaceMB -lt $fcountMB ]; then
		echo -e "Vous n'avez pas assez d'espace disponible ! \n"
		exit 0
	else ## continue jusqu a fin clone
		echo -e "Démarre le clonage de $old_distdir vers $DISTDIR ...\n"
	fi

}


## demande nouveau nom de projet
distName
