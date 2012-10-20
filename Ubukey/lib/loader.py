#!/usr/bin/env python
#-*- coding: UTF-8 -*-

## own import
from constants import *
from functions import *
import os,gtk,sys,re

def checkConf():
    ## CONF FILE
    if not path_exist(conf_path) or not path_exist(conf_file):
        path = FirstRun()
        if path and path_exist(path):
            os.makedirs(conf_path, 0755)
            print _("selected path : %s") % path
            listdir = ("distribs","isos","temp","addons/precise",
                       "addons/precise/gnome","addons/precise/kde4",
                       "addons/precise/xfce4","addons/precise/lxde",
                       "addons/custom","addons/all")
            for d in listdir:
                target = os.path.join(path,d)
                if not path_exist(target):
                    create_dir(target)
            return generate_config(path)
        else:
            exit()
            
        ## load config and verify main distrib dir
        try:
            main_dist_path,dist_list = scan_dist_path()
        except:
            path = FirstRun()
            return generate_config(path)
        if not os.access(main_dist_path, os.R_OK):
            error_dialog(_("Your distrubution's folder :\n%s \nis not accessible, unmounted or removed (recreate it)...") % main_dist_path)
            sys.exit()
        if not os.path.exists(os.path.join(main_dist_path,'addons/custom')):
			os.mkdir(os.path.join(main_dist_path,'addons/custom'))
            
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
    write_ini(parser,conf_file)
    create_dir(LOGDIR)

        
def FirstRun():
    if not path_exist('/usr/bin/pkexec'):
        error_dialog(_('Please install the policykit-1 package'))
    
    ## select a dir for the distributions
    dialog = create_folderchooser_open(_('Select a folder for your distributions'))
    result = dialog.run()
    if result != gtk.RESPONSE_OK:
        dialog.destroy()
    return
    
    path = dialog.get_filename()
    if path_exist(conf_path):
        os.system('rm -R %s' % conf_path)
    dialog.destroy()
	
    path_part = os.popen("df '%s' | grep /dev | awk '{print $1}'" % path, 'r').read().strip()
    path_check = os.popen("mount | grep '%s' | grep -E '(ntfs|vfat|nosuid|noexec|nodev)'" % path_part, 'r').read().strip()
    if (path_check != ''):
        print _("Please select another folder (no ntfs/fat partitions or partitions mounted with nosuid/nodev/noexec options or root protected...please correct fstab or choose another partition!)")
        return FirstRun()
    ## ok return the path
    return path
    

