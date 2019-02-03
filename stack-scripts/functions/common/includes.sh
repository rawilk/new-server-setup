#!/usr/bin/env bash

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
    local OUTPUT=/root/stackfunctions.sh

    # Update the output file if one is provided
    if [[ $2 != '' ]]
    then
        local OUTPUT="$2"
    fi

    local URI="$BASE$1"

    # Append extra lines first if the file already has content
    if [ -s $OUTPUT ]
    then
        echo "" >> $OUTPUT
        echo "" >> $OUTPUT
    fi

    curl $URI >> $OUTPUT
}