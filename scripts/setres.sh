#/bin/bash

r=$(xrandr --current | grep '*' | uniq | awk '{print $1}')
count=`echo -e "$r" | wc -l ` &>/dev/null
gksu rm /tmp/zenity* &>/dev/null

res=''
echo -e "#!/bin/bash
zenity --list --radiolist \\
--width 400 --height 200 \\
--title \"Choose the size for ubukey virtual screen\" \\
--column \"choice\" \\
--column \"Resolution\" \\
--text \"Select a resolution...\" \\
FALSE \"Custom\" \\" | tee /tmp/zenity &>/dev/null
echo -e "$r" | sed -e '/*$/d' | sed 's/^/FALSE "/g' | sed 's/$/" \\/g' | sed '$s/\\//g'| tee -a /tmp/zenity &>/dev/null
chmod +x /tmp/zenity
/bin/bash /tmp/zenity >>/tmp/zenitychoice1

## liste de resultat
res=`cat "/tmp/zenitychoice1" | sed 's/|/\ \n/g'`
if [ "$res" = "Custom" ]; then
	rm /tmp/zenitycustom
	rm /tmp/zenitycustomchoice
	rm /tmp/zenitychoice 
	echo -e "#!/bin/bash
	zenity --entry --title \"Custom-resolution\" \\
	--text \"enter your custom resolution\" \\" | tee /tmp/zenitycustom &>/dev/null 
	chmod +x /tmp/zenitycustom
	/bin/bash /tmp/zenitycustom >>/tmp/zenitycustomchoice
	res2=`cat "/tmp/zenitycustomchoice" | sed 's/|/\ \n/g'`
	echo "$res2" | tee /tmp/zenitychoice &>/dev/null
	echo -e "selected resolution: $res2"
else
	echo "$res" | tee /tmp/zenitychoice &>/dev/null
	echo -e "selected resolution: $res"
fi

