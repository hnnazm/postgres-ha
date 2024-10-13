#!/bin/bash

set -euo pipefail  # Exit on error, unset variables as error, and pipefail
# set -x  # Uncomment this line for debugging to see command execution

# make sure that postgres user can run systemctl command
# allow postgres user to run systemctl (in visudo file)
# postgres ALL=(ALL) NOPASSWD: /bin/systemctl *

/usr/pgsql-16/bin/repmgr -f /etc/repmgr/16/repmgr.conf standby clone -F -h 103.209.157.50 -U repmgr

sudo systemctl start postgresql-16

/usr/pgsql-16/bin/repmgr -f /etc/repmgr/16/repmgr.conf standby register -F
