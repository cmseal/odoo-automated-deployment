echo "Remove setup cron job"
touch cron-empty
crontab -u odoo cron-empty

echo "Clone project from git"
cd ~
##TODO:
git clone "$unipart_username"@git.unipart.io:/home/scm/"$project_repo_name".git

if test "$mobile_project_repo_name" != ""; then
	echo "Clone mobile from git"
	cd /home/odoo/
	##TODO:
	git clone "$unipart_username"@git.unipart.io:/home/scm/"$mobile_project_repo_name".git
fi

echo "Create Odoo 10 addon symlinks"
sudo mkdir -p ~/.local/share/Odoo/addons/10.0
ln -sf ~/"$project_repo_name"/odoo_addons/"$project_repo_name" ~/.local/share/Odoo/addons/10.0/
ln -sf ~/"$project_repo_name"/odoo_addons"$project_repo_name"_import ~/.local/share/Odoo/addons/10.0/
ln -sf ~/"$project_repo_name"/odoo_addons/print ~/.local/share/Odoo/addons/10.0/
ln -sf ~/"$project_repo_name"/odoo_addons/edi ~/.local/share/Odoo/addons/10.0/

echo "Setup PostgreSQL"
sudo apt-get install postgresql --assume-yes
##TODO can't do su here:
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
   wget -q -P /tmp/ http://download.gna.org/wkhtmltopdf/0.12/0.12.2/wkhtmltox-0.12.2_linux-trusty-amd64.deb
	 sudo apt-get --assume-yes install xfonts-75dpi
   sudo dpkg -i /tmp/wkhtmltox-0.12.2_linux-trusty-amd64.deb
   sudo rm /tmp/wkhtmltox-0.12.2_linux-trusty-amd64.deb
fi

echo "Update mobile config.php file"
sudo mv ~/config.php ~/mclaren/mobile/config.php
 
sudo service apache2 reload
  
echo "Start Odoo service and wait (first time running)"
sudo service odoo start
sleep 5m

echo "Stop Odoo service, drop the db and restore the one provided"
sudo service odoo stop
sleep 30s
dumpdb odoo

if [ ! -f ~/*.gz ]; then
	gunzip -ck *.gz | psql postgres
else
	bzcat *.bz2 | psql postgres
fi
	
echo "Start Odoo with restored db"
sudo service odoo start

sudo touch ~/setup_completed
echo "Script completed!"
