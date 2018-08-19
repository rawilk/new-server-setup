#!/usr/bin/env bash
# Author: Randall Wilk <randall@randallwilk.com>

##############################################
# Include the given github shell script.
# Globals:
#    None
# Arguments:
#   Script Path, Output File (Optional)
# Returns:
#   None
#############################################
function include_github_script() {
    local BASE=https://raw.githubusercontent.com/rawilk/new-server-setup/master/
    local OUTPUT=/root/includes.sh
    
    if [[ $2 != '' ]]; then
        local OUTPUT="$2"
    fi

    local URI="$BASE$1"
    echo "Curl to: ${URI}"
    curl ${URI} >> ${OUTPUT}
}