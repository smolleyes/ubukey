#!/bin/bash
############################################### 
source /etc/ubukey/config

cp -f $UBUKEYDIR/scripts/ubusrc-gen /usr/local/bin
chmod +x /usr/local/bin/ubusrc-gen
bash ubusrc-gen
if [[ ! `dpkg -l | grep aptitude` ]]; then
sudo apt-get -y --force-yes install aptitude
fi

LOCALUTF="$(cat /etc/ubukey/ubukeyconf | grep -e "localutf" | sed 's/.*=//')"
LOCALBASE="$(cat /etc/ubukey/ubukeyconf | grep -e "localbase" | sed 's/.*=//')"
LOCALSIMPLE="$(cat /etc/ubukey/ubukeyconf | grep -e "localsimple" | sed 's/.*=//')"
user="$(cat /etc/ubukey/ubukeyconf | grep -e "user" | sed 's/.*user=//')"
sessionType="$(cat /etc/ubukey/ubukeyconf | grep -e "distSession" | sed 's/.*=//')"

#desinstalle tous les paquets langues et locales
todel=$(dpkg -l | awk '{print $2}' | egrep "language-pack|aspell-|gimp-help-|language-support-|myspell-|openoffice.org-help-|openoffice.org-l10n-|language-pack-gnome-|gimp-help-" | xargs)
sudo aptitude -y purge $todel

#################### 
#installe paquets fr
echo -e "(Re)installation des  paquets language-pack-kde-$LOCALSIMPLE language-pack-kde-$LOCALSIMPLE-base aspell-$LOCALSIMPLE gimp-help-$LOCALSIMPLE ifrench-gut language-support-$LOCALSIMPLE language-support-translations-$LOCALSIMPLE language-support-writing-$LOCALSIMPLE myspell-$LOCALSIMPLE-gut openoffice.org-help-$LOCALSIMPLE openoffice.org-l10n-$LOCALSIMPLE thunderbird-locale-$LOCALSIMPLE kde-l10n-$LOCALSIMPLE language-pack-$LOCALSIMPLE wfrench \n"
apt-get -y --force-yes install language-pack-kde-$LOCALSIMPLE language-pack-kde-$LOCALSIMPLE-base aspell-$LOCALSIMPLE ifrench-gut language-support-$LOCALSIMPLE language-support-translations-$LOCALSIMPLE language-support-writing-$LOCALSIMPLE openoffice.org-help-$LOCALSIMPLE openoffice.org-l10n-$LOCALSIMPLE thunderbird-locale-$LOCALSIMPLE kde-l10n-$LOCALSIMPLE language-pack-$LOCALSIMPLE wfrench

############ 
# localepurge
rm /etc/locale.gen &>/dev/null
echo -e "$LOCALSIMPLE
$LOCALBASE
$LOCALUTF" | tee /etc/locale.gen &>/dev/null

## check langue dans .kde4

## edite fichier de conf kde3/4
if [ "$sessionType" = "kde4" ]; then
echo -e "Configuration pour kde4 \n"
if [[ ! $(cat /etc/skel/.kde/share/config/kdeglobals | grep -e "Language=") ]];then
echo -e '
[Locale]
Country='"$LOCALSIMPLE"'
Language='"$LOCALSIMPLE"':
' | tee -a /etc/skel/.kde/share/config/kdeglobals

elif [[ ! $(cat /etc/skel/.kde/share/config/kdeglobals | grep -e "LANG=") ]];then
echo -e "Edite le .profile avec la locale : $LOCALUTF \n"
echo -e 'export LANG='"$LOCALUTF"'
export LC_ALL='"$LOCALUTF"'
export LANGUAGE='"$LOCALSIMPLE"'
' | tee -a /etc/skel/.profile
fi

else
## si kde3
echo -e "Edite langue par defaut kde3 : $LOCALSIMPLE \n"
sed -i 's/Country=.*/Country='$LOCALSIMPLE'/' /etc/skel/.kde/share/config/kdeglobals
sed -i 's/Language=.*/Language='$LOCALSIMPLE'/' /etc/skel/.kde/share/config/kdeglobals
fi

####################### 
# supprimer fichiers d aide

echo -e "Nettoyage des fichiers locale et doc inutiles \n"
for i in $(locate . | egrep  "/af/|/am/|/an/|/ar/|/az/|/be/|/bg/|/bn/|/br/|/bs/|/ca/|/cs/|/csb/|/da/|/de/|/el/|/es/|/et/|/eu/|/fa/|/fi/|/fy/|/ga/|/gl/|/he/|/hi/|/hr/|/hu/|/hy/|/id/|/is/|/it/|/ja/|/ka/|/ko/|/ku/|/lb/|/lt/|/lv/|/mk/|/ms/|/nb/|/nl/|/nn/|/no/|/oc/|/pl/|/pt/|/pt_BR/|/ro/|/ru/|/sd/|/sk/|/sl/|/sr/|/sv/|/ta/|/tg/|/th/|/tl/|/tr/|/vi/|/zh_CN/|/zh_HK/|/zh_TW/") ;  do 
diR=$(echo "$i" |  sed 's/\/[^/]*$//')
rm -R "$diR" &>/dev/null
done

###################################
# conf de casper (boot du live cd)
echo -e "Adapte les fichiers de conf casper a la langue : $LOCALSIMPLE \n"
sed -i 's/kbd=.*/kbd='$LOCALESIMPLE'/g' /usr/share/initramfs-tools/scripts/casper-bottom/19keyboard &>/dev/null
sed -i 's/en_US.UTF-8/'$LOCALUTF'/g' /usr/share/initramfs-tools/scripts/casper-bottom/14locales &>/dev/null
sed -i 's/en_US.UTF-8/'$LOCALUTF'/g' /usr/share/initramfs-tools/scripts/casper-bottom/20xconfig &>/dev/null

echo -e "Changement de la langue par defaut des consoles tty avec : $LOCALSIMPLE \n"
sed -i 's/XKBLAYOUT=.*/XKBLAYOUT="'$LOCALSIMPLE'"/' /etc/default/console-setup

echo -e "Mise en place de la langue \"$LOCALSIMPLE\" terminée \n"
sleep 5
 
