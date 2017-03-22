#!/bin/bash

source /home/sfoorgn/.profile

chmod 755 /home/sfoorgn/thirdparty/install_sc-license.sh
sh /home/sfoorgn/thirdparty/install_sc-license.sh > sc-license_installation.log

mkdir -p /var/log/omninames
export OMNINAMES_LOGDIR=/var/log/omninames

/usr/local/bin/omniNames -start {{ OMNI_PORT }} -always &

chown spcorgn:sfoorgn -R /sarc/home
chown sfoorgn:sfoorgn -R /sarc/sfoorgn

chown sfoorgn:sfoorgn -R /home/sfoorgn
chown spcorgn:sfoorgn -R /home/sfoorgn/exe/asp
chown spcorgn:sfoorgn -R /home/spcorgn

/usr/bin/monit -c /etc/monit/monitrc
/usr/sbin/cron
/usr/sbin/rsyslogd

su - sfoorgn -c _simphoboot
chmod 664 /home/sfoorgn/.scllog
source /home/spcorgn/.profile
su - spcorgn -c "scl boot asp spcorgn; /home/spcorgn/services/StartServices.sh"

su - spcorgn -c "crontab /etc/cron.d/spcorgn_cron"
su - sfoorgn -c "crontab /etc/cron.d/sfoorgn_cron"

tail -f /dev/null	