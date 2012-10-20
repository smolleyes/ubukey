#-*- coding: UTF-8 -*-
import os,gtk
from translation import Translation
import gettext 

version = "0.1"
APP_NAME = 'ubukey'
LANG=os.environ.get('LANG').split('_')[0]
HOME=os.environ.get('HOME')
exec_path = os.path.dirname(os.path.abspath(__file__))

## LOCALISATION
source_lang = "en"
rep_trad = "/usr/share/locale"

## gui
if ('/usr/local' in exec_path):
    data_path = os.path.join(exec_path,"/usr/local/share/ubukey")
elif ('/usr' in exec_path):
    data_path = os.path.join(exec_path,"/usr/share/ubukey")
else:
    data_path = os.path.dirname(os.path.dirname(exec_path))
    rep_trad = os.path.join(data_path,'lang')

print "traduction dir: %s" % rep_trad

glade_path = os.path.join(data_path,"data/glade")
GLADE_FILE = os.path.join(glade_path,'gui.glade')
img_path = os.path.join(data_path,"img")
conf_path = os.path.join(HOME,'.config/ubukey')
conf_file = os.path.join(conf_path,'config')
distribs_ini = os.path.join(conf_path,'distribs.ini')
glade_path = os.path.join(data_path,"data/glade")
GLADE_FILE = os.path.join(glade_path,'gui.glade')
scripts_path=os.path.join(data_path,'scripts')

## log settings
LOG=os.path.join(HOME,'.config/ubukey/logs/log')
LOGDIR=os.path.dirname(LOG)

##localisation end
traduction = Translation(APP_NAME, source_lang, rep_trad)
gettext.install(APP_NAME)
gtk.glade.bindtextdomain(APP_NAME, rep_trad)
gettext.textdomain(APP_NAME)
_ = traduction.gettext
