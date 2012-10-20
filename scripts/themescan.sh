#!/bin/bash
source /etc/ubukey/config

function chooser()
{
dir="$1"
dirHome="$2"
dirChroot="$3"

if [ -n "$4" ]; then
findtype="f"
else
findtype="d"
fi

cd /tmp
rm /tmp/zenity*
rm /tmp/list* &>/dev/null

scanLocal=$(find "$dir"/* -type $findtype -maxdepth 0 && find "$dirHome"/* -type $findtype -maxdepth 0) 
scanChroot=$(find "$dirChroot"/* -type $findtype -maxdepth 0) 

dir1=`echo "$scanLocal" | sed 's/.*\///g' | sort | tee -a /tmp/list`
dir2=`echo "$scanChroot" | sed 's/.*\///g' | sort | tee -a /tmp/list2`

diff=""
diff=$(sdiff -ls "/tmp/list" "/tmp/list2" | grep -e "<||\|" | sed '/none\|Default\|original\|desktop\|svg/d' | sed -e 's/>.*//' -e 's/<.*//' -e 's/|.*//' -e '/[a-z,A-Z,0-9]/!d')
if [ -z "$diff" ]; then	
	echo -e "Tous Les themes ($type) locaux sont déjà copiés... \n"
else

## on cree le menu zenity 
rm /tmp/zenitychoix
touch /tmp/finallist
rm /tmp/zenity &>/dev/null
echo -e "#!/bin/bash
zenity --list --checklist \\
--width 650 --height 500 \\
--title \"Choix des Addons\" \\
--column \"choix\" \\
--column \"thème\" \\
--text \"$message\" \\" | tee /tmp/zenity &>/dev/null
echo -e "FALSE \"Tout copier...\" \\" | tee -a /tmp/zenity &>/dev/null
echo -e "$diff" | sed -e '/*$/d' | sed 's/^/FALSE "/g' | sed 's/$/" \\/g' | sed '$s/\\//g'| tee -a /tmp/zenity &>/dev/null
chmod +x /tmp/zenity
/bin/bash /tmp/zenity >>/tmp/zenitychoix

## liste de resultat
list=`cat "/tmp/zenitychoix" | sed 's/|/\ \n/g'`

if [ -n "$list" ]; then
	## verifie si theme local est dans /usr/share ou /home/xxx/.themes .icons etc 
	touch /tmp/listDir
	## si tout copier utilisé
	if [[ "$list" = "Tout copier..." ]]; then
				list=`echo -e "$diff"` &>/dev/null
	fi
		echo -e "$list" | while read line ; do
			if [ -e "$dir"/"$line" ]; then
				echo -e "$dir/$line" | tee -a /tmp/listDir &>/dev/null
			else
				echo -e "$dirHome/$line" | tee -a /tmp/listDir &>/dev/null
			fi

		done
		## re liste de resultats
		toCopy=`cat /tmp/listDir | sed 's/|/\\n/g'`

## liste recuperee, on copie dans /usr/share/themes ou icons etc...
		if [ -n "$toCopy" ]; then
		echo -e "$toCopy" | while read line ; do
			cp -R "$line" "$DESTDIR" 
			echo -e "copie du thème $line terminée \n"
		done
		fi

fi ## fin a selectionne themes dans menu

fi

}

case $sessionType in 

gnome)

MENU=$(zenity --list --width 500 --height 525 \
--text "choisissez les operations à effectuer avant d'entrer dans le chroot

Pour les options de copie, une comparaison sera faite entre les elements presents 
en local et en chroot, seuls les themes ou images manquantes seront proposés ensuite.
" \
--checklist --column "" --column "Action" --column "Description" --hide-column 0 \
FALSE "Cloner" "
Cette option effectuera une copie complete de:
- Vos paquets installés (depuis les dépots)
- Vos dossiers de configuration, votre theme etc

Note: ce menu inclue l'option \"Language\" ci-dessous
" \
FALSE "Language" "Préparer le chroot avec votre langue actuelle par défaut 
(fr,en,be...)" \
FALSE "Themes" "Copier les thèmes locaux" \
FALSE "Icons" "Copier les thèmes d icones" \
FALSE "Wallpapers" "Copier les fonds d ecrans" \
FALSE "Fonts" "Copier les police locales" \
FALSE "Firefox" "(Re)Copier votre configuration firefox")

CHOICE=$(echo -e "$MENU" | sed 's/|/ /g')
for i in $CHOICE; do 
case $i in

Cloner)

############ localisation

if [[ ! $(grep "localise=true" "$DISTDIR"/config) ]]; then

rm "$DISTDIR"/chroot/tmp/chrootlog.log &>/dev/null
touch "$DISTDIR"/chroot/tmp/chrootlog.log &>/dev/null

(tail -f "$DISTDIR"/chroot/tmp/chrootlog.log &) 2>/dev/null

echo -e "Entre dans le chroot pour préparer votre système avec la langue \"$LOCALSIMPLE\""
chroot "$DISTDIR"/chroot << "EOF"
user=$(cat /etc/ubukey/ubukeyconf | grep -e "user" | sed 's/.*user=//')
## demarre script localisation
/bin/bash /usr/share/ubukey/scripts/localiser.sh | tee -a /tmp/chrootlog.log
EOF

echo "localise=true" | tee -a "$DISTDIR"/config &>/dev/null

else
echo -e "Localisation deja effectuée... \n"
fi

#######################################
# copie config gnome

## vide corbeille locale
if [ -e "$HOME/.local/share/Trash/files" ]; then
rm -rf "$HOME"/.local/share/Trash/files/*
fi

LISTE="$(find "$HOME" -maxdepth 1 -mindepth 1 -type d 2>/dev/null | grep -e "$home/\." | sed -e '/find/d;/.gvfs/d;/.thumbnails/d;/.cache/d;/.dbus/d;/.icons/d;/.themes/d;/.googleearth/d;/.wine/d;/.local/d;' | sort)"
i=1
echo -e "Calcul de l'espace nécessaire pour la copie...\n"
>/tmp/listsize
echo -e "$LISTE" | while read line; do
	fsize="`du -c $line | grep total | awk '{print $1}'`"
	i=$(( $i + $fsize ))
	echo $i >/tmp/listsize
done

fcountB="$(cat /tmp/listsize)"
if [ -n $fcountB ]; then
	fcountMB=$(( $fcountB / 1000 ))
else
	res=0
	echo -e "taille: $res MB"
fi

chspaceB=$(df "$DISTDIR"/chroot | grep /dev | awk '{print $4}')
chspaceMB=$(( $chspaceB / 1000 ))

echo -e "\nL'espace nécessaire pour la copie de vos fichiers de configuration
absents ou a mettre a jour est de :
${fcountMB}MB 

Vous disposez actuellement dans votre chroot de :
${chspaceMB}MB disponibles
"
sleep 5

if [ $chspaceB -lt $fcountB ]; then
	echo -e "Vous n'avez pas assez d'espace disponible ! \n
Faites le ménage sous chroot ou utilisez le menu de clonage de votre distribution \n
pour augmenter la taille de votre image ext3
"
sleep 5
else ## continue jusqu a fin clone

if [ $fcountB != 0 ]; then
echo -e "Démarre la copie/mise a jour des fichiers...\n"
sleep 1
	echo -e "$LISTE" | while read line; do
		rsync -au "$line" "${DISTDIR}"/chroot/etc/skel/
		echo -e "Mise à jour incrementale du dossier $line..."
	done
else
	echo -e "Tous les fichiers de conf sont à jour ! \n"
fi

## verifie que les elements du theme actif en local n etaient pas dans /usr/share (donc pas copiés)
## au lieu du .themes et .icons du /home/xxx local, idem pour wallpaper...
WALLPAPER="$(sudo -u $SUDO_USER gconftool-2 --get /desktop/gnome/background/picture_filename)"
fname="$(basename $WALLPAPER)"
THEME="$(sudo -u $SUDO_USER gconftool-2 --get /desktop/gnome/interface/gtk_theme)"
THEMEICON="$(sudo -u $SUDO_USER gconftool-2 --get /desktop/gnome/interface/icon_theme)"
THEMEMOUSE="$(sudo -u $SUDO_USER gconftool-2 --get /desktop/gnome/peripherals/mouse/cursor_theme)"

## copie wallpaper
echo -e "\nCopie du wallpaper actuel dans le chroot: $WALLPAPER"
cp -f "${WALLPAPER}" "${DISTDIR}"/chroot/usr/share/backgrounds

if [[ ! $(cat "${DISTDIR}"/chroot/etc/skel/.gnome2/backgrounds.xml | grep -e "$WALLPAPER") ]]; then

sed -i '/<\/wallpapers>/d' "${DISTDIR}"/chroot/etc/skel/.gnome2/backgrounds.xml
echo -e " <wallpaper deleted=\"false\">
   <name>$fname</name>
   <filename>/usr/share/backgrounds/$fname</filename>
   <options>stretched</options>
   <shade_type>solid</shade_type>
   <pcolor>#b6b687875a5a</pcolor>
   <scolor>#fdfddddd6e6e</scolor>
 </wallpaper>
</wallpapers>" | tee -a "${DISTDIR}"/chroot/etc/skel/.gnome2/backgrounds.xml &>/dev/null
else
## change/force config dans gnome avec lien /usr/share au cas ou
sed -i "s%<filename>.*$fname.*%<filename>/usr/share/backgrounds/$fname</filename>%" "${DISTDIR}"/chroot/etc/skel/.gnome2/backgrounds.xml
fi

## prepare pour gconf dans chroot
echo "$fname" > "${DISTDIR}"/chroot/tmp/wallLink
## change gconf dans chroot
chroot "$DISTDIR"/chroot &>/dev/null << "EOF"
wall="$(cat /tmp/wallLink)"
sed -i "s%.*$wall.*%<stringvalue>\/usr\/share\/backgrounds\/$wall</stringvalue>%" /etc/skel/.gconf/desktop/gnome/background/%gconf.xml
exit
EOF

## theme gtk
if [ ! -e "${DISTDIR}/chroot/usr/share/themes/${THEME}" ]; then
	echo -e "\nCopie du theme Gtk actuel dans le chroot: $THEME"
	if [ -e "$HOME/.themes/${THEME}" ]; then
		cp -R "$HOME/.themes/${THEME}" "${DISTDIR}"/chroot/usr/share/themes/ &>/dev/null
	else
		cp -R /usr/share/themes/"${THEME}" "${DISTDIR}"/chroot/usr/share/themes/ &>/dev/null
	fi
else
	echo -e "\nTheme GTK $THEME, deja installé dans le chroot...\n "
fi

## theme d icone
if [ ! -e "${DISTDIR}/chroot/usr/share/icons/${THEMEICON}" ]; then
	echo -e "Copie du theme d'icon actuel dans le chroot: $THEMEICON"
	if [ -e "$HOME/.icons/${THEMEICON}" ]; then
		cp -R "$HOME/.icons/${THEMEICON}" "${DISTDIR}"/chroot/usr/share/icons/
	else
		cp -R /usr/share/icons/"${THEMEICON}" "${DISTDIR}"/chroot/usr/share/icons/
	fi
else
	echo -e "Theme d'icones $THEMEICON, deja installé dans le chroot...\n "
fi

## theme de souris
if [ "$THEMEMOUSE" = "default" ];then
	echo -e "Theme de souris par defaut actif en local, rien a copier... \n"
elif [ ! -e "${DISTDIR}/chroot/usr/share/icons/${THEMEMOUSE}" ]; then
	echo -e "Copie du theme  de souris actuel dans le chroot: $THEMEMOUSE"
	if [ -e "$HOME/.icons/${THEMEMOUSE}" ]; then
		cp -R "$HOME/.icons/${THEMEMOUSE}" "${DISTDIR}"/chroot/usr/share/icons/
	else
		cp -R /usr/share/icons/"${THEMEMOUSE}" "${DISTDIR}"/chroot/usr/share/icons/
	fi
else
	echo -e "Theme de souris $THEMEMOUSE, deja installé dans le chroot...\n "
fi ##fin check elements theme actif

echo -e "\nCopie de vos dossiers de configuration terminée \n"
sleep 5

chroot "$DISTDIR"/chroot << "EOF"

function message()
{
touch /tmp/chrootlog.log
message="$1"
echo -e "$message"
}

## maj distro
## prepare sources et cle gpg...
message "Prépare le dossier apt avec votre sources.list, cle et liste de paquets à copier \n"
## alors on deplace le sources.list du script 
rm /var/cache/apt/pkgcache.bin
rm /var/cache/apt/srcpkgcache.bin
mv /etc/apt/sources.list /etc/apt/sources.list.script
mv /etc/apt/trusted.gpg /etc/apt/trusted.gpg.script
## et copie le sources.list etc injectes precedement
cp -R -f /etc/ubukey/sources/. /etc/apt/.

## met a jour avec le nouveau sources.list etc
message "Copie ok, mise a jour des sources...\n "
apt-get update | tee -a /tmp/chrootlog.log

exit
EOF
killall -9 tail

## liste des paquets dans le chroot
chroot "$DISTDIR"/chroot << "EOF"
dpkg -l |grep ^rc |awk '{print $2}' | xargs dpkg -P &>/dev/null 
dpkg-query -W --showformat='${Package}\n' | sed '/^$/d' | sort > /tmp/chrootlist
exit
EOF

## liste paquets en local
dpkg -l |grep ^rc |awk '{print $2}' |xargs dpkg -P &>/dev/null 
dpkg-query -W --showformat='${Package}\n' | sed '/^$/d' | sort > /tmp/locallist

## liste des paquets non installés dans chroot par comparaison (et vire fglrx/nvidia...)
ORIGLIST="$(diff -y /tmp/locallist ${DISTDIR}/chroot/tmp/chrootlist | grep "<" | awk '{print $1}' | sed 's/nvidia.*//;s/xorg-driver-fglrx.*//;s/fglrx.*//;/.*-dev/d;/adobe/d;/.wine/d' | sed '/^$/d')"

echo "$ORIGLIST" | tee "$DISTDIR"/chroot/tmp/pkglist &>/dev/null
chroot "$DISTDIR"/chroot << "EOF"

function message()
{
touch /tmp/chrootlog.log
message="$1"
echo -e "$message" | tee -a /tmp/chrootlog.log &>/dev/null
}

ORIGLIST="$(cat /tmp/pkglist)"
>/tmp/uninstlist

message "\nExtraction de la liste des paquets disponibles pour installation \n"
sleep 1
apt-cache dumpavail | grep Package: | sed 's/.*: //' >/tmp/available

message "detection des paquets non installables depuis les depots"
echo "$ORIGLIST" | while read line; do 
if [[ ! $(cat /tmp/available | grep -w "^$line$") ]]; then
sed -i "/$line/d" /tmp/pkglist
echo $line | tee -a /tmp/uninstlist &>/dev/null
fi
done
exit
EOF
killall -9 tail

## liste des paquets non presents dans le chroot
DIFFLIST="$(cat $DISTDIR/chroot/tmp/pkglist | sed '/^$/d')"
## liste des paquets impossibles a installer depuis le depots
UNINLIST="$(cat $DISTDIR/chroot/tmp/uninstlist | sed '/^$/d')"

if [ -n "$UNINLIST" ]; then
		echo -e "\nLes paquets qui vont etre affiches ne sont pas installables depuis les depots actuels Vous avez du les installer depuis un site ou autre... a vous de le reinstaller dans le chroot : \n"
sleep  5
echo "$UNINLIST" | xargs | tee -a "$DISTDIR"/save/failed_pkglist.txt
fi

echo -e "\nLa liste des ces fichiers est sauvegardée dans:
$DISTDIR/save/failed_pkglist.txt
"

sleep 5

#############################
if [ -z "$DIFFLIST" ]; then
	echo -e "\nTous les paquets installables depuis les depots sont presents dans le chroot... Ok \n"
else
## et au final la taille des paquets non installés donc ajout pure...(update prennent quasi rien)
SIZELIST="$(dpkg-query -W --showformat='${Installed-Size}\n' $DIFFLIST | sed '/^$/d' )"

i=0
echo -e "$SIZELIST" | while read line; do
	pkgsize="$line"
	i=$(( $i + $pkgsize ))
	echo $i > /tmp/count
done
res=$(( `cat /tmp/count` / 1000 ))
needed_space=$(( $res + 256 ))
chspace=$(($(df "$DISTDIR"/chroot | grep /dev | awk '{print $4}') / 1000 ))

if [ $needed_space = 256 ]; then
echo -e "\nAucun nouveau paquet n'est à installer, seules les mises a jour seront verifiées \n" 
else
echo -e "\nL'espace nécessaire pour l'installation des paquets manquants 
(uniquement) dans le chroot, plus une petite marge (256Mo) 
pour les mises a jour et garder un peu de place, est de :
${needed_space}MB

Vous disposez actuellement dans votre chroot de :
${chspace}MB disponibles

"
fi

################ demarre install/maj des paquets dans chroot ###########

if [ "$chspace" -lt "$needed_space" ]; then
	echo -e "Vous n'avez pas assez d'espace disponible ! \n
Faites le ménage sous chroot ou utilisez le menu de clonage de votre distribution\n
pour augmenter la taille de votre image ext3
"
else
	echo -e "Tout est Ok, Démarre l installation des paquets ! \n"
	sleep 5
	
	## check java
	JAVALIST="$(cat $DISTDIR/chroot/tmp/pkglist | grep sun-java | xargs)"
	if [ -n "$JAVALIST" ]; then
		chroot "$DISTDIR"/chroot apt-get -y --force-yes install $JAVALIST
	fi	

	## injecte liste des paquets non installés dans chroot
	echo -e "Entre dans le chroot \n"
	
chroot "$DISTDIR"/chroot << "EOF"
mount -t proc proc /proc
mount -t sysfs sys /sys
mount -t devpts none /dev/pts
#/etc/init.d/dbus restart
## maj globale
exit
EOF

echo -e  "\nMise a jour complete des paquets pour commencer...\n"
sleep 2
chroot "$DISTDIR"/chroot apt-get clean ## nettoyage...
chroot "$DISTDIR"/chroot apt-get -y --force-yes dist-upgrade
## maj des paquets
echo -e "\nInstallation des paquets manquants dans le chroot...\n"
sleep 2
chroot "$DISTDIR"/chroot apt-get -y --force-yes install `cat "$DISTDIR"/chroot/tmp/pkglist | xargs`
## clean
chroot "$DISTDIR"/chroot apt-get clean

echo -e "Remet les sources a leur etat original...\n"
sleep 3

chroot "$DISTDIR"/chroot &>/dev/null << "EOF"
## remet en place sources.list original
mv /etc/apt/sources.list.script /etc/apt/sources.list
mv /etc/apt/trusted.gpg.script /etc/apt/trusted.gpg

rm /var/cache/apt/pkgcache.bin
rm /var/cache/apt/srcpkgcache.bin

apt-get update &>/dev/null

umount /proc
umount/sys
umount /dev/pts
exit
EOF

echo -e "Opérations terminées"

fi ## fin check taille

fi ## fin check difflist vide

fi ## fin check taille copie config
;;

Language)

echo -e "Entre dans le chroot pour préparer votre système avec la langue \"$LOCALSIMPLE\""
chroot "$DISTDIR"/chroot << "EOF"
user=$(cat /etc/ubukey/ubukeyconf | grep -e "user" | sed 's/.*user=//')
## demarre script localisation
if [ ! -e "/usr/bin/locate" ]; then
apt-get -y install locate
fi
/bin/bash /usr/share/ubukey/scripts/localiser.sh | tee -a /tmp/chrootlog.log
EOF
;;

Firefox)
## copies divers elements sur demande
echo -e "Mise a jour de firefox si nécessaire \n"
aptitude -y install firefox &>/dev/null
echo -e "Copie de votre configuration firefox locale (bookmarks, plugins...) \n"
cfgdir=$(cat /home/"$USER"/.mozilla/firefox/profiles.ini | grep "Path=" | sed 's/.*=//')

cp -R -f /home/"$USER"/.mozilla "${DISTDIR}"/chroot/etc/skel/
#~ rm "${DISTDIR}"/chroot/etc/skel/.mozilla/firefox/${cfgdir}/places.sqlite
chmod 755 -R "${DISTDIR}"/chroot/etc/skel/.mozilla

## verifie une cle du about:config creant un bug sur les bookmarks sous intrepid...
sed -i 's%user_pref("browser.places.importBookmarksHTML", true);%user_pref("browser.places.importBookmarksHTML", false);%' "${DISTDIR}"/chroot/etc/skel/.mozilla/firefox/${cfgdir}/prefs.js
rm "${DISTDIR}"/chroot/etc/skel/.mozilla/firefox/${cfgdir}/places.sqlite
;;

Themes)
## choix des icons
type="themes"
message="Les thèmes suivant ne sont pas présents dans le chroot

Choisissez les thèmes à copier, ou annulez...
"
DESTDIR="$DISTDIR/chroot/usr/share/themes"
(chooser /usr/share/themes /home/"$USER"/.themes "$DISTDIR"/chroot/usr/share/themes) 2>/dev/null
;;

Icons)
## choix des themes
type="icons"
message="Les thèmes d'icônes suivant ne sont pas présents dans le chroot

Choisissez les thèmes d'icônes à copier, ou annulez...
"
DESTDIR="$DISTDIR/chroot/usr/share/icons"
(chooser /usr/share/icons /home/"$USER"/.icons "$DISTDIR"/chroot/usr/share/icons ) 2>/dev/null

;;

Fonts)
## choix des fonts
type="fonts"
message="Les Polices suivantes ne sont pas présentes dans le chroot

Choisissez celles que vous voulez copier, ou annulez...
"
DESTDIR="$DISTDIR/chroot/usr/share/fonts"
(chooser /usr/share/fonts /home/"$USER"/.fonts "$DISTDIR"/chroot/usr/share/fonts) 2>/dev/null
;;


Wallpapers)
## choix wallpapers
type="Wallpapers"
message="Les Fonds d'ecrans suivants ne sont pas présents dans le chroot

Choisissez ceux que vous voulez copier, ou annulez...
"
wallLocal=$(cat /home/"$USER"/.gnome2/backgrounds.xml | grep "<filename>" | sed '/none/d' | sed 's/<\/filename>//g' | sed 's/<filename>//g' | sed -e "s/^ *//g")

echo -e "$wallLocal" | while read lines; do
name=$(echo -e "$lines" | sed 's/.*\///')
if [ ! -e /usr/share/backgrounds/"$name" ]; then
cp "$lines" /usr/share/backgrounds
fi 
done

DESTDIR="$DISTDIR/chroot/usr/share/backgrounds"
mkdir /home/"$USER"/.temp
(chooser /usr/share/backgrounds /home/"$USER"/.temp "$DISTDIR"/chroot/usr/share/backgrounds file) 2>/dev/null
rm -R /home/"$USER"/.temp
;;

esac

done


;; ############################################### fin gnome #############################################################

kde4)

MENU=$(zenity --list --width 500 --height 550 \
--text "choisissez les operations à effectuer avant d'entrer dans le chroot

Une comparaison sera faite entre les elements presents en local et en chroot
seuls les themes ou images manquantes seront proposés ensuite.

Le menu localiser est conseillé la première fois" \
--checklist --column "" --column "Action" --column "Description" --hide-column 0 \
FALSE "Language" "Préparer le chroot avec votre langue actuelle par défaut 
(fr,en,be...)" \
FALSE "Themes" "Copier les thèmes locaux" \
FALSE "Icons" "Copier les thèmes d'icones" \
FALSE "Wallpapers" "Copier les fonds d'ecrans" \
FALSE "Fonts" "Copier les police locales" \
FALSE "Ksplash" "Copier vos images Ksplash" \
FALSE "Kdm" "Copier vos thèmes kdm" \
FALSE "Konqueror" "(Re)Copier votre configuration Konqueror" \
FALSE "Kicker" "Copier vos images de fond du kicker" \
FALSE "Firefox" "(Re)Copier votre configuration firefox")

CHOICE=$(echo -e "$MENU" | sed 's/|/ /g')

for i in $CHOICE; do 
case $i in

Language)
rm "$DISTDIR"/chroot/tmp/chrootlog.log &>/dev/null
touch "$DISTDIR"/chroot/tmp/chrootlog.log &>/dev/null

(tail -f "$DISTDIR"/chroot/tmp/chrootlog.log &) 2>/dev/null

echo -e "Entre dans le chroot pour préparer votre système avec la langue \"$LOCALSIMPLE\""
chroot "$DISTDIR"/chroot << "EOF"

## mise a jour forcee du script
/bin/bash /usr/share/ubukey/scripts/localiser-kde.sh | tee -a /tmp/chrootlog.log
EOF

;;

Themes)
## choix des themes
type="themes"
message="Les thèmes suivant ne sont pas présents dans le chroot

Choisissez les thèmes à copier, ou annulez...
"
DESTDIR="$DISTDIR/chroot/usr/lib/kde4/share/kde4/apps/kthememanager/themes"
(chooser /usr/lib/kde4/share/kde4/apps/kthememanager/themes /home/"$USER"/.kde4/share/apps/kthememanager/themes "$DISTDIR"/chroot/usr/lib/kde4/share/kde4/apps/kthememanager/themes) 2>/dev/null
;;

Icons)
## choix des icones
type="icons"
message="Les thèmes d'icônes suivant ne sont pas présents dans le chroot

Choisissez les thèmes d'icônes à copier, ou annulez...
"
DESTDIR="$DISTDIR/chroot/usr/share/icons"
(chooser /usr/lib/kde4/share/icons /home/"$USER"/.kde4/share/icons "$DISTDIR"/chroot/usr/lib/kde4/share/icons) 2>/dev/null
;;

Ksplash)
## choix splash
type="splash"
message="Les thèmes Ksplash kde suivant ne sont pas présents dans le chroot

Choisissez les thèmes à copier, ou annulez...
"
DESTDIR="$DISTDIR/chroot/usr/lib/kde4/share/kde4/apps/ksplash/Themes"

## check si ksplash est la...
if [ ! -e "$DISTDIR"/chroot/usr/bin/ksplash ]; then
echo -e "Installation de ksplash dans le chroot (manquant...)\n"
chroot "$DISTDIR"/chroot &>/dev/null  << "EOF"
apt-get -y install ksplash
EOF
fi

## et continue sur les themes
(chooser /usr/lib/kde4/share/kde4/apps/ksplash/Themes /home/"$USER"/.kde4/share/apps/ksplash/Themes "$DISTDIR"/chroot/usr/lib/kde4/share/kde4/apps/ksplash/Themes) 2>/dev/null
cp /home/"$USER"/.kde4/share/config/ksplashrc "$DISTDIR"/chroot/etc/skel/.kde4/share/config/ &>/dev/null
;;


Fonts)
## choix des fonts
type="fonts"
message="Les Polices suivantes ne sont pas présentes dans le chroot

Choisissez celles que vous voulez copier, ou annulez...
"
DESTDIR="$DISTDIR/chroot/usr/share/fonts"
(chooser /usr/share/fonts /home/"$USER"/.fonts "$DISTDIR"/chroot/usr/share/fonts) 2>/dev/null
;;

Kdm)
## choix des fonts
type="Kdm"
message="Les Thèmes kdm suivants ne sont pas présents dans le chroot

Choisissez ceux que vous voulez copier, ou annulez...
"
DESTDIR="$DISTDIR/chroot/usr/share/apps/kdm/themes"
mkdir /home/"$USER"/.temp
(chooser /usr/lib/kde4/share/kde4/apps/kdm/themes/ /home/"$USER"/.temp "$DISTDIR"/chroot/usr/lib/kde4/share/kde4/apps/kdm/themes/) 2>/dev/null
rm -R /home/"$USER"/.temp
;;

Konqueror)
## config konqueror
	cp -R /home/"$USER"/.kde4/share/config/konquerorrc "$DISTDIR"/chroot/etc/skel/.kde4/share/config/ &>/dev/null
	cp -R /home/"$USER"/.kde4/share/apps/konqueror/{bookmarks.xml,faviconrc} "$DISTDIR"/chroot/etc/skel/.kde4/share/apps/konqueror/ &>/dev/null
	echo -e "Copie des bookmarks et config konqueror ok... \n"
;;

Kicker)
## config kicker
	cp /home/"$USER"/.kde4/share/config/kickoffrc "$DISTDIR"/chroot/etc/skel/.kde4/share/config/ &>/dev/null
	cp /home/"$USER"/.kde4/share/apps/kicker/wallpapers/* "$DISTDIR"/chroot/etc/skel/.kde4/share/apps/kicker/ &>/dev/null
	echo -e "Copie des images de fond et config kicker ok... \n"
;;

Wallpapers)
## choix des wallpapers
type="Wallpapers"
message="Les Fonds d'ecrans suivants ne sont pas présents dans le chroot

Choisissez ceux que vous voulez copier, ou annulez...
"
wallList=$(cat /home/"$USER"/.kde4/share/config/kdesktoprc | grep -e "Recent Files\[\$e\]=" | sed -e 's/.*=//' -e 's/,/ /g' -e 's/$HOME/\/home\/'$USER'/g')
echo -e $wallList | while read lines; do
name=$(echo -e "$lines" | sed 's/.*\///')
if [ ! -e /usr/lib/kde4/share/wallpapers/"$name" ]; then
cp "$lines" /usr/lib/kde4/share/wallpapers/
sed -i 's/'"$name"',//' /home/"$USER"/.kde4/share/config/kdesktoprc
fi 
done

DESTDIR="$DISTDIR/chroot/usr/lib/kde4/share/wallpapers/"
mkdir /home/"$USER"/.temp
(chooser /usr/lib/kde4/share/wallpapers /home/"$USER"/.kde4/share/wallpapers "$DISTDIR"/chroot/usr/lib/kde4/share/wallpapers file) 2>/dev/null
rm -R /home/"$USER"/.temp
;;


Firefox)
## copies divers elements sur demande
cp -R /home/"$USER"/.mozilla "$DISTDIR/chroot/etc/skel/"
;;

esac ## fin loop menu

done

;;################################################ fin kde4  #############################################################

kde3)

MENU=$(zenity --list --width 500 --height 550 \
--text "choisissez les operations à effectuer avant d'entrer dans le chroot

Une comparaison sera faite entre les elements presents en local et en chroot
seuls les themes ou images manquantes seront proposés ensuite.

Le menu localiser est conseillé la première fois" \
--checklist --column "" --column "Action" --column "Description" --hide-column 0 \
FALSE "Language" "Préparer le chroot avec votre langue actuelle par défaut 
(fr,en,be...)" \
FALSE "Themes" "Copier les thèmes locaux" \
FALSE "Icons" "Copier les thèmes d'icones" \
FALSE "Wallpapers" "Copier les fonds d'ecrans" \
FALSE "Fonts" "Copier les police locales" \
FALSE "Ksplash" "Copier vos images Ksplash" \
FALSE "Kdm" "Copier vos thèmes kdm" \
FALSE "Konqueror" "(Re)Copier votre configuration Konqueror" \
FALSE "Kicker" "Copier vos images de fond du kicker" \
FALSE "Firefox" "(Re)Copier votre configuration firefox")

CHOICE=$(echo -e "$MENU" | sed 's/|/ /g')

for i in $CHOICE; do 
case $i in

Language)

rm "$DISTDIR"/chroot/tmp/chrootlog.log &>/dev/null
touch "$DISTDIR"/chroot/tmp/chrootlog.log &>/dev/null

(tail -f "$DISTDIR"/chroot/tmp/chrootlog.log &) 2>/dev/null

echo -e "Entre dans le chroot pour préparer votre système avec la langue \"$LOCALSIMPLE\""
chroot "$DISTDIR"/chroot << "EOF"

## demarre script localisation
/bin/bash /usr/share/ubukey/scripts/localiser-kde.sh | tee -a /tmp/chrootlog.log
EOF

;;

Themes)
## choix des themes
type="themes"
message="Les thèmes suivant ne sont pas présents dans le chroot

Choisissez les thèmes à copier, ou annulez...
"
DESTDIR="$DISTDIR/chroot/usr/share/apps/kthememanager/themes"
(chooser /usr/share/apps/kthememanager/themes /home/"$USER"/.kde/share/apps/kthememanager/themes "$DISTDIR"/chroot/usr/share/apps/kthememanager/themes) 2>/dev/null
;;

Icons)
## choix des icones
type="icons"
message="Les thèmes d'icônes suivant ne sont pas présents dans le chroot

Choisissez les thèmes d'icônes à copier, ou annulez...
"
DESTDIR="$DISTDIR/chroot/usr/share/icons"
(chooser /usr/share/icons /home/"$USER"/.kde/share/icons "$DISTDIR"/chroot/usr/share/icons) 2>/dev/null
;;

Ksplash)
## choix splash
type="splash"
message="Les thèmes Ksplash kde suivant ne sont pas présents dans le chroot

Choisissez les thèmes à copier, ou annulez...
"
DESTDIR="$DISTDIR/chroot/usr/share/apps/ksplash/Themes"

## check si ksplash est la...
if [ ! -e "$DISTDIR"/chroot/usr/bin/ksplash ]; then
echo -e "Installation de ksplash dans le chroot (manquant...)\n"
chroot "$DISTDIR"/chroot &>/dev/null  << "EOF"
apt-get -y install ksplash
EOF
fi

## et continue sur les themes
(chooser /usr/share/apps/ksplash/Themes /home/"$USER"/.kde/share/apps/ksplash/Themes "$DISTDIR"/chroot/usr/share/apps/ksplash/Themes) 2>/dev/null
cp /home/"$USER"/.kde/share/config/ksplashrc "$DISTDIR"/chroot/etc/skel/.kde/share/config/ &>/dev/null
;;


Fonts)
## choix des fonts
type="fonts"
message="Les Polices suivantes ne sont pas présentes dans le chroot

Choisissez celles que vous voulez copier, ou annulez...
"
DESTDIR="$DISTDIR/chroot/usr/share/fonts"
(chooser /usr/share/fonts /home/"$USER"/.fonts "$DISTDIR"/chroot/usr/share/fonts) 2>/dev/null
;;

Kdm)
## choix des fonts
type="Kdm"
message="Les Thèmes kdm suivants ne sont pas présents dans le chroot

Choisissez ceux que vous voulez copier, ou annulez...
"
DESTDIR="$DISTDIR/chroot/usr/share/apps/kdm/themes"
mkdir /home/"$USER"/.temp
(chooser /usr/share/apps/kdm/themes /home/"$USER"/.temp "$DISTDIR"/chroot/usr/share/apps/kdm/themes) 2>/dev/null
rm -R /home/"$USER"/.temp
;;

Konqueror)
## config konqueror
	cp -R /home/"$USER"/.kde/share/config/konquerorrc "$DISTDIR"/chroot/etc/skel/.kde/share/config/ &>/dev/null
	cp -R /home/"$USER"/.kde/share/apps/konqueror/{bookmarks.xml,faviconrc} "$DISTDIR"/chroot/etc/skel/.kde/share/apps/konqueror/ &>/dev/null
	echo -e "Copie des bookmarks et config konqueror ok... \n"
;;

Kicker)
## config kicker
	cp /home/"$USER"/.kde/share/config/kickerrc "$DISTDIR"/chroot/etc/skel/.kde/share/config/ &>/dev/null
	cp /home/"$USER"/.kde/share/apps/kicker/wallpapers/* "$DISTDIR"/chroot/etc/skel/.kde/share/apps/kicker/ &>/dev/null
	echo -e "Copie des images de fond et config kicker ok... \n"
;;

Wallpapers)
## choix des wallpapers
type="Wallpapers"
message="Les Fonds d'ecrans suivants ne sont pas présents dans le chroot

Choisissez ceux que vous voulez copier, ou annulez...
"
wallList=$(cat /home/"$USER"/.kde/share/config/kdesktoprc | grep -e "Recent Files\[\$e\]=" | sed -e 's/.*=//' -e 's/,/ /g' -e 's/$HOME/\/home\/'$USER'/g')
echo -e $wallList | while read lines; do
name=$(echo -e "$lines" | sed 's/.*\///')
if [ ! -e /usr/share/wallpapers/"$name" ]; then
cp "$lines" /usr/share/wallpapers
sed -i 's/'"$name"',//' /home/"$USER"/.kde/share/config/kdesktoprc
fi 
done

DESTDIR="$DISTDIR/chroot/usr/share/wallpapers"
mkdir /home/"$USER"/.temp
(chooser /usr/share/wallpapers /home/"$USER"/.temp "$DISTDIR"/chroot/usr/share/wallpapers file) 2>/dev/null
rm -R /home/"$USER"/.temp
;;

Firefox)
## copies divers elements sur demande
cp -R /home/"$USER"/.mozilla "$DISTDIR/chroot/etc/skel/"
;;

esac ## fin loop menu

done

;;###############################################  fin kde3  ##############################################################
xfce4)
;;###############################################  fin xfce4 ##############################################################

esac 


## TODO trouver equivalence de
#/usr/share/gnome-background-properties/ubuntu-wallpapers.xml

