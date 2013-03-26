#!/bin/bash
source /etc/ubukey/config

MENU=''
rm /tmp/full_list &>/dev/null

function select_webbrowser(){
MENU='#!/bin/bash
zenity --list --checklist \
--width 800 --height 600 \
--title "Paquets supplémentaires" \
--text "Choisissez votre navigateur internet:" \
--column="État" --column "Nom" \
FALSE firefox \
FALSE "chromium-browser chromium-codecs-ffmpeg-extra chromium-browser-l10n" \
FALSE opera \
FALSE midori \
'
}

function select_loginmanager(){
MENU='#!/bin/bash
zenity --list --checklist \
--width 800 --height 600 \
--title "Paquets supplémentaires" \
--text "Choisissez votre gestionnaire de connexion:" \
--column="État" --column "Nom" \
FALSE lightdm \
FALSE gdm \
FALSE kdm \
FALSE lxdm \
'
}

function select_mail(){
MENU='#!/bin/bash
zenity --list --checklist \
--width 800 --height 600 \
--title "Paquets supplémentaires" \
--text "Choisissez votre gestionnaire de courriels:" \
--column="État" --column "Nom" \
FALSE thunderbird \
FALSE evolution \
'
}

function select_media(){
MENU='#!/bin/bash
zenity --list --checklist \
--width 800 --height 600 \
--title "Paquets supplémentaires" \
--text "Choisissez vos lecteurs multimédia:" \
--column="État" --column "Nom" \
FALSE rhythmbox \
FALSE banshee \
FALSE exaile \
FALSE totem \
FALSE vlc \
FALSE mplayer \
'
}

function select_textedit(){
MENU='#!/bin/bash
zenity --list --checklist \
--width 800 --height 600 \
--title "Paquets supplémentaires" \
--text "Choisissez votre éditeur de texte:" \
--column="État" --column "Nom" \
FALSE gedit \
FALSE kate \
FALSE geany \
FALSE leafpad \
FALSE mousepad \
'
}

function select_archiver() {
MENU='#!/bin/bash
zenity --list --checklist \
--width 800 --height 600 \
--title "Paquets supplémentaires" \
--text "Choisissez votre gestionnaire d archives et addons...:" \
--column="État" --column "Nom" \
FALSE file-roller \
FALSE xarchiver \
FALSE "rar unrar" \
FALSE "zip unzip" \
'
}

function show_menu(){
echo -e "$MENU" | tee /tmp/pchooser &>/dev/null
rm /tmp/List
sudo chmod +x /tmp/pchooser
bash /tmp/pchooser | tee -a /tmp/List &>/dev/null

list=$(cat /tmp/List | sed 's/|/ /g' | xargs)

case $? in
    0)
    echo "$list" | tee -a /tmp/full_list &>/dev/null
    ;;
    1)
    exit 1
    ;;
esac
}

function install_packages(){

list=$(cat /tmp/full_list | xargs)
echo -e "\nPaquets selectionnes : \n $list"
case $? in
    0)
    if [[ `echo -e "$list" | grep opera` ]]; then
    wget -O - http://deb.opera.com/archive.key | apt-key add -
    echo "deb http://deb.opera.com/opera/ stable non-free" | tee -a "$DISTDIR"/chroot/etc/apt/sources.list.d/opera.list 
    fi
    chroot "$DISTDIR"/chroot apt-get update
    chroot "$DISTDIR"/chroot apt-get install -y --force-yes $list
    ;;
    1)
    exit 1
    ;;
esac
rm /tmp/full_list

}

select_webbrowser
show_menu
select_loginmanager
show_menu
select_mail
show_menu
select_media
show_menu
select_textedit
show_menu
select_archiver
show_menu
install_packages
