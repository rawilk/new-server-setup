#!/usr/bin/env bash
# Author: Randall Wilk <randall@randallwilk.com>

# Include the includes script to easily include other scripts from the repo
curl -o /root/includes.sh -L https://raw.githubusercontent.com/rawilk/new-server-setup/master/stack-scripts/functions/common/includes.sh
. /root/includes.sh

# Include the functions needed for installation

# Finally include the file created for the functions
. /root/stackfunctions.sh