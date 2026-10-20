#!/bin/bash
#
# Title:            AppleCare Warranty Expiration
# Description:      Reads the coverage end date that macOS caches in the console
#                   user's NewDeviceOutreach *_Warranty plist(s) and reports the
#                   first one found as YYYY-MM-DD.
# Usage/Context:    Jamf Pro Extension Attribute (Data Type: Date, Input: Script).
# Jamf Parameters:  None (extension attributes do not receive script parameters).
# Requirements:     macOS 12+ with a user logged in who has opened the Coverage
#                   section of System Settings at least once (populates the cache).
# Author:           Angrod (https://github.com/Angrod)
#

currentUser=$(/usr/sbin/scutil <<< "show State:/Users/ConsoleUser" | /usr/bin/awk '/Name :/ && ! /loginwindow/ { print $3 }')
if [[ -z "$currentUser" ]]; then
    echo "<result>No user logged in</result>"
    exit 0
fi

userHome=$(/usr/bin/dscl . -read "/Users/$currentUser" NFSHomeDirectory | /usr/bin/awk '{ print $2 }')
outreachDir="$userHome/Library/Application Support/com.apple.NewDeviceOutreach"

shopt -s nullglob
for warrantyFile in "$outreachDir"/*_Warranty*; do
    expires=$(/usr/bin/defaults read "$warrantyFile" coverageEndDate 2>/dev/null)
    if [[ "$expires" =~ ^[0-9]+$ ]]; then
        echo "<result>$(/bin/date -r "$expires" '+%Y-%m-%d')</result>"
        exit 0
    fi
done

echo "<result>No Warranty File found</result>"
exit 0
