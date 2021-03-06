#!/usr/bin/env python
#-*- coding: UTF-8 -*-

## own import
from constants import *
from functions import *
import time
from subprocess import Popen, PIPE
import fnmatch
import gobject

class NoSourceError(Exception): pass

class Distribs(object):
	def __init__(self,gui):
		self.ini = distribs_ini
		self.gui = gui
		self.username = os.environ.get('USERNAME')
		if not self.username:
			self.username = os.environ.get('USER')
			
	def start(self):
		self.chroot_script = os.path.join(scripts_path,'dochroot.sh')
		crun = os.popen("ps aux | grep '/bin/bash' | grep -e "+scripts_path+'/dochroot'" | grep -v 'grep'").read().strip()
		xrun = os.popen("ps aux | grep '/bin/bash' | grep -e "+scripts_path+'/startchroot'" | grep -v 'grep'").read().strip()
		if not crun == '' or not xrun == '':
			print _("a session is already running")
			return
		
		self.gui.run_btn_label.set_text(_("Stop"))
		self.gui.run_btn_img.set_from_stock(gtk.STOCK_STOP,gtk.ICON_SIZE_BUTTON)
		self.gui.run_btn_state = "started"
		self.gui.vt.log(_("distribution started"))
		#self.gui.notebook.set_current_page(1)
		try:
			self.gui.vt.run_command('gksu %s %s %s' % (self.chroot_script, self.gui.selected_dist_path, self.username))
			self.pid = os.popen("ps aux | grep -e 'dochroot' | grep -v 'grep'").read().strip()
			while 1:
				t = os.popen("ps aux | grep -e 'bash "+scripts_path+'/dochroot'" | grep -v 'grep'").read().strip()
				if not t == '':
					time.sleep(5)
				else:
					if self.gui.run_btn_state == "started":
						self.stop()
					break
		except:
			pass
		
	def stop(self):
		t=os.popen("ps aux | grep 'startchroot' | grep -v 'grep' | awk '{print $2}' | xargs").read().strip()
		if t and t != '':
			r = os.system("gksu 'kill -9 %s'" % t)
			if not r == 256:
				return
		self.gui.run_btn_label.set_text(_("Start"))
		self.gui.run_btn_img.set_from_stock(gtk.STOCK_MEDIA_PLAY,gtk.ICON_SIZE_BUTTON)
		self.gui.run_btn_state = "stopped"
		self.gui.vt.log(_("distribution stopped"))
		self.gui.notebook.set_current_page(0)
		self.gui.unlock_menu()
		self.gui.unlock_gui()
	
	def update_list(self):
		self.main_dist_path,dist_list,RESOLUTION = scan_dist_path()
		print _("updating distribution list...")
		self.parser = Parser(self.ini)
		for folder in dist_list:
			dist_conf = os.path.join(folder,'config')
			if not os.path.exists(dist_conf):
				print _("no configuration file found : %s") % dist_conf
				continue
			dist_name = os.path.basename(folder)
			if not self.parser.has_section(dist_name):
				self.parser.add_section(dist_name)
				dist_parser = Parser(dist_conf)
				for key,value in dist_parser.items(dist_name):
					self.parser.set(dist_name,key,value)
		write_ini(self.parser,self.ini)
		self.gui.dist_model.clear()
		for dist in self.parser.sections():
			self.add_model(dist)
			
	def add_model(self,dist):
		self.iter = self.gui.dist_model.append()
		self.gui.dist_model.set(self.iter,
		0, dist,
		1, os.path.join(self.main_dist_path,'distribs',dist),
		)
		
	def add_plugin_model(self,name,path):
		self.iter = self.gui.plugins_model.append()
		self.gui.plugins_model.set(self.iter,
		0, name,
		1, path,
		)
	
	def new_dist(self):
		self.create_script = os.path.join(scripts_path,'create_dist.sh')
		self.gui.vt.run_command('gksu /bin/bash %s %s %s' % (self.create_script,
															 self.main_dist_path,
															 self.username))
		self.update_list()
		
	def remove_dist(self):
		quest = yesno(_("remove a distribution"), _("Remove your distribution %s installed in :\n%s  ?") % (self.gui.selected_dist,self.gui.selected_dist_path))
		if quest == "No":
			return
		self.remove_script = os.path.join(scripts_path,'remove_dist.sh')
		self.gui.vt.run_command('gksu /bin/bash %s %s %s %s' % (self.remove_script,
														  self.gui.selected_dist,
														  self.gui.selected_dist_path, self.username))
		self.parser.remove_section(self.gui.selected_dist)
		write_ini(self.parser,self.ini)
		self.gui.dist_model.remove(self.gui.dist_iter)
		
	def export_dist(self):
		self.export_script = os.path.join(scripts_path,'export_dist.sh')
		self.gui.vt.run_command('gksu /bin/bash %s %s %s' % (self.export_script,
														  self.gui.selected_dist,
														  self.gui.selected_dist_path))
		
	def start_vbox(self):
		self.vbox_script = os.path.join(scripts_path,'vbox.sh')
		self.gui.vt.run_command('gksu /bin/bash %s %s %s' % (self.vbox_script,
														  self.gui.selected_dist,
														  self.gui.selected_dist_path))
		
	def gen_bootcd(self):
		self.bootcd_script = os.path.join(scripts_path,'mkbootcd.sh')
		self.gui.vt.run_command('gksu /bin/bash %s %s %s' % (self.bootcd_script,
														  self.gui.selected_dist,
														  self.gui.selected_dist_path))
		
	def clone_dist(self):
		self.clone_script = os.path.join(scripts_path,'clone_dist.sh')
		self.gui.vt.run_command('gksu /bin/bash %s %s %s %s' % (self.clone_script,
															 self.gui.selected_dist,
															 self.gui.selected_dist_path,
															 self.main_dist_path))
		self.update_list()
		
	def plugins_dialog(self):
		self.optwin = self.gui.plugins_dialog
		self.optwin.set_position("center")
		self.update_plugins_list()
		self.gui.plug_scroll.show_all()
		response = self.optwin.run()
		if response == gtk.RESPONSE_DELETE_EVENT or response == gtk.RESPONSE_CANCEL:
			self.optwin.hide()
			
	def update_plugins_list(self):
		self.gui.plugins_model.clear()
		for root, dirnames, filenames in os.walk(os.path.join(self.main_dist_path,'addons/custom')):
			for filename in fnmatch.filter(filenames, '*.sh'):
				self.add_plugin_model(filename, root)
			
	def rename_plugin(self,newText):
		plugpath=os.path.join(self.main_dist_path,'addons/custom')
		os.rename(self.gui.selected_plug_path,os.path.join(plugpath,newText))
		self.update_plugins_list()
	
	def delete_plug(self):
		try:
			print _("removing the plugin %s ") % self.gui.selected_plug_path
			os.remove(self.gui.selected_plug_path)
			self.gui.plugins_model.remove(self.gui.plug_iter)
		except:
			return
		
	def create_plug(self):
		print _("creating new plugin...")
		plugpath=os.path.join(self.main_dist_path,'addons/custom')
		if not os.path.exists(plugpath):
			os.makedirs(plugpath)
		plug = open(os.path.join(plugpath,'new.sh'), "w")
		plug.write ('''#!/bin/bash
###########
#
# Note:
# -----
# please always use "xterm -e" and/or zenity 
# to start/show your scripts 
#
###########
#
# Please add a description here, it will be viewable in the 
# ubukey addons manager under the chroot ! 

DESCRIPTION=""

############
#
# Your code here...







###################
# do not remove...
###################
kill -9 `ps aux | grep -e "hold" | grep -e [x]term | grep -e "/usr/share/ubukey/addons" | awk '{print $2}' | xargs`

''')
		plug.close()
		self.optwin.hide()
		nfile = os.path.join(self.main_dist_path,'addons/custom/new.sh')
		editor=os.popen("xdg-mime query default text/plain").read().replace('.desktop\n','')
		try:
			(pid,t,r,s) = gobject.spawn_async(['/usr/bin/%s' % editor, nfile],flags=gobject.SPAWN_DO_NOT_REAP_CHILD,standard_output = True, standard_error = True)
		except:
			return
		data=(nfile)
		gobject.child_watch_add(pid, self.task_done,data)
		
	def task_done(self,pid,ret,data):
		self.gui.warning_dialog('Please rename your plugin!')
		self.plugins_dialog()
		
	def edit_plug(self):
		print _("edit the plugin %s ") % self.gui.selected_plug_path
		editor=os.popen("xdg-mime query default text/plain").read().replace('.desktop\n','')
		os.system('/usr/bin/%s %s' % (editor,self.gui.selected_plug_path))
	
	def options_dialog(self):
		self.optswin = self.gui.options_dialog
		self.optswin.set_position("center")
		self.gui.resolution_entry.set_text(self.gui.resolution)
		response = self.optswin.run()
		
	def close_options_dialog(self):
		res = self.gui.resolution_entry.get_text()
		if res != self.gui.resolution:
			self.gui.resolution=res
			parser = Parser(conf_file)
			parser.set('ubukey', 'resolution', res)
			write_ini(parser,conf_file)
		self.gui.options_dialog.hide()
		
	def start_multiboot(self):
		self.mboot_script = os.path.join(scripts_path,'multiboot.sh')
		#drawarea_xid=self.gui.drawarea.get_property('window').xid
		#print "draw id: %s" % drawarea_xid
		self.gui.vt.run_command('gksu /bin/bash %s %s' % (self.mboot_script,
								   self.username))
		#winid=os.popen("xwininfo -name MultiSystem | grep 'Window id' | awk '{print $4}'").read().strip()
		#print "MultiSystem window id : %s" % winid
	
	def open_source_folder(self):
		print _("Opening folder %s") % self.gui.selected_dist_path
		os.system("xdg-open %s" % self.gui.selected_dist_path)
	
	
                                
