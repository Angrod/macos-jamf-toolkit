#!/bin/bash
#
# Title:            Clear Jamf Waiting Room
# Description:      Deletes leftover cached packages from the Jamf Waiting Room
#                   (e.g. after a failed or abandoned "cache then install"
#                   policy) to reclaim disk space.
# Usage/Context:    Jamf Pro policy script (maintenance) or standalone with sudo.
# Jamf Parameters:  None.
# Requirements:     macOS 11+; run as root. Don't scope it to run at the same time
#                   as a policy that is caching a package.
# Author:           Angrod (https://github.com/Angrod)
#

log() { echo "$(/bin/date '+%Y-%m-%d %H:%M:%S') | $*"; }

waitingRoom="/Library/Application Support/JAMF/Waiting Room"

if [[ ! -d "$waitingRoom" ]]; then
    log "Waiting Room not found. Nothing to do."
    exit 0
fi

shopt -s nullglob dotglob
items=("$waitingRoom"/*)
if (( ${#items[@]} == 0 )); then
    log "Waiting Room is already empty."
    exit 0
fi

freed=$(/usr/bin/du -sh "$waitingRoom" | /usr/bin/awk '{ print $1 }')
/bin/rm -rf "${items[@]}"
log "Removed ${#items[@]} item(s), about $freed, from the Waiting Room."
exit 0
