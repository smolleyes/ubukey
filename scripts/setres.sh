#/bin/bash

r=$(xrandr --current | grep '*' | uniq | awk '{print $1}')
count=`echo -e "$r" | wc -l ` &>/dev/null
gksu rm /tmp/zenity* &>/dev/null

res=''
if [ $count > 1 ]; then
	echo -e "#!/bin/bash
zenity --list --radiolist \\
--width 400 --height 200 \\
--title \"Choose the size for ubukey virtual screen\" \\
--column \"choice\" \\
--column \"Resolution\" \\
--text \"Select a resolution...\" \\" | tee /tmp/zenity &>/dev/null
echo -e "$r" | sed -e '/*$/d' | sed 's/^/FALSE "/g' | sed 's/$/" \\/g' | sed '$s/\\//g'| tee -a /tmp/zenity &>/dev/null
chmod +x /tmp/zenity
/bin/bash /tmp/zenity >>/tmp/zenitychoice

## liste de resultat
res=`cat "/tmp/zenitychoice" | sed 's/|/\ \n/g'`

else
	res="$r"
	echo "$r" | tee /tmp/zenitychoice &>/dev/null
fi

echo -e "selected resolution: $res"
