#!/bin/bash

###### READ ME FIRST ######
#
# This script does the following:
# 
#  1) Setup 'odoo' user and ssh your access for using it
#  2) REBOOT - so you'll get disconnected
#  3) Clone Odoo core
#  4) Clone project repo
#  5) Clone mobile project repo
#  6) Update Ubuntu
#  7) Install all python packages required
#  8) Setup PostgreSQL and user
#  9) Run Odoo core (for db setup), then exit
# 10) Drop the default db and restore the provided db
# 11) Install and setup Apache and PHP for multiple workers and mobile interface
# 12) Configure Apache vhosts for Odoo and Mobile interfaces
# 13) Create the run_odoo.sh script for use in Screen (or not, if you press Enter)
#
###### INSTRUCTIONS ######
#
# 1) Set the four script variables below
#
# 2) Copy a single custom db backup ending either .bz2 or .gz to ~/
#
# 3) Run: chmod +x odoo_auto_install.sh
#
# 4) Run: ./odoo_auto_install.sh
#
# 5) After the server disconnects you to reboot, reconnect but as the odoo user
#
# 6) The automated process will continue, and complete when 'setup_complete' file appears in /home/odoo/
#
#    At this point, Odoo is setup as a service (service odoo start|stop|reload)
#
#    The main Odoo interface will be on: http://<vm_ip_address>
#
#    The mobile interface will be on: http://<vm_ip_address>:81
#
#    Logging is to /var/log/odoo/odoo.log
#
#    You can manually run Odoo as normal, /home/odoo/odoo/odoo-bin..., as long as the service is stopped first
#
######


## Script Variables ##

# Your unipart username for git access
unipart_username="chrisseal"

# Project repo name to clone (minus .git), e.g. project_repo_name="mclaren"
project_repo_name="mclaren"

# VM IP Address (public IP for Digital Ocean, local VM IP for laptop hosted), e.g. vm_ip_address="127.0.0.1"
vm_ip_address="46.101.41.217"

# Mobile project repo to clone (minus .git), e.g. mobile_project_repo_name="odoo_mobile"
mobile_project_repo_name="odoo_mobile"

######  Please don't edit below this line  ######

user=`whoami`

if [ "$user" == "root" ]; then

	if test "$unipart_username" = "" || test "$project_repo_name" = "" || test "$vm_ip_address" = ""; then
		echo "Ensure the first three script variables have been edited in this file, then re-run it"
		exit 1;
	fi
	
	if [[ -f ~/*.gz && -f ~/*.bz2 ]]; then
		echo "No db backup found. Copy a odoo*.gz or odoo*.bz2 and try again."
		exit 1;
	fi
	
	echo "Update Ubuntu"
	apt-get update
	apt-get dist-upgrade --assume-yes
	
	echo "Create Odoo user and associated permissions"
	adduser odoo --disabled-password --gecos ""
	echo "odoo:Unipart" | chpasswd
	usermod -aG sudo odoo
	echo "%sudo	ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
	mv ~/odoo-automated-deployment/*.* /home/odoo/
	rmdir odoo-automated-deployment
	mv ~/*.bz2 /home/odoo/
	mv ~/*.gz /home/odoo/
	##TODO: if this doesn't exist, don't bother
	head -n 7 ~/.ssh/authorized_keys > /home/odoo/user_pub_key
	echo "@reboot /home/odoo/odoo_auto_install.sh > /home/odoo/setup.log 2>&1" > cron
	crontab -u odoo cron
	reboot
fi

if [ "$user" == "odoo" ]; then

	echo "Setup access info"
	mkdir ~/.ssh
	##TODO: if this doesn't exist, don't bother
	head -n 7 ~/user_pub_key > ~/.ssh/authorized_keys
	sudo rm ~/user_pub_key
	chmod 600 ~/.ssh/authorized_keys
	ssh-keyscan git.unipart.io > ~/.ssh/known_hosts
	chmod 600 ~/.ssh/known_hosts
	chmod 700 ~/.ssh

        #echo 'unipart_username='"$unipart_username"'; project_repo_name='"$project_repo_name"'; mobile_project_repo_name='"$mobile_project_repo_name"' | cat - odoo_first_login.sh > temp && mv temp odoo_first_login.sh
	sudo chmod +x odoo_first_login.sh
	 
fi


