if [ ! -e "/etc/ubukey" ]; then
	mkdir /etc/ubukey
fi

CDIST=`lsb_release -cs`

if [ -e "/usr/share/ubukey" ]; then 
UBUKDIR="/usr/share/ubukey"
elif [ -e "/usr/local/share/ubukey" ]; then
UBUKDIR="/usr/local/share/ubukey"
else
UBUKDIR="$(pwd)/.."
fi

_X64="false"
if [[ "`uname -m`" == "x86_64" ]]; then
	_X64="true"
fi

echo -e '
UBUKEYDIR='$UBUKDIR'
X64='$_X64'
CURDIST='$CDIST'
###Pour exporter la librairie de gettext.
set -a
source gettext.sh
set +a
export TEXTDOMAIN=ubukey
export TEXTDOMAINDIR='$UBUKDIR'/lang
. gettext.sh
export ubukey=$0
' | tee /etc/ubukey/config &>/dev/null
