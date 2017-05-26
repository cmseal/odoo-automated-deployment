#!/bin/bash

###### BASIC INSTRUCTIONS ######
#
# 1) Set the four script variables below
#
# 2) Copy a single db backup ending either .bz2 or .gz to ~/ for root
#
# 3) Run: chmod +x odoo_auto_install.sh
#
# 4) Run: ./odoo_auto_install.sh
#
# 5) After the server disconnects you to reboot, reconnect but as the odoo user
#
# 6) Run: ./odoo_first_login.sh in the Odoo user folder
#
# 7) The automated process will continue, and complete when 'setup_complete' file appears in Odoo user folder
#
#    At this point, Odoo is setup and started as a service (service odoo start|stop|reload)
#
#    The main Odoo interface will be on: http://<vm_ip_address>
#
#    The mobile interface will be on: http://<vm_ip_address>:81
#
#    Logging is to /var/log/odoo/odoo.log
#
#    Technical information is in README.md, if you've not used this before
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

	# Check fields are completed above and a db is present for restoring
	if test "$unipart_username" = "" || test "$project_repo_name" = "" || test "$vm_ip_address" = ""; then
		echo "Ensure the first three script variables have been edited in this file, then re-run it"
		exit 1;
	fi
	
	if [[ -f ~/*.gz && -f ~/*.bz2 ]]; then
		echo "No db backup found. Copy a odoo*.gz or odoo*.bz2 and try again."
		exit 1;
	fi
	
	# Update Ubuntu
	apt-get update
	apt-get dist-upgrade --assume-yes
	
	# Create Odoo user and associated permissions
	adduser odoo --disabled-password --gecos ""
	echo "odoo:Unipart" | chpasswd
	usermod -aG sudo odoo
	echo "%sudo	ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
	
	# Move files to Odoo home for second phase
	mv ~/odoo-automated-deployment/*.* /home/odoo/
	rmdir odoo-automated-deployment
	mv ~/*.bz2 /home/odoo/
	mv ~/*.gz /home/odoo/
	if [ -f ~/.ssh/authorized_keys ]; then
		head -n 7 ~/.ssh/authorized_keys > /home/odoo/user_pub_key
	fi
	
	# Setup second phase automatically and reboot
	echo "@reboot /home/odoo/odoo_auto_install.sh" > cron
	crontab -u odoo cron
	reboot
fi

# Second phase
if [ "$user" == "odoo" ]; then

	# Setup access to login as Odoo
	mkdir ~/.ssh
	if [ -f ~/user_pub_key ]; then
		head -n 7 ~/user_pub_key > ~/.ssh/authorized_keys
		sudo rm ~/user_pub_key
		chmod 600 ~/.ssh/authorized_keys
	fi
	ssh-keyscan git.unipart.io > ~/.ssh/known_hosts
	chmod 600 ~/.ssh/known_hosts
	chmod 700 ~/.ssh

	# Prep third phase
	sudo chmod +x odoo_first_login.sh
	 
fi
