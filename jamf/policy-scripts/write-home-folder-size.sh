#!/bin/bash
#
# Title:            Write Home Folder Size
# Description:      Measures each top-level folder in the logged-in user's home
#                   and caches the result in a plist, which the companion EA
#                   (jamf/extension-attributes/home-folder-size.sh) reports.
#                   Keeping the slow `du` here keeps inventory updates fast.
# Usage/Context:    Jamf Pro policy script (e.g. weekly, at check-in).
# Jamf Parameters:
#   $4  Plist domain for the cached data  [optional, default: com.yourcompany.app]
#       Must match plistDomain in the companion EA.
# Requirements:     macOS 11+; run as root with a user logged in.
# Author:           Angrod (https://github.com/Angrod)
#

log() { echo "$(/bin/date '+%Y-%m-%d %H:%M:%S') | $*"; }

plistDomain="${4:-com.yourcompany.app}"
dataFolder="/Library/IT_Data"
dataFile="$dataFolder/${plistDomain}.plist"

currentUser=$(/usr/sbin/scutil <<< "show State:/Users/ConsoleUser" | /usr/bin/awk '/Name :/ && ! /loginwindow/ { print $3 }')
if [[ -z "$currentUser" ]]; then
    log "No user logged in. Skipping."
    exit 0
fi
userHome=$(/usr/bin/dscl . -read "/Users/$currentUser" NFSHomeDirectory | /usr/bin/awk '{ print $2 }')

sizes=$(/usr/bin/du -sh "$userHome"/* 2>/dev/null | /usr/bin/awk -F'\t' '{ n = split($2, p, "/"); print $1, p[n] }')

/bin/mkdir -p "$dataFolder"
if /usr/bin/defaults write "$dataFile" HomeFolderSize -string "$sizes"; then
    log "Cached home folder sizes for $currentUser in $dataFile"
    exit 0
fi

log "ERROR: Could not write $dataFile"
exit 1
