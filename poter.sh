#!/bin/bash
#
# Script to create pot/po/mo files 

basedir="$(pwd)/lang"
cd "$(pwd)"

LANGLIST="en fr"

if [ "$1" = "cmo" ]; then
	for lang in $LANGLIST; do
		echo "genere le .mo $lang"
		## finalise en creeant le .mo
		mkdir -p $basedir/$lang/LC_MESSAGES &>/dev/null
		msgfmt --output-file=$basedir/$lang/LC_MESSAGES/ubukey.mo $basedir/$lang/$lang.po
	done
	exit 0
fi

## cree pot fichier glade et des .py
xgettext --from-code=UTF-8 -k_ -kNeval_gettext -kN_ -o $basedir/ubukey.pot $(find /home/smo/Documents/projects/ubukey | egrep "\.glade|[a-zA-Z].py$|[a-zA-Z].sh$|\.pot" | xargs)
sed -i 's/CHARSET/UTF-8/' $basedir/ubukey.pot

## create or update po files
for lang in $LANGLIST; do
if [ ! -e "$basedir"/$lang/$lang.po ]; then
	mkdir "$basedir"/$lang &>/dev/null
	msginit --no-translator --input=$basedir/ubukey.pot --output=$basedir/$lang/$lang.po --locale=$lang_$(echo "$lang" | tr '[:lower:]' '[:upper:]')
else
	msginit --no-translator --input=$basedir/ubukey.pot --output=$basedir/$lang/$lang-update.po --locale=$lang_$(echo "$lang" | tr '[:lower:]' '[:upper:]')
	msgmerge -U $basedir/$lang/$lang.po $basedir/$lang/$lang-update.po
	## clean files
	rm $basedir/$lang/$lang-update.po &>/dev/null
	rm $basedir/$lang/$lang.po~ &>/dev/null
fi
done
