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
# 5) Wait about 10-15 minutes for the script to complete.
#
# 6) The automated process is complete when 'setup_complete' file appears in /home/odoo/
#
# 7) Run: ./run_odoo.sh from inside a Screen session
#
#    The main Odoo interface will be on: http://<vm_ip_address>
#
#    The mobile interface will be on: http://<vm_ip_address>/mobile
#
#    Logging is to /var/log/odoo/odoo.log 
#
######


## Script Variables ##

# Your unipart username for git access
unipart_username=""

# Project repo name to clone (minus .git), e.g. project_repo_name="mclaren"
project_repo_name=""

# VM IP Address (public IP for Digital Ocean, local VM IP for laptop hosted), e.g. vm_ip_address="127.0.0.1"
vm_ip_address=""

# Mobile project repo to clone (minus .git), e.g. mobile_project_repo_name="odoo_mobile"
mobile_project_repo_name=""

######  Please don't edit below this line  ######

user=`whoami`

if [ "$user" == "root" ]; then

	if test "$unipart_username" = "" || test "$project_repo_name" = "" || test "$vm_ip_address" = ""; then
		echo "Ensure the first three script variables have been edited in this file, then re-run it"
		exit 1;
	fi
	
	if [ ! -r "~/odoo*.gz" ] && [ ! -r "~/odoo*.bz2" ]; then
		echo "No db backup found. Copy a odoo*.gz or odoo*.bz2 and try again."
		exit 1;
	fi
	
	echo "Create Odoo user and associated permissions"
	adduser odoo --disabled-password --gecos ""
	echo "odoo:Unipart" | chpasswd
	usermod -aG sudo odoo
	echo "%sudo	ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
	cp ./odoo-automated-deployment/* /home/odoo/
	head -n 7 .ssh/authorized_keys > /home/odoo/user_pub_key
	echo "@reboot /home/odoo/odoo_auto_install.sh > /home/odoo/setup.log 2>&1" > cron
	crontab -u odoo cron
	reboot
fi

if [ "$user" == "odoo" ]; then

	echo "Setup access info"
	mkdir /home/odoo/.ssh
	ssh-keyscan git.unipart.io > /home/odoo/.ssh/known_hosts
	chmod 600 /home/odoo/.ssh/known_hosts	
	head -n 7 /home/odoo/user_pub_key > /home/odoo/.ssh/authorized_keys
	sudo rm /home/odoo/user_pub_key
	chmod 600 /home/odoo/.ssh/authorized_keys
	chmod 700 /home/odoo/.ssh

	echo "Update Ubuntu"
	sudo apt-get update
	sudo apt-get dist-upgrade --assume-yes

	echo "Clone Odoo from git"
	cd /home/odoo/
	git clone https://github.com/mcb30/odoo.git --depth 20 --branch import

	echo "Clone project from git"
	cd /home/odoo/
	##TODO:
	git clone "$unipart_username"@git.unipart.io:/home/scm/"$project_repo_name".git

	if test "$mobile_project_repo_name" != ""; then
		echo "Clone mobile from git"
		cd /home/odoo/
		##TODO:
		git clone "$unipart_username"@git.unipart.io:/home/scm/"$mobile_project_repo_name".git
	fi

	echo "Create Odoo 10 addon symlinks"
	sudo mkdir -p /home/odoo/.local/share/Odoo/addons/10.0
	ln -sf /home/odoo/mclaren/odoo_addons/mclaren /home/odoo/.local/share/Odoo/addons/10.0/
	ln -sf /home/odoo/mclaren/odoo_addons/mclaren_import /home/odoo/.local/share/Odoo/addons/10.0/
	ln -sf /home/odoo/mclaren/odoo_addons/print /home/odoo/.local/share/Odoo/addons/10.0/
	ln -sf /home/odoo/mclaren/odoo_addons/edi /home/odoo/.local/share/Odoo/addons/10.0/

	echo "Setup PostgreSQL"
	sudo apt-get install postgresql --assume-yes
	##TODO:
	su postgres sh -c "createuser -d -A $(whoami)"

	echo "Install python packages"
	sudo apt-get --assume-yes install python-passlib python-werkzeug python-lxml \
	python-dateutil python-tz python-babel python-psycopg2 python-yaml \
	python-pychart python-reportlab python-mako python-psutil \
	python-jinja2 python-docutils python-xlrd python-pypdf python-xlwt \
	python-decorator python-requests python-paramiko python-psycogreen \
	python-gevent python-ply node-less wkhtmltopdf apache2 php7.0 \
	libapache2-mod-php7.0 php7.0-xmlrpc

	echo "Fix wkhtmltopdf (which is shipped in a very old variant by Ubuntu/Debian)"
	if wkhtmltopdf --help | grep -q "Reduced Functionality"; then
	   echo "Fixing Wkhtmltopdf..."
	   wget -P /tmp/ http://download.gna.org/wkhtmltopdf/0.12/0.12.2/wkhtmltox-0.12.2_linux-trusty-amd64.deb
	   sudo apt-get --assume-yes install xfonts-75dpi
	   sudo dpkg -i /tmp/wkhtmltox-0.12.2_linux-trusty-amd64.deb
	   sudo rm /tmp/wkhtmltox-0.12.2_linux-trusty-amd64.deb
	fi

	echo "Setup Apache mods"
	sudo /etc/init.d/apache2 start
	sudo update-rc.d apache2 defaults
	sudo a2enmod proxy
	sudo a2enmod proxy_http
	sudo a2enmod proxy_ajp
	sudo a2enmod rewrite
	sudo a2enmod deflate
	sudo a2enmod headers
	sudo a2enmod proxy_balancer
	sudo a2enmod proxy_connect
	sudo a2enmod proxy_html

	#TODO:
	#Edit odoo mobile config.php to use localhost

	echo "Create and amend Apache .conf files"
	sudo mv vm_ip_address.conf /etc/apache2/sites-available/"$vm_ip_address".conf
	sudo mv vm_ip_address-mobile.conf /etc/apache2/sites-available/"$vm_ip_address"-mobile.conf
	sudo sed -i -e 's/vm_ip_address/"$vm_ip_address"/g' /etc/apache2/sites-available/"$vm_ip_address".conf
	sudo sed -i -e 's/vm_ip_address/"$vm_ip_address"/g' /etc/apache2/sites-available/"$vm_ip_address"-mobile.conf

	echo "Remove default Apache index and replace with redirect (just incase)"
	sudo rm /var/www/html/index.html
	sudp mv /home/odoo/index.html /var/www/html/index.html
	sudo sed -i -e 's/vm_ip_address/"$vm_ip_address"/g' /var/www/html/index.html

	echo "Make host directories to keep Apache happy"
	sudo mkdir /var/www/vhosts/"$vm_ip_address"
	sudo mkdir /var/www/vhosts/"$vm_ip_address"/httpdocs

	echo "Enable new Apache sites"
	sudo a2ensite "$vm_ip_address"
	sudo a2ensite "$vm_ip_address"-mobile
	sudo a2dissite 000-default
	sudo service apache2 reload

	echo "Make ./run_odoo.sh script"
	chmod +x /home/odoo/run_odoo.sh

	echo "Script completed!"
	sudo touch /home/odoo/setup_completed

fi

# TODO:
# setup script as odoo service
# auto run then stop odoo, drop default db, restore db backup
# edit odoo mobile config.php to use localhost
