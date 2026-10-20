#!/bin/bash
#
# Title:            Re-enable Printer Queues
# Description:      Finds printer queues that CUPS has paused (disabled), cancels
#                   their stuck jobs and re-enables them. A one-click Self Service
#                   fix for "printer is paused" tickets.
# Usage/Context:    Jamf Pro policy script (Self Service remediation).
# Jamf Parameters:  None.
# Requirements:     macOS 11+; run as root.
# Author:           Angrod (https://github.com/Angrod)
#

log() { echo "$(/bin/date '+%Y-%m-%d %H:%M:%S') | $*"; }

disabledPrinters=$(/usr/bin/lpstat -p 2>/dev/null | /usr/bin/awk '/disabled/ { print $2 }')

if [[ -z "$disabledPrinters" ]]; then
    log "No disabled printer queues found."
    exit 0
fi

while IFS= read -r printer; do
    /usr/bin/cancel -a "$printer"
    /usr/sbin/cupsenable "$printer"
    log "Cleared and re-enabled $printer"
done <<< "$disabledPrinters"

stillDisabled=$(/usr/bin/lpstat -p 2>/dev/null | /usr/bin/awk '/disabled/ { print $2 }')
if [[ -n "$stillDisabled" ]]; then
    log "ERROR: Still disabled: $stillDisabled"
    exit 1
fi

log "All printer queues enabled."
exit 0
