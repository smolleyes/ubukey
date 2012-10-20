#!/bin/bash

sudo rm /tmp/list &>/dev/null
touch /tmp/list

dist=`lsb_release -cs`

if [[ ! -e "/usr/bin/mkpasswd" || ! -e "/usr/bin/xterm" ]]; then
	sudo apt-get -y install whois xterm
fi

sessionType=$(sudo cat /etc/ubukey/ubukeyconf | grep -e "distSession" | sed 's/.*distSession=//')

listAddons=$(sudo find /usr/share/ubukey/addons/all/* /usr/share/ubukey/addons/$dist/$sessionType/* /usr/share/ubukey/addons/custom/*)
	
for i in $listAddons ; do
description=$(sed -n '/^DESCRIPTION=/{ :a; /"$/!{N; ba;}; s/DESCRIPTION=//;s/$//p;}' "$i" ) 
echo "$description"
name=$(basename "$i")
if [ -z "$description" ]; then
description="\"Aucune description...\""
fi 
echo -e "FALSE "$i" "$name" ""$description"" \\" | sudo tee -a /tmp/list &>/dev/null ## maybe here too
done
## remove latest "\"
sudo sed -i '$s/\\//g' /tmp/list

###### prepare zenity menu 
rm /tmp/zenity
touch /tmp/zenity

echo -e "#!/bin/bash
zenity --list --checklist \\
--width 800 --height 600 \\
--title \"Choix des Addons\" \\
--column=\"\" --column \"link\" --column \"Addon\" --column \"Description\" --hide-column=\"2\" \\" | sudo tee /tmp/zenity &>/dev/null

echo -e "`cat /tmp/list`" | sudo tee -a /tmp/zenity &>/dev/null
## remove latest "\"
sudo sed -i '$s/\\//g' /tmp/list

sudo chmod +x /tmp/zenity
bash /tmp/zenity > /tmp/addonsList

pre=$(cat /tmp/addonsList | sed 's/|/\\n/g')
list=$(echo -e "$pre")
case $? in
	0)
	for i in $list ; do
	xterm -geometry 100x30 -hold -e "$i" 
	done
	;;
	1)
	;;
esac

kill -9 `ps aux | grep -e "root" | grep -e [x]term | grep -e "/usr/local/bin/ubukey-addons" | awk '{print $2}' | xargs`
