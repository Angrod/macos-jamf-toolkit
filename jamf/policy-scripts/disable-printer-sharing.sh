#!/bin/bash
#
# Title:            Disable Printer Sharing
# Description:      Turns off CUPS printer sharing (a common CIS benchmark item)
#                   and verifies the change.
# Usage/Context:    Jamf Pro policy script (security baseline / remediation).
# Jamf Parameters:  None.
# Requirements:     macOS 11+; run as root.
# Author:           Angrod (https://github.com/Angrod)
#

log() { echo "$(/bin/date '+%Y-%m-%d %H:%M:%S') | $*"; }

/usr/sbin/cupsctl --no-share-printers

if /usr/sbin/cupsctl | /usr/bin/grep -q "_share_printers=0"; then
    log "Printer sharing is disabled."
    exit 0
fi

log "ERROR: Printer sharing is still enabled."
exit 1
