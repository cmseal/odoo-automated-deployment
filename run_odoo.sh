#!/bin/bash

if [ -z "$STY" ] ; then
 echo "Warning, you are not in Screen; press Enter to continue anyway, or Ctrl-C to quit";
 read reply;
fi;

cd odoo
exec ./odoo-bin --database odoo --init mclaren,print,edi --xmlrpc-interface 127.0.0.1 --logfile=/var/log/odoo/odoo.log --log-level=debug_rpc --proxy-mode --workers=4 --limit-memory-hard=1073741824 --limit-memory-soft=912680550 --limit-request=8192 --limit-time-cpu=600  --limit-time-real=1200 --max-cron-threads=1
