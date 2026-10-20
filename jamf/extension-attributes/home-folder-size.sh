#!/bin/bash
#
# Title:            Home Folder Size
# Description:      Reads the per-folder home directory sizes cached by the
#                   companion policy script jamf/policy-scripts/write-home-folder-size.sh.
#                   Running du inside an EA would slow every inventory update, so the
#                   expensive work happens in a policy and the EA just reads the result.
# Usage/Context:    Jamf Pro Extension Attribute (Data Type: String, Input: Script).
# Jamf Parameters:  None (extension attributes do not receive script parameters).
#                   Keep plistDomain below in sync with $4 of the companion policy.
# Requirements:     macOS 11+; companion policy must have run at least once.
# Author:           Angrod (https://github.com/Angrod)
#

plistDomain="com.yourcompany.app"
dataFile="/Library/IT_Data/${plistDomain}.plist"

homeSize=""
if [[ -f "$dataFile" ]]; then
    homeSize=$(/usr/bin/defaults read "$dataFile" HomeFolderSize 2>/dev/null)
fi

echo "<result>${homeSize:-No Results Found}</result>"
exit 0
