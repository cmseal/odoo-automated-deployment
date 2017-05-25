# UDES/Odoo Automated Deployment
This repo creates a set of conf files and bash scripts, in order to minimise user effort for deployment of Odoo with UDES project modules.

The end result is:
- Ubuntu updated
- Odoo user created with SSH key access
- Odoo repo pulled
- UDES project repos pulled
- Odoo setup as a service
- PostgreSQL setup
- Apache and PHP 7 installed
- Apache configured for main UDES and mobile sites
- DB backup restored
- Odoo started

This works for either a locally hosted development instance, or a testing/UAT instance that is cloud hosted, on Ubuntu Server 16.04 x64.

Additionlly, the following is possible for developer convenience:
- SFTP access
- Running Odoo directly, once the service is stopped
