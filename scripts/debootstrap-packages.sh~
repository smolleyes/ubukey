source /etc/ubukey/config

rm /tmp/pack &>/dev/null

function install_packages()
{
session=$1
echo -e "Installation des paquets pour $session \n"

chroot "$DISTDIR"/chroot apt-get -y --force-yes install dialog

lang=$(env | grep -w "LANG" | sed -e 's/\..*//;s/LANG=//;s/_.*//')
. $UBUKEYDIR/deboot-modules/$session

if [ $session = "cinnamon" ]; then
	chroot "$DISTDIR"/chroot apt-get -y --force-yes install python-software-properties
	chroot "$DISTDIR"/chroot apt-add-repository -y ppa:gwendal-lebihan-dev/cinnamon-stable
	chroot "$DISTDIR"/chroot apt-add-repository -y ppa:bimsebasse/cinnamonextras
	chroot "$DISTDIR"/chroot apt-get update
fi 

packageList="$(echo "$packages" | sed -e '/^#/d;s/\"//g' | xargs)"
echo "checking packages availability..."
for p in $packageList ;do 
	if [[ `chroot "$DISTDIR"/chroot apt-cache search $p | grep $p` ]]; then 
		echo "package $p installable"
		echo "$p" | tee -a /tmp/pack &>/dev/null
	else 
		echo "The package $p is not available for installation..."
	fi
done

sudo chroot "$DISTDIR"/chroot apt-get -y --force-yes install --no-install-recommends `cat /tmp/pack | xargs`

## extra-packages (install with recommends)
if [ $session = "gnome" ]; then
	chroot "$DISTDIR"/chroot apt-get -y --force-yes install indicator-session gnome-media alacarte network-manager gvfs-backends gvfs-bin gvfs-fuse
	chroot "$DISTDIR"/chroot apt-get remove -y gwibber ubuntuone*
fi 
##

if [ "$session" != "" ]; then
	sed -i "s/distSession=.*/distSession=$session/" "$DISTDIR"/config
fi
if [[ "$session" = "gnome-shell" || "$session" = "cinnamon" ]]; then
	sed -i "s/distSession=.*/distSession=gnome/" "$DISTDIR"/config
fi
}

## menu choix packages
ACTION=`zenity --width 500 --height 400 --title "selecteur de modules" --list --text "Sélectionner les modules à installer

note: 
Ces modules installent le minimum possible pour chaque session
avec le serveur x, un kernel et quelques paquets essentiels...(lubuntu = lxde)
" --radiolist --column "Choix" --column "Action"  \
TRUE "gnome" \
FALSE "kde4" \
FALSE "xfce4" \
FALSE "lxde" \
FALSE "gnome-shell" \
FALSE "cinnamon"`

case $ACTION in
	gnome)
	install_packages gnome | tee /tmp/debootlog
	;;
	kde4)
	install_packages kde4 | tee /tmp/debootlog
	;;
	lxde)
	install_packages lxde | tee /tmp/debootlog
	;;
	xfce4)
	install_packages xfce4 | tee /tmp/debootlog
	;;
	gnome-shell)
	install_packages gnome-shell | tee /tmp/debootlog
	;;
	cinnamon)
	install_packages cinnamon | tee /tmp/debootlog
	;;
	*)
	exit 0
	;;
esac

zenity --question \
--title "Paquets supplémentaires" \
--text "Voulez vous installer des paquets supplémentaires (RECOMMANDE) ?" 
if [ "$?" != 1 ]; then
    . $UBUKEYDIR/scripts/debootstrap_packages_chooser.sh
fi

