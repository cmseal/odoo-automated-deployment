# UDES/Odoo Automated Deployment
This repo creates a set of conf files and bash scripts, in order to minimise user effort for deployment of Odoo with UDES project modules.

The end result is:
- Ubuntu updated
- Odoo user created with SSH key/password access
- Odoo repo pulled
- UDES project repos pulled
- PostgreSQL setup
- Apache and PHP 7 installed
- Apache configured for main UDES proxy and mobile sites
- Odoo setup as a service
- DB backup restored
- Odoo started

This works for either a locally hosted development instance, or a testing/UAT instance that is cloud hosted, on Ubuntu Server 16.04 x64.

Additionlly, the following is possible for developer convenience:
- SFTP access via SSH key or Odoo user password
- Running Odoo directly, either via ./run_odoo.sh or ./odoo-bin... (once the service is stopped)

## How to use
1) ssh into your VM as root
2) scp a db backup into the root home folder, either .gz or .bz2
3) git clone this repo and go into the directory
4) edit odoo_auto_install.sh, and edit the variables:
  - unipart_username (this is your unix username, to pull from Unipart Digital git)
  - vm_ip_address (public IP for DigitalOcean, or local VM IP for laptop hosted)
5) chmod +x odoo_auto_install.sh
6) ./odoo_auto_install.sh
7) After the script reboots the VM, wait a few seconds then reconnect as odoo@ instead of root@
8) ./odoo_first_run.sh (it's already executable)

This will do everything, to the point that the script finishes and Odoo is running as a service (see below for details).

## Technical Setup
The following are the specifics for the setup, once the scripts have been completed;
- Odoo user pw: Unipart
- Apache is setup with proxy for main interface (like production)
- Proxy has longpolling enabled for 4 workers (helpful for UAT testing speed)
- Workers configured for a machine with 1GB RAM and 2 CPU cores
- Mobile interface is on the same IP, but port 81
- Odoo service logs to /var/log/odoo/odoo.log
- Odoo service commands:
  - sudo systemctl start odoo.service
  - sudo systemctl stop odoo.service
  - sudo systemctl restart odoo.service
  - sudo systemctl status odoo.service
