#!/bin/bash
#
# Title:            Promote Current User to Admin
# Description:      Adds the logged-in user to the local admin group, e.g. for an
#                   approved developer exception. Pair with demote-local-admins.sh
#                   or a time-limited Self Service workflow to take it back.
# Usage/Context:    Jamf Pro policy script (scoped to approved users only).
# Jamf Parameters:  None.
# Requirements:     macOS 11+; run as root.
# Author:           Angrod (https://github.com/Angrod)
#

log() { echo "$(/bin/date '+%Y-%m-%d %H:%M:%S') | $*"; }

currentUser=$(/usr/sbin/scutil <<< "show State:/Users/ConsoleUser" | /usr/bin/awk '/Name :/ && ! /loginwindow/ { print $3 }')
if [[ -z "$currentUser" || "$currentUser" == "root" ]]; then
    log "ERROR: No user logged in."
    exit 1
fi

if /usr/sbin/dseditgroup -o checkmember -m "$currentUser" admin &>/dev/null; then
    log "$currentUser is already an admin."
    exit 0
fi

if /usr/sbin/dseditgroup -o edit -a "$currentUser" -t user admin; then
    log "Added $currentUser to the admin group."
    exit 0
fi

log "ERROR: Could not add $currentUser to the admin group."
exit 1
