#!/bin/bash
#
# Title:            Allow Standard Users to Add Printers
# Description:      Nests a group (default: "staff", i.e. all local users) inside
#                   the lpadmin group so non-admins can add printers without an
#                   admin password.
# Usage/Context:    Jamf Pro policy script (Self Service or enrollment).
# Jamf Parameters:
#   $4  Group to nest inside lpadmin                   [optional, default: staff]
#       Use "everyone" to include directory/network users as well.
# Requirements:     macOS 11+; run as root.
# Author:           Angrod (https://github.com/Angrod)
#

log() { echo "$(/bin/date '+%Y-%m-%d %H:%M:%S') | $*"; }

group="${4:-staff}"

if /usr/sbin/dseditgroup -o checkmember -m "$group" lpadmin &>/dev/null; then
    log "'$group' is already a member of lpadmin. Nothing to do."
    exit 0
fi

if /usr/sbin/dseditgroup -o edit -n /Local/Default -a "$group" -t group lpadmin; then
    log "Added group '$group' to lpadmin."
    exit 0
fi

log "ERROR: Failed to add group '$group' to lpadmin."
exit 1
