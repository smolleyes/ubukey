#!/usr/bin/env python

import sys, os
from stat import *
from setuptools import find_packages
from distutils.core import setup
from distutils.command.install import install as _install

try:
    from DistUtilsExtra.command import *
except ImportError:
    print 'Cannot install ubukey :('
    print 'Would you please install package "python-distutils-extra and python-setuptools" first?'
    sys.exit()
import glob

INSTALLED_FILES = '.installed_files'

#stolen from ccsm
class install (_install):

	def run (self):

		_install.run(self)
		outputs = self.get_outputs()
		data = '\n'.join(outputs)
		try:
			f = open(INSTALLED_FILES, 'w')
		except:
			self.warn ('Could not write installed files list %s' %INSTALLED_FILES)
			return 

		f.write(data)
		f.close()

class uninstall(_install):

	def run(self):
		try:
			files = file(INSTALLED_FILES, 'r').readlines()
		except:
			self.warn('Could not read installed files list %s' %INSTALLED_FILES)
			return

		for f in files:
			print 'Uninstalling %s' %f.strip()
			try:
				os.unlink(f.strip())
			except:
				self.warn('Could not remove file %s' %f)
		os.remove(INSTALLED_FILES)

version = open('VERSION', 'r').read().strip()	

packages = ['Ubukey','Ubukey/lib']

data_files = [
	('share/icons/hicolor/22x22/apps',['images/22x22/ubukey.png']),
	('share/icons/hicolor/24x24/apps',['images/24x24/ubukey.png']),
	('share/icons/hicolor/48x48/apps',['images/48x48/ubukey.png']),
	('share/applications',['ubukey.desktop']),
	('share/ubukey/data/glade',['data/glade/gui.glade']),
	('share/ubukey/data/grub/i386',['data/grub/i386/stage2_eltorito']),
	('share/ubukey/data/grub/x86_64',['data/grub/x86_64/stage2_eltorito']),
	('share/ubukey/images', ['images/logo_xfce4.png',
	'images/vbox.png',  'images/splash.jpg',  'images/usbkey.png',
	'images/logo_kde4.png',  'images/logo_gnome.png', 
	'images/home-rw.png', 'images/logo_lxde.png', 'images/ubukeymaker.png','images/multisystem-liveusb.png'
	]),
	('share/ubukey/conf_files', ['conf_files/syslinux.cfg','conf_files/extlinux.conf']), 
	('share/ubukey/deboot-modules', ['deboot-modules/lxde', 
	'deboot-modules/gnome',  'deboot-modules/xfce4',  'deboot-modules/kde4','deboot-modules/cinnamon','deboot-modules/gnome-shell',
	]),
	('share/ubukey/scripts', ['scripts/dochroot.sh',  'scripts/ubusrc-gen',  'scripts/create_dist.sh',
	'scripts/debootstrap_dist.sh',  'scripts/mkbootcd.sh',  'scripts/ubukey-addons_manager.sh',
	'scripts/clone_dist.sh',  'scripts/themescan.sh',  'scripts/localiser-kde.sh','scripts/export_dist.sh',
	'scripts/localiser.sh',  'scripts/scankey.sh',  'scripts/vbox.sh','scripts/include.sh','scripts/setres.sh',
	'scripts/virtualbox.sh',  'scripts/remove_dist.sh',
	'scripts/debootstrap-packages.sh','scripts/debootstrap_packages_chooser.sh','scripts/multiboot.sh',
	]),
	('share/ubukey/launchers', ['launchers/gfx',  'launchers/Ubukeymaker.desktop',
	'launchers/wicd',  'launchers/mountrw.sh',  'launchers/sizer',  'launchers/gc.desktop',
	'launchers/ubukey.desktop'
	]),
	('share/ubukey/addons/all', ['addons/all/fix-tty.sh',
	'addons/all/utilisateur-live.sh', 'addons/all/installer.sh',  'addons/all/clone-pkglist.sh',
	'addons/all/live-homerw.sh'
	]),
	('share/ubukey/addons/raring/lxde', ['addons/raring/lxde/codecs-gstreamer.sh']),
	('share/ubukey/addons/raring/gnome', ['addons/raring/gnome/codecs-gstreamer.sh']),
	('share/ubukey/addons/raring/xfce4', ['addons/raring/xfce4/codecs-gstreamer.sh']),
	('share/ubukey/addons/quantal/lxde', ['addons/quantal/lxde/codecs-gstreamer.sh']),
	('share/ubukey/addons/quantal/gnome', ['addons/quantal/gnome/codecs-gstreamer.sh']),
	('share/ubukey/addons/quantal/xfce4', ['addons/quantal/xfce4/codecs-gstreamer.sh']),
	('share/ubukey/addons/precise/lxde', ['addons/precise/lxde/codecs-gstreamer.sh']),
	('share/ubukey/addons/precise/gnome', ['addons/precise/gnome/codecs-gstreamer.sh']),
	('share/ubukey/addons/precise/xfce4', ['addons/precise/xfce4/codecs-gstreamer.sh'])]


setup(
	name='ubukey',
	version=version,
	description='Create or customize ubuntu based distributions',
	author='Laguillaumie sylvain',
	author_email='s.lagui@free.fr',
	url='http://penguincape.org',
	packages=packages,
	scripts=['ubukey'],
	data_files=data_files,
	cmdclass={'build' :  build_extra.build_extra,
	    'build_i18n' :  build_i18n.build_i18n,
	    'build_help' :  build_help.build_help,
	    'build_icons' :  build_icons.build_icons,
	    'uninstall': uninstall,
	    'install': install,
	    },
)

#Stolen from ccsm's setup.py
if sys.argv[1] == 'install':
	
	prefix = None

	if len (sys.argv) > 2:
		i = 0
		for o in sys.argv:
			if o.startswith ("--prefix"):
				if o == "--prefix":
					if len (sys.argv) >= i:
						prefix = sys.argv[i + 1]
					sys.argv.remove (prefix)
				elif o.startswith ("--prefix=") and len (o[9:]):
					prefix = o[9:]
				sys.argv.remove (o)
				break
			i += 1

	if not prefix:
		prefix = '/usr'
	gtk_update_icon_cache = '''gtk-update-icon-cache -f -t \
%s/share/icons/hicolor''' % prefix
	root_specified = [s for s in sys.argv if s.startswith('--root')]
	if not root_specified or root_specified[0] == '--root=/':
		print 'Updating Gtk icon cache.'
		os.system(gtk_update_icon_cache)
	else:
		print '''*** Icon cache not updated. After install, run this:
***     %s''' % gtk_update_icon_cache
        os.system('xdg-desktop-menu install --novendor ubukey.desktop')

