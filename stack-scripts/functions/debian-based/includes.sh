#!/usr/bin/env bash
# Author: Randall Wilk <randall@randallwilk.com>

# Include the includes script to easily include other scripts from the repo
curl -o /root/includes.sh -L https://raw.githubusercontent.com/rawilk/new-server-setup/master/stack-scripts/functions/common/includes.sh
. /root/includes.sh

# Include the functions needed for installation
include_github_script stack-scripts/functions/common/common.sh
include_github_script stack-scripts/functions/common/basic-setup.sh
include_github_script stack-scripts/functions/common/harden-server.sh
include_github_script stack-scripts/functions/debian-based/setup-teardown.sh
include_github_script stack-scripts/functions/debian-based/harden-server.sh
include_github_script stack-scripts/functions/debian-based/users.sh

# Finally include the file created for the functions
. /root/stackfunctions.sh

# Determine if we are setting up an Ubuntu or Debian server
IS_UBUNTU=false

if [[ ${OS} == Ubuntu* ]]; then
    IS_UBUNTU=true
fi