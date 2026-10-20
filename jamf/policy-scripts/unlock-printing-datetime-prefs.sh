#!/bin/bash
#
# Title:            Unlock Printing and Date & Time Settings
# Description:      Lets standard users change printer and Date & Time settings
#                   without an admin password, by marking those two
#                   authorization rights as "shared".
# Usage/Context:    Jamf Pro policy script (enrollment).
# Jamf Parameters:  None.
# Requirements:     macOS 11+; run as root.
# Author:           Angrod (https://github.com/Angrod)
#

log() { echo "$(/bin/date '+%Y-%m-%d %H:%M:%S') | $*"; }

workDir=$(/usr/bin/mktemp -d /private/tmp/authdb.XXXXXX)
trap '/bin/rm -rf "$workDir"' EXIT

status=0
for right in system.preferences.printing system.preferences.datetime; do
    rightPlist="$workDir/$right.plist"
    if ! /usr/bin/security authorizationdb read "$right" > "$rightPlist" 2>/dev/null; then
        log "ERROR: Could not read $right"
        status=1
        continue
    fi
    /usr/bin/defaults write "$rightPlist" shared -bool true
    if /usr/bin/security authorizationdb write "$right" < "$rightPlist" 2>/dev/null; then
        log "Unlocked $right for standard users."
    else
        log "ERROR: Could not write $right"
        status=1
    fi
done

exit "$status"
