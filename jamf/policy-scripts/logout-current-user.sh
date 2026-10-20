#!/bin/bash
#
# Title:            Log Out Current User
# Description:      Ends the logged-in user's GUI session (launchctl bootout).
#                   Unsaved work is lost, so pair it with a warning dialog.
# Usage/Context:    Jamf Pro policy script (e.g. after a jamfHelper warning).
# Jamf Parameters:  None ($3, the Jamf-supplied username, is used when present).
# Requirements:     macOS 11+; run as root.
# Author:           Angrod (https://github.com/Angrod)
#

log() { echo "$(/bin/date '+%Y-%m-%d %H:%M:%S') | $*"; }

currentUser="${3:-}"
if [[ -z "$currentUser" ]]; then
    currentUser=$(/usr/sbin/scutil <<< "show State:/Users/ConsoleUser" | /usr/bin/awk '/Name :/ && ! /loginwindow/ { print $3 }')
fi
if [[ -z "$currentUser" || "$currentUser" == "root" ]]; then
    log "No user logged in. Nothing to do."
    exit 0
fi

/bin/sleep 1
if /bin/launchctl bootout "gui/$(/usr/bin/id -u "$currentUser")"; then
    log "Logged out $currentUser."
    exit 0
fi

log "ERROR: Could not log out $currentUser."
exit 1
