#!/bin/bash
#
# Title:            Reset Software Update Daemon
# Description:      Clears the local Software Update preferences and restarts
#                   softwareupdated. Fixes Macs stuck on "Checking for updates"
#                   or showing stale/phantom updates. Managed settings from
#                   configuration profiles are re-applied automatically.
# Usage/Context:    Jamf Pro policy script (Self Service remediation).
# Jamf Parameters:  None.
# Requirements:     macOS 11+; run as root.
# Author:           Angrod (https://github.com/Angrod)
#

log() { echo "$(/bin/date '+%Y-%m-%d %H:%M:%S') | $*"; }

suPlist="/Library/Preferences/com.apple.SoftwareUpdate.plist"

if [[ -f "$suPlist" ]]; then
    /usr/bin/defaults delete "$suPlist" &>/dev/null
    /bin/rm -f "$suPlist"
    log "Removed $suPlist"
fi

/bin/sleep 1
if /bin/launchctl kickstart -k system/com.apple.softwareupdated; then
    log "softwareupdated restarted."
    exit 0
fi

log "ERROR: Could not restart softwareupdated."
exit 1
