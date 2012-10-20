#!/usr/bin/env python
#-*- coding: UTF-8 -*-

import os, sys, gtk
from glob import glob
import subprocess
from subprocess import Popen
import ConfigParser

## own import
from constants import *

def path_exist(dir):
    if os.path.exists(dir):
        return True
    else:
        return False
    
def create_dir(dir):
    try:
        os.makedirs(dir, 0755)
    except OSError as e:
        return False, e
    return True

def create_folderchooser_open(title):
    buttons     = (gtk.STOCK_CANCEL, gtk.RESPONSE_CANCEL,
                   gtk.STOCK_OPEN,   gtk.RESPONSE_OK)
    filechooser = gtk.FileChooserDialog(title,
                                        None,
                                        gtk.FILE_CHOOSER_ACTION_OPEN,
                                        buttons)
    filechooser.set_current_folder(HOME)
    filechooser.set_position('center')
    filechooser.set_action(gtk.FILE_CHOOSER_ACTION_SELECT_FOLDER)
    return filechooser


def Parser(ini):
    parser = ConfigParser.SafeConfigParser()
    try:
        parser.readfp(open(ini))
    except:
        pass
    return parser

def write_ini(parser,ini):
    with open(ini, 'wb') as configfile:
        parser.write(configfile)
        
def run_cmd(command):
    try:
        ret = Popen(command,shell=True, 
                    stdout=subprocess.PIPE).communicate()[0].strip()
    except:
        print _("cmd %s failed : ") % command
        return
    return ret

def scan_dist_path():
    dist_list = []
    parser = Parser(conf_file)
    try:
        dist_path = parser.get('ubukey', 'dist_path')
    except:
        return
    for dist in glob(dist_path+'/distribs/*'):
        dist_list.append(dist)
    return dist_path,dist_list

def get_dist_env(dist,dist_path):
    dist_conf = os.path.join(dist_path,'config') 
    parser = Parser(dist_conf)
    dist_env = parser.get(dist, 'distSession')
    return dist_env
    
    
def yesno(title,msg):
    dialog = gtk.MessageDialog(parent = None,
    buttons = gtk.BUTTONS_YES_NO,
    flags =gtk.DIALOG_DESTROY_WITH_PARENT,
    type = gtk.MESSAGE_QUESTION,
    message_format = msg
    )
    dialog.set_position("center")
    dialog.set_title(title)
    result = dialog.run()
    dialog.destroy()
    if result == gtk.RESPONSE_YES:
        return "Yes"
    elif result == gtk.RESPONSE_NO:
        return "No"

def error_dialog(message, parent = None):
    """
    Displays an error message.
    """
    dialog = gtk.MessageDialog(parent = parent,
                               type = gtk.MESSAGE_ERROR,
                               buttons = gtk.BUTTONS_OK,
                               flags = gtk.DIALOG_MODAL)
    dialog.set_markup(message)
    dialog.set_position('center')
    dialog.run()
    dialog.destroy()
    
    
    
