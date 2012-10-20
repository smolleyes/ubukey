#!/usr/bin/env python

import sys, os
from stat import *
from distutils.core import setup
from distutils.command.install import install as _install

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
    ('share/ubukey/images', ['images/logo_xfce4.png',
    'images/vbox.png',  'images/splash.jpg',  'images/usbkey.png',
    'images/logo_kde4.png',  'images/logo_gnome.png', 
    'images/home-rw.png', 'images/logo_lxde.png', 'images/ubukeymaker.png'
    ]),
    ('share/ubukey/conf_files', ['conf_files/syslinux.cfg']), 
    ('share/ubukey/deboot-modules', ['deboot-modules/lxde', 
    'deboot-modules/gnome',  'deboot-modules/xfce4',  'deboot-modules/kde4',
    ]),
    ('share/ubukey/scripts', ['scripts/dochroot.sh',  'scripts/ubusrc-gen',  'scripts/create_dist.sh',
    'scripts/debootstrap_dist.sh',  'scripts/mkbootcd.sh',  'scripts/ubukey-addons_manager.sh',
    'scripts/clone_dist.sh',  'scripts/themescan.sh',  'scripts/localiser-kde.sh',
    'scripts/ubukey-kde4.sh',  'scripts/ubukey-gnome.sh',  'scripts/export_dist.sh',
    'scripts/localiser.sh',  'scripts/scankey.sh',  'scripts/vbox.sh',
    'scripts/ubukey-xfce4.sh',  'scripts/virtualbox.sh',  'scripts/remove_dist.sh',
    'scripts/debootstrap-packages.sh','scripts/debootstrap_packages_chooser.sh'
    ]),
    ('share/ubukey/launchers', ['launchers/gfx',  'launchers/Ubukeymaker.desktop',
    'launchers/wicd',  'launchers/mountrw.sh',  'launchers/sizer',  'launchers/gc.desktop',
    'launchers/ubukey.desktop'
    ]),
    ('share/ubukey/addons/all', ['addons/all/fix-tty.sh',
    'addons/all/utilisateur-live.sh', 'addons/all/installer.sh',  'addons/all/clone-pkglist.sh',
    'addons/all/live-homerw.sh'
    ]),
    ('share/ubukey/addons/maverick/lxde', ['addons/maverick/lxde/codecs-gstreamer.sh']),
    ('share/ubukey/addons/maverick/gnome', ['addons/maverick/gnome/codecs-gstreamer.sh']),
    ('share/ubukey/addons/maverick/xfce4', ['addons/maverick/xfce4/codecs-gstreamer.sh']),
    ('share/ubukey/addons/natty/lxde', ['addons/natty/lxde/codecs-gstreamer.sh']),
    ('share/ubukey/addons/natty/gnome', ['addons/natty/gnome/codecs-gstreamer.sh']),
    ('share/ubukey/addons/natty/xfce4', ['addons/natty/xfce4/codecs-gstreamer.sh']),
    ('share/ubukey/addons/lucid/lxde', ['addons/lucid/lxde/codecs-gstreamer.sh']),
    ('share/ubukey/addons/lucid/gnome', ['addons/lucid/gnome/codecs-gstreamer.sh']),
    ('share/ubukey/addons/lucid/xfce4', ['addons/lucid/xfce4/codecs-gstreamer.sh']),
    ('share/ubukey/addons/oneiric/lxde', ['addons/oneiric/lxde/codecs-gstreamer.sh']),
    ('share/ubukey/addons/oneiric/gnome', ['addons/oneiric/gnome/codecs-gstreamer.sh']),
    ('share/ubukey/addons/oneiric/xfce4', ['addons/oneiric/xfce4/codecs-gstreamer.sh']),
    ('share/ubukey/addons/precise/lxde', ['addons/precise/lxde/codecs-gstreamer.sh']),
    ('share/ubukey/addons/precise/gnome', ['addons/precise/gnome/codecs-gstreamer.sh']),
    ('share/ubukey/addons/precise/xfce4', ['addons/precise/xfce4/codecs-gstreamer.sh']),
]


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
	cmdclass={
		'uninstall': uninstall,
		'install': install},
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
		prefix = '/usr/local'
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

