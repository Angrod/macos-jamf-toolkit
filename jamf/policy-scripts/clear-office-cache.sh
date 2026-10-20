#!/bin/bash
#
# Title:            Clear Microsoft Office Cache
# Description:      Quits Word, Excel, PowerPoint and Outlook, then clears their
#                   container caches and Office add-in (Wef) caches for the
#                   logged-in user. A common fix for add-ins that won't load and
#                   apps that hang on launch.
# Usage/Context:    Jamf Pro policy script (Self Service remediation).
# Jamf Parameters:  None.
# Requirements:     macOS 11+; Microsoft 365 apps; run as root with a user logged in.
# Author:           Angrod (https://github.com/Angrod)
#

log() { echo "$(/bin/date '+%Y-%m-%d %H:%M:%S') | $*"; }

currentUser=$(/usr/sbin/scutil <<< "show State:/Users/ConsoleUser" | /usr/bin/awk '/Name :/ && ! /loginwindow/ { print $3 }')
if [[ -z "$currentUser" ]]; then
    log "ERROR: No user logged in."
    exit 1
fi
userHome=$(/usr/bin/dscl . -read "/Users/$currentUser" NFSHomeDirectory | /usr/bin/awk '{ print $2 }')

for app in "Microsoft Word" "Microsoft Excel" "Microsoft PowerPoint" "Microsoft Outlook"; do
    if /usr/bin/pkill -x "$app"; then
        log "Quit $app."
    fi
done
/bin/sleep 2

for container in Word Excel PowerPoint Outlook; do
    base="$userHome/Library/Containers/com.microsoft.$container/Data/Library"
    for cache in "$base/Caches" "$base/Application Support/Microsoft/Office/16.0/Wef"; do
        if [[ -d "$cache" ]]; then
            /bin/rm -rf "$cache"
            log "Removed $cache"
        fi
    done
done

log "Office caches cleared for $currentUser."
exit 0
