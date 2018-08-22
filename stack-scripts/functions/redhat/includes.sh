#!/usr/bin/env bash
# Author: Randall Wilk <randall@randallwilk.com>

# Include the main `includes` script to easily include other scripts from the repo
curl -o /root/includes.sh -L https://raw.githubusercontent.com/rawilk/new-server-setup/master/stack-scripts/functions/common/includes.sh
. /root/includes.sh

# Pull in the functions needed for installation
include_github_script stack-scripts/functions/common/common.sh
include_github_script stack-scripts/functions/common/basic-setup.sh
include_github_script stack-scripts/functions/common/harden-server.sh
include_github_script stack-scripts/functions/redhat/setup-teardown.sh
include_github_script stack-scripts/functions/redhat/harden-server.sh
include_github_script stack-scripts/functions/redhat/users.sh
include_github_script stack-scripts/functions/redhat/utils.sh
include_github_script stack-scripts/functions/redhat/ftp.sh
include_github_script stack-scripts/functions/redhat/nginx.sh
include_github_script stack-scripts/functions/redhat/database.sh
include_github_script stack-scripts/functions/redhat/php.sh

# Finally, include the file created for the functions
. /root/stackfunctions.sh