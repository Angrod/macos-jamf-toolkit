#!/bin/bash
#
# Title:            Set Jamf End Username
# Description:      Assigns the computer to the logged-in user in Jamf Pro
#                   (User & Location > Username) so Smart Groups, scoping and
#                   directory lookups work. Optionally appends a domain suffix
#                   so the value matches your IdP's email-style usernames.
# Usage/Context:    Jamf Pro policy script (enrollment, login trigger).
# Jamf Parameters:
#   $4  Suffix to append, e.g. "@yourcompany.com"                     [optional]
# Requirements:     macOS 11+; run as root; Jamf Pro agent.
# Author:           Angrod (https://github.com/Angrod)
#

log() { echo "$(/bin/date '+%Y-%m-%d %H:%M:%S') | $*"; }

suffix="${4:-}"

currentUser=$(/usr/sbin/scutil <<< "show State:/Users/ConsoleUser" | /usr/bin/awk '/Name :/ && ! /loginwindow/ { print $3 }')
case "$currentUser" in
    ""|root|_mbsetupuser)
        log "No end user logged in. Skipping."
        exit 0
        ;;
esac

endUsername="${currentUser}${suffix}"
log "Setting Jamf end username to '$endUsername'."
if /usr/local/bin/jamf recon -endUsername "$endUsername"; then
    exit 0
fi

log "ERROR: jamf recon failed."
exit 1
