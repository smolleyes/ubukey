#!/usr/bin/env python
#-*- coding: UTF-8 -*-

## own import
from constants import *
from functions import *
import os,gtk,sys,re

main_dist_path=None
dist_path=None

def checkConf():
	## load config and verify main distrib dir
	try:
		main_dist_path,dist_list,RESOLUTION = scan_dist_path()
		path=main_dist_path+'/distribs'
	except:
		path = FirstRun()
		print "generate config file..."
		generate_config(path)
	return loadConf(path)
	
def loadConf(path=None):
	main_dist_path,dist_list,RESOLUTION = scan_dist_path()
	dist_path=main_dist_path+'/distribs'
	if not os.access(main_dist_path, os.R_OK):
		error_dialog(_("Your distribution's folder :\n%s \nis not accessible, unmounted or removed (recreate it)...") % main_dist_path)
		sys.exit()
	# verify conf dirs
	flavours=['precise','quantal','raring']
	for flavour in flavours:
		listdir = ("distribs","isos","temp","addons/%s" % flavour,
				   "addons/%s/gnome" % flavour,"addons/%s/kde4" % flavour,
				   "addons/%s/xfce4" % flavour,"addons/%s/lxde" % flavour,
				   "addons/custom","addons/all")
		for d in listdir:
			target = os.path.join(path,d)
			if not path_exist(target):
				try:
					create_dir(target)
				except:
					print 'can t create dir %s' % target
            
## LOGS
if not path_exist(LOGDIR):
	create_dir(LOGDIR)
## clean the log file
if path_exist(LOG):
    os.remove(LOG)
                
def generate_config(path):
    if os.path.exists(conf_file):
        os.remove(conf_file)
    parser = Parser(conf_file)
    parser.add_section('ubukey')
    parser.set('ubukey', 'dist_path', path)
    parser.set('ubukey', 'kernel', run_cmd('uname -r'))
    parser.set('ubukey', 'dist', run_cmd('lsb_release -cs'))
    w,h=getResolution()
    parser.set('ubukey', 'resolution', w+'x'+h)
    write_ini(parser,conf_file)
    create_dir(LOGDIR)

def getResolution():
	try:
		os.system("gconftool-2 --set /apps/gksu/sudo-mode --type bool true" )
	except:
		print ""
	scr = os.system('/bin/bash ' + data_path +'/scripts/setres.sh')
	res= open('/tmp/zenitychoice',"r").read()
	try:
		width,height = res.split('x')
	except:
		width=1024
		height=768
	return width,height
        
def FirstRun():
    ## select a dir for the distributions
    dialog = create_folderchooser_open('Select a folder for your distributions')
    result = dialog.run()
    if result != gtk.RESPONSE_OK:
        dialog.destroy()
        return
    
    path = dialog.get_filename()
    if path_exist(conf_path):
        os.system('rm -R %s' % conf_path)
        os.mkdir(conf_path)
    else:
		os.mkdir(conf_path)
    dialog.destroy()
	
    path_part = os.popen("df '%s' | grep /dev | awk '{print $1}'" % path, 'r').read().strip()
    path_check = os.popen("mount | grep '%s' | grep -E '(ntfs|vfat|nosuid|noexec|nodev)'" % path_part, 'r').read().strip()
    if (path_check != ''):
        print "Please select another folder (no ntfs/fat partitions or partitions mounted with nosuid/nodev/noexec options or root protected...please correct fstab or choose another partition!)"
        return FirstRun()
    ## ok return the path
    return path
    
