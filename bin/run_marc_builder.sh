#!/bin/bash
# The environment to run is passed in as the first command line argument
# Eg. the crontab entry for lyberapps-dev looks like

#
# Determine whether an existing robot process is currently running by checking
# for a temporary lock file
#


#
# Make sure the kerberos ticket and afs token are renewed
#
echo "renew-ticket for afs"
date
KRB5CCNAME=/tmp/kerb5.tkt KINIT_PROG=/usr/bin/aklog \
/usr/local/bin/k5start  -t -k /tmp/kerb5.tkt -H 60 -U -f \
/opt/app/lyberadmin/sulair-lyberservices

/opt/app/lyberadmin/common-accessioning/current/robots/etd_submit/build_symphony_marc.rb
