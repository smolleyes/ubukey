#!/bin/bash
###################_pass_###################
DESCRIPTION="Changer l utilisateur par défaut de votre live-cd/usb, son mot de passe
et permet églement d'activer ou désactiver l'autologin..."

if [[ "$UID" -ne 0 ]]; then
  	CMDLN_ARGS="$@"
	export CMDLN_ARGS
	exe=`pgrep utilisateur-live.sh`
	exec sudo /usr/share/ubukey/addons/all/utilisateur-live.sh && kill -9 "$exe" 
fi


function MOD_USER()
{
USER_LIVEUSB="$(cat /etc/casper.conf | grep "export USERNAME" | awk -F= '{print $2}'  | sed 's/[\"]//g')"
old_user="$USER_LIVEUSB"
USER_LIVEUSB=$(zenity \
--window-icon="/usr/share/pixmaps/ubuntu-screensaver.svg" \
--width=600 \
--height=120 \
--entry \
--title="Modifier nom utilisateur" \
--text="Saisissez votre nom d'utilisateur (Caractères autorisés: [A-Za-z0-9_-*.])" \
--entry-text "$USER_LIVEUSB" \
)
case $? in 
0)
LOCALUTF="$(cat /etc/ubukey/ubukeyconf | grep -e "localutf" | sed 's/.*=//')"
LOCALBASE="$(cat /etc/ubukey/ubukeyconf | grep -e "localbase" | sed 's/.*=//')"
LOCALSIMPLE="$(cat /etc/ubukey/ubukeyconf | grep -e "localsimple" | sed 's/.*=//')"

unset LC_COLLATE

if [[ ! $(grep "^[-[:alnum:]_.]*$" <<<"$USER_LIVEUSB") || -z "$USER_LIVEUSB" ]]; then

echo -e "Nom d'utilisateur vide ou erroné, n'utilisez pas d'espaces
, pas de caractères spéciaux ni de caractères accentués svp.\n"

else

CHANGE_USER="# This file should go in /etc/casper.conf
# Supported variables are:
# USERNAME, USERFULLNAME, HOST, BUILD_SYSTEM

export USERNAME=\"$USER_LIVEUSB\"
export USERFULLNAME=\"Session de $USER_LIVEUSB\"
export HOST=\"$USER_LIVEUSB\"
export BUILD_SYSTEM=\"$USER_LIVEUSB\"
export FLAVOUR=\"$USER_LIVEUSB\"
"
echo -e "$CHANGE_USER" | tee /etc/casper.conf &>/dev/null

fi

## langue dans chroot
export LANG=$LOCALUTF
export LC_ALL=$LOCALUTF

;;
1)
exit 0
;;
*)
exit 0
;;

esac

}

function VALIDPASS()
{
PASS="$1"
PASSNUM="$2"

if [ -z "$PASS" ]; then
	echo -e "Mot de passe vide"
	SAISIEPASS
fi

if [[ -z "$PASS1" || -z "$PASS2" ]]; then
		case $PASSNUM in
			1)
				PASS1="$PASS"
			;;
			2)
				PASS2="$PASS"
			;;
		esac 
fi

if [[ -n "$PASS1" && -n "$PASS2" ]]; then

		if [[ "$PASS1" != "$PASS2" ]]; then
			echo -e "Le mot de passe \""$PASS2"\" ne correspond pas à \""$PASS1"\"... on recommence :) \n"
			PASS1=""
			PASS2=""
			SAISIEPASS
		else
			PASSWORD="$PASS2"
			PASS1=""
			PASS2=""
			echo -e "Votre mot de passe sera $PASSWORD"
		fi
fi

}

PASSMENU() 
{

USER_LIVEUSB="$(cat /etc/casper.conf | grep "export USERNAME" | awk -F= '{print $2}'  | sed 's/[\"]//g')"
MOD_PASS=$(zenity \
--title="Live CD/USB" \
--text="Choisir l'option désirée dans la liste ci-dessous" \
--window-icon="/usr/share/pixmaps/ubuntu-screensaver.svg" \
--width=640 \
--height=200 \
--list \
--print-column="2" \
--radiolist \
--separator=" " \
--column="*" \
--column="Val" \
--column="Fonction à exécuter" \
--hide-column="2" \
FALSE "A" "Utiliser mot de passe choisit pour utilisateur $USER_LIVEUSB" \
FALSE "B" "Utiliser mot de passe choisit pour utilisateur $USER_LIVEUSB et ROOT" \
TRUE "C" "Pas de mot de passe pour utilisateur $USER_LIVEUSB (comme le cd original...)" \
)

case $MOD_PASS in
A)
SAISIEPASS
CHOIX_PASS

echo -e "Initialise le mot de passe "$CRYPTEDPASS" pour l'utilisateur "$USER_LIVEUSB" \n"
sed -i 's/set passwd\/user-password-crypted .*\.*/set passwd\/user-password-crypted '${CRYPTEDPASS}'/' "$CHEMIN_USER"
sed -i 's/NOPASSWD: ALL/ALL/g' "$CHEMIN_USER"
sed -i '/'$old_user'/d' /etc/sudoers
AUTO_LOGIN

;;
B)
SAISIEPASS
CHOIX_PASS

echo -e "Initialise le mot de passe "$CRYPTEDPASS" pour l'utilisateur ROOT et "$USER_LIVEUSB" \n"
sed -i 's/set passwd\/user-password-crypted .*\.*/set passwd\/user-password-crypted '${CRYPTEDPASS}'/' "$CHEMIN_USER"
sed -i 's/set passwd\/root-password-crypted .*\.*/set passwd\/root-password-crypted '${CRYPTEDPASS}'/' "$CHEMIN_USER"
sed -i 's/NOPASSWD: ALL/ALL/g' "$CHEMIN_USER"
sed -i '/'$old_user'/d' /etc/sudoers
AUTO_LOGIN

;;
C)
echo -e "Desactive le mot de passe pour l'utilisateur "$USER_LIVEUSB" \n"
sed -i 's/set passwd\/user-password-crypted .*\.*/set passwd\/user-password-crypted U6aMy0wojraho/' "$CHEMIN_USER"
sed -i 's/set passwd\/root-password-crypted .*\.*/set passwd\/root-password-crypted U6aMy0wojraho/' "$CHEMIN_USER"
sed -i '/'$old_user'/d' /etc/sudoers 
echo -e ""$USER_LIVEUSB" ALL=NOPASSWD: ALL" | tee -a /etc/sudoers &>/dev/null
AUTO_LOGIN

;;
esac

}

function CRYPTPASS() 
{
echo -e "Encryptage du mot de passe \""$PASSWORD"\" \n"
CRYPTEDPASS=""
CRYPTEDPASS=$(mkpasswd -s "$PASSWORD")
while [[ ! `echo "$CRYPTEDPASS" | grep -w "^[A-Za-z0-9]*$"` ]]; do
echo -e "Mauvais mot de passe \""$CRYPTEDPASS"\", contient des caractères interdit
Nouvelle tentative..."
CRYPTEDPASS=$(mkpasswd -s "$PASSWORD")
done

echo -e "Mot de passe encrypté ok : $PASSWORD (encrypté = $CRYPTEDPASS) \n"
sleep 3
}


function CHOIX_PASS()
{
CHEMIN_USER="/usr/share/initramfs-tools/scripts/casper-bottom/25adduser"
TEST_PASS=$(cat "$CHEMIN_USER" | grep -e "set passwd/user-password-crypted U6aMy0wojraho")

if [[ -e "$CHEMIN_USER" && -n "$TEST_PASS" || -n "$FORCEPWD" ]]; then

CRYPTPASS

else
	echo -e "Mot de passe deja edité... \n"
fi

}


###################_fin_pass_###################

function SAISIEPASS()
{
if [ -z "$WARNING" ]; then
zenity --info --width 600  --text "
Vous allez pouvoir (re)changer le mot de passe pour votre live-cd.

indiquez un mot de passe sans espaces...

Cliquez \"Valider\" pour continuer."

WARNING="TRUE"
fi

if [ -z "$PASS1" ]; then
GETPASS1=""
GETPASS1=$(zenity --entry --hide-text --text "Saisie du nouveau mot de passe utilisateur (1)")
VALIDPASS "$GETPASS1" 1 
fi

if [ -z "$PASS2" ]; then
GETPASS2=""
GETPASS2=$(zenity --entry --hide-text --text "Confirmez, Saisie du mot de passe utilisateur (2)")
VALIDPASS "$GETPASS2" 2
fi



}

###################_AUTO_LOGIN_###################
function AUTO_LOGIN()
{
FICHIER="/usr/share/initramfs-tools/scripts/casper-bottom/15autologin"
if [ -e "$FICHIER" ]; then

## petit check pour le statut actuel
if [[ `cat "$FICHIER" | grep -e "AutoLoginEnable=true"` ]]; then
	STATUT="actif"
else
	STATUT="inactif"
fi

## Fonctions enable/disable auto-login
function AUTO_LOGIN_FALSE()
{
sed -i 's/AutoLoginEnable=true/AutoLoginEnable=false/g' "$FICHIER"
sed -i 's/AutomaticLoginEnable=true/AutomaticLoginEnable=false/g' "$FICHIER"
echo -e "L'auto-login a bien été désactivé ... \n"
sleep 2
}

function AUTO_LOGIN_TRUE()
{
sed -i 's/AutoLoginEnable=false/AutoLoginEnable=true/g' "$FICHIER"
sed -i 's/AutomaticLoginEnable=false/AutomaticLoginEnable=true/g' "$FICHIER"
echo -e "L'auto-login a bien été activé ... \n"
sleep 2
}

## et on lance le menu
AUTOLOGIN=$(zenity \
--title="Live CD/USB" \
--text="Choisir l'option désirée dans la liste ci-dessous...
(l'autologin est actuellement $STATUT)" \
--window-icon="/usr/share/pixmaps/ubuntu-screensaver.svg" \
--width=400 \
--height=220 \
--list \
--radiolist \
--column="*" \
--column="Val" \
--column="Activer/Désactiver autologin" \
--hide-column="2" \
TRUE "A" "Activer l'autologin " \
FALSE "B" "Désactiver l'autologin" \
)

case $? in
	0)
	case $AUTOLOGIN in
		A)
		if [[ "$STATUT" = "actif" ]]; then
			echo -e "L'auto-login est déjà actif, rien à faire..."
			sleep 2 
		else
			AUTO_LOGIN_TRUE
		fi
		;;
		B)
		if [[ "$STATUT" = "inactif" ]]; then
			echo -e "L'auto-login est déjà inactif, rien à faire..."
		else
			AUTO_LOGIN_FALSE
			sleep 2
		fi
		;;
	esac
	;;
	1)
	echo -e "Modification de l'auto-login annulé... \n"
	sleep 2
	;;
esac

fi

}
###################_fin_AUTO_LOGIN_###################

function CHECKPASS()
{
CHEMIN_USER="/usr/share/initramfs-tools/scripts/casper-bottom/25adduser"
TEST_PASS=$(cat "$CHEMIN_USER" | grep -e "set passwd/user-password-crypted U6aMy0wojraho")

## check is password a deja ete modifie ou pas
if [ -z "$TEST_PASS" ]; then
	zenity --question \
	--title "Mot de passe" \
	--text "Le mot de passe a déjà été changé, souhaitez vous le remodifier ?"
	case $? in 
		0)
		FORCEPWD="True"
		echo -e "(Re)démarre l'assistant de création du mot de passe... \n"
		PASSMENU
		;;
		1)
		echo -e "Ok on continue sur l'auto-login... \n"
		sleep 2	
		AUTO_LOGIN
		;;
	esac

else
	echo -e "(Re)démarre l'assistant de création du mot de passe... \n"
	PASSMENU
fi
}

MOD_USER
CHECKPASS

zenity --info --text "Setup utilisateur terminé...

L'utilisateur \""$USER_LIVEUSB"\" est désormais actif sur votre live-cd !\n"

kill -9 `ps aux | grep -e "hold" | grep -e [x]term | grep -e "/usr/share/ubukey/addons" | awk '{print $2}' | xargs`
