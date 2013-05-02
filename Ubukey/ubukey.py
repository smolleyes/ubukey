#!/usr/bin/env python
#-*- coding: UTF-8 -*-

import pygtk
pygtk.require('2.0')
import gtk
import gtk.glade
import os, re, time
import Xlib
import Xlib.display
from Xlib import X
from subprocess import Popen, PIPE

## own import
from lib.loader import *
from lib.terminal import VirtualTerminal
from lib.distribs import Distribs
from lib.constants import *
from lib.functions import get_dist_env

class Ubukey_gui(object):
	def __init__(self):
		if os.getuid() == 0:
			self.error_dialog(_("Ubukey can't start as root user ..."),None)
			exit()
		self.selected_dist_path=None
		## set the gladexml file
		self.gladexml = gtk.glade.XML(GLADE_FILE, None ,APP_NAME)
		self.plugins_dialog = self.gladexml.get_widget("plugins_dialog")
		self.options_dialog = self.gladexml.get_widget("options_dialog")
		self.selected_dist = None
		## the main window and properties
		self.window = self.gladexml.get_widget("main_window")
		self.window.set_resizable(1)
		self.window.set_position("center")
		## glade widgets
		self.eventbox = self.gladexml.get_widget("eventbox1")
		self.vt_container = self.gladexml.get_widget("vt_container")
		self.run_btn_label = self.gladexml.get_widget("run_btn_label")
		self.run_btn_img = self.gladexml.get_widget("run_btn_img")
		self.run_btn_state = "stopped"
		
		# menu buttons
		self.run_btn = self.gladexml.get_widget("run_btn")
		self.newdist_btn = self.gladexml.get_widget("newdist_btn")
		self.deletedist_btn = self.gladexml.get_widget("removedist_btn")
		self.clonedist_btn = self.gladexml.get_widget("clone_btn")
		self.exportdist_btn = self.gladexml.get_widget("export_btn")
		self.testdist_btn = self.gladexml.get_widget("vbox_btn")
		self.bootcd_btn = self.gladexml.get_widget("bootcd_btn")
		self.plugins_btn = self.gladexml.get_widget("plugins_btn")
		self.multiboot_btn = self.gladexml.get_widget("multiboot_btn")
		
		# notebook
		self.notebook = self.gladexml.get_widget('notebook1')
		## vbox btn
		self.vbox_img = self.gladexml.get_widget('vbox_img')
		img = gtk.gdk.pixbuf_new_from_file_at_scale(os.path.join(data_path,'images/vbox.png'), 24, 24, 1)
		self.vbox_img.set_from_pixbuf(img)
		## dist logo
		self.distlogo = self.gladexml.get_widget('distlogo_img')
		## multiboot btn
		self.mboot_img = self.gladexml.get_widget('multiboot_img')
		img = gtk.gdk.pixbuf_new_from_file_at_scale(os.path.join(data_path,'images/multisystem-liveusb.png'), 24, 24, 1)
		self.mboot_img.set_from_pixbuf(img)
		## drawingarea
		self.drawarea=self.gladexml.get_widget('mboot_drawing')
		
		## dist list treeview
		self.dist_scroll = self.gladexml.get_widget("dist_scroll")
		self.dist_model = gtk.ListStore(str, str)
	
		self.distTree = gtk.TreeView()
		self.distTree.set_model(self.dist_model)
		renderer = gtk.CellRendererText()
		titleColumn = gtk.TreeViewColumn("Name", renderer, text=0)
		titleColumn.set_min_width(200)
		pathColumn = gtk.TreeViewColumn()
	
		self.distTree.append_column(titleColumn)
		self.distTree.append_column(pathColumn)
	
		## setup the scrollview
		self.columns = self.distTree.get_columns()
		self.columns[0].set_sort_column_id(1)
		self.columns[1].set_visible(0)
		self.dist_scroll.add(self.distTree)
		self.distTree.connect('cursor-changed',self.get_selected_dist)
	
		## plugins list treeview
		self.plug_scroll = self.gladexml.get_widget("plug_scroll")
		self.plugins_model = gtk.ListStore(str, str)
	
		self.plugTree = gtk.TreeView()
		self.plugTree.set_model(self.plugins_model)
		renderer = gtk.CellRendererText()
		renderer.connect('edited', self.rename_plugin)
		renderer.set_property('editable', True)
		pathColumn = gtk.TreeViewColumn()
	
		self.plugTree.insert_column_with_attributes(-1, 'Name', renderer, text=0)
		self.plugTree.append_column(pathColumn)
		
		columns = self.plugTree.get_columns()
		columns[0].set_sort_column_id(1)
		columns[1].set_visible(0)
		self.plug_scroll.add(self.plugTree)
		self.plugTree.connect('cursor-changed',self.get_selected_plug)
		
		
		## add socket for Xephyr
		self.socket = gtk.Socket()
		self.socket.show()
		self.eventbox.add(self.socket)
		# options dialog
		self.resolution_entry = self.gladexml.get_widget("resolution_entry")
		
		## signals
		dic = {"on_destroy_event" : self.exit,
			   "on_delete_event" : self.exit,
			   "on_start_btn_clicked" : self.set_startdist_btn_state,
			   "on_newdist_btn_clicked" : self.new_dist,
			   "on_removedist_btn_clicked" : self.remove_dist,
			   "on_export_btn_clicked" : self.export_dist,
			   "on_vbox_btn_clicked" : self.start_vbox,
			   "on_bootcd_btn_clicked" : self.gen_bootcd,
			   "on_clone_btn_clicked" : self.clone_dist,
			   "on_plugins_btn_clicked" : self.exec_plugins_dialog,
			   "on_new_plug_btn_clicked" : self.create_plug,
			   "on_edit_plug_btn_clicked" : self.edit_plug,
			   "on_del_plug_btn_clicked" : self.delete_plug,
			   "on_refresh_plug_btn_clicked" : self.exec_plugins_dialog,
			   "on_multiboot_btn_clicked" : self.start_multiboot,
			   "on_sourceFolder_btn_clicked" : self.open_source_folder,
			   "on_close_plug_dialog_btn_clicked" : self.close_plugin_dialog,
			   "on_pref_button_clicked": self.exec_options_dialog,
			   "on_close_options_dialog_btn_clicked": self.close_options_dialog
			   }
		
		self.gladexml.signal_autoconnect(dic)
		self.start_gui()
    
	def lock_gui(self):
		self.dist_scroll.set_sensitive(False) 
	
	def unlock_gui(self):
		self.dist_scroll.set_sensitive(True)
		
	def lock_menu(self):
		self.run_btn.set_sensitive(False) 
		self.newdist_btn.set_sensitive(False) 
		self.deletedist_btn.set_sensitive(False) 
		self.clonedist_btn.set_sensitive(False) 
		self.exportdist_btn.set_sensitive(False) 
		self.testdist_btn.set_sensitive(False) 
		self.bootcd_btn.set_sensitive(False) 
		self.plugins_btn.set_sensitive(False) 
		self.multiboot_btn.set_sensitive(False)
		
	def unlock_menu(self):
		self.run_btn.set_sensitive(True) 
		self.newdist_btn.set_sensitive(True) 
		self.deletedist_btn.set_sensitive(True) 
		self.clonedist_btn.set_sensitive(True) 
		self.exportdist_btn.set_sensitive(True) 
		self.testdist_btn.set_sensitive(True) 
		self.bootcd_btn.set_sensitive(True) 
		self.plugins_btn.set_sensitive(True) 
		self.multiboot_btn.set_sensitive(True) 
	
	def start_gui(self):
		try:
			self.main_dist_path,dist_list,RESOLUTION = scan_dist_path()
		except:
			path = checkConf()
			return self.start_gui()
		## load resolution
		self.resolution=RESOLUTION
		try:
			width,height = self.resolution.split('x')
			self.window.set_default_size(int(width), int(height) - 50)
		except:
			self.window.set_default_size(1024, 768)
		##  start gui widgets
		self.window.show_all()
		self.load_distribs_xml()
		self.start_Xephyr()
		self.startVt()
		## create system config file
		self.vt.run_command('/bin/bash ' + data_path +'/scripts/include.sh')
		gtk.main()
	
	def error_dialog(self,message, parent = None):
		"""Displays an error message."""
		dialog = gtk.MessageDialog(parent = parent, type = gtk.MESSAGE_ERROR, buttons = gtk.BUTTONS_OK, flags = gtk.DIALOG_MODAL)
		dialog.set_markup(message)
		dialog.set_position('center')
		result = dialog.run()
		dialog.destroy()
		
	def warning_dialog(self,message,parent=None):
		"""Displays an warning/info message."""
		dialog = gtk.MessageDialog(parent = parent, type = gtk.MESSAGE_WARNING, buttons = gtk.BUTTONS_OK, flags = gtk.DIALOG_MODAL)
		dialog.set_markup(message)
		dialog.set_position('center')
		result = dialog.run()
		dialog.destroy()
				   
	def start_Xephyr(self):
		xid = self.socket.get_id()
		lockfile="/tmp/.X5-lock"
		if os.path.exists(lockfile):
			os.remove(lockfile)
		os.system('killall -9 Xephyr')
		cmd = "Xephyr :5 -dpms -s 0 -title ubukey-xephyr \
		-ac \
		-keybd ephyr,,xkbrules=evdev,xkbmodel=evdev,xkblayout=%s,xkbvariant=oss, -parent %s +extension RANDR +extension XTEST +extension DOUBLE-BUFFER +extension Composite +extension XFIXES +extension DAMAGE +extension RENDER +extension GLX & sleep 4" % (LANG,xid)
		self.xephyr_pipe = Popen(cmd,shell=True)
		
	def get_selected_dist(self,widget):
		"""return the path of the selected dist in the gui treeview"""
		selected = self.distTree.get_selection()
		self.dist_iter = selected.get_selected()[1]
		## else extract needed metacity's infos
		self.selected_dist = self.dist_model.get_value(self.dist_iter, 0)
		self.selected_dist_path = self.dist_model.get_value(self.dist_iter, 1)
		session = get_dist_env(self.selected_dist,self.selected_dist_path)
		if session and not session == "":
			img = os.path.join(data_path,"images/logo_%s.png" % session)
			self.distlogo.set_from_file(img)
	
	def get_selected_plug(self,widget=None):
		"""return the path of the selected dist in the gui treeview"""
		selected = self.plugTree.get_selection()
		self.plug_iter = selected.get_selected()[1]
		## else extract needed metacity's infos
		self.selected_plug = self.plugins_model.get_value(self.plug_iter, 0)
		self.selected_plug_path = os.path.join(self.plugins_model.get_value(self.plug_iter, 1),self.selected_plug)
		
	def set_startdist_btn_state(self,widget):
		if self.run_btn_state == "stopped":
			if self.selected_dist_path is None:
				return
			self.lock_menu()
			self.lock_gui()
			self.run_btn.set_sensitive(True)
			self.distribs.start()
		elif self.run_btn_state == "started":
			self.distribs.stop()
		
	def startVt(self):
		self.vt = VirtualTerminal(LOG)
		self.vt_container.add(self.vt)
		self.vt.show()
		
	def load_distribs_xml(self):
		self.distribs = Distribs(self)
		self.distribs.update_list()
		
	def new_dist(self,widget=None):
		self.lock_menu()
		self.lock_gui()
		self.distribs.new_dist()
		self.unlock_menu()
		self.unlock_gui()
		
	def export_dist(self,widget):
		self.lock_gui()
		self.lock_menu()
		self.distribs.export_dist()
		self.unlock_menu()
		self.unlock_gui()
		
	def remove_dist(self,widget):
		self.lock_gui()
		self.lock_menu()
		self.distribs.remove_dist()
		self.unlock_gui()
		self.unlock_menu()
		
	def start_vbox(self,widget):
		self.lock_menu()
		self.lock_gui()
		self.distribs.start_vbox()
		self.unlock_menu()
		self.unlock_gui()
		
	def gen_bootcd(self,widget):
		self.lock_menu()
		self.lock_gui()
		self.distribs.gen_bootcd()
		self.unlock_menu()
		self.unlock_gui()
		
	def clone_dist(self,widget):
		self.lock_menu()
		self.lock_gui()
		self.distribs.clone_dist()
		self.unlock_menu()
		self.unlock_gui()
		
	def exec_plugins_dialog(self,widget):
		self.distribs.plugins_dialog()
	
	def create_plug(self,widget):
		self.distribs.create_plug()
	
	def delete_plug(self,widget):
		self.distribs.delete_plug()
	
	def edit_plug(self,widget):
		self.distribs.edit_plug()
		
	def start_multiboot(self,widget):
		self.distribs.start_multiboot()
		
	def open_source_folder(self,widget):
		self.distribs.open_source_folder()
	
	def close_plugin_dialog(self,widget):
		self.plugins_dialog.hide()
	
	def exec_options_dialog(self,widget):
		self.distribs.options_dialog()
	
	def rename_plugin(self,widget,cell,newText):
		self.distribs.rename_plugin(newText)
	
	def close_options_dialog(self,widget):
		self.distribs.close_options_dialog()
        
	def exit(self,window=None,event=None):
		os.system("kill -9 `ps aux | grep bash | grep ubukey | grep .sh | awk '{print $2}' |xargs`")
		os.system('killall -9 Xephyr')
		gtk.main_quit()
		
	def pkg(self,widget):
		self.vt.run_command('/bin/bash ' + data_path +'/scripts/dialog.sh')
        
if __name__ == "__main__":
    checkConf()
    gui = Ubukey_gui()
