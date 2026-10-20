#!/bin/bash
#
# Title:            Remove Microsoft AutoUpdate
# Description:      Quits and removes Microsoft AutoUpdate (MAU 2.0) for
#                   environments that patch Office through Jamf/AutoPkg instead.
#                   Note: Office will no longer update itself afterwards.
# Usage/Context:    Jamf Pro policy script.
# Jamf Parameters:  None.
# Requirements:     macOS 11+; run as root.
# Author:           Angrod (https://github.com/Angrod)
#

log() { echo "$(/bin/date '+%Y-%m-%d %H:%M:%S') | $*"; }

mauDir="/Library/Application Support/Microsoft/MAU2.0"

if [[ ! -d "$mauDir" ]]; then
    log "MAU 2.0 not found. Nothing to do."
    exit 0
fi

/usr/bin/pkill -x "Microsoft AutoUpdate" &>/dev/null
/usr/bin/pkill -x "Microsoft Update Assistant" &>/dev/null

/bin/rm -rf "$mauDir"
if [[ -d "$mauDir" ]]; then
    log "ERROR: Could not remove $mauDir"
    exit 1
fi

log "Microsoft AutoUpdate removed."
exit 0
