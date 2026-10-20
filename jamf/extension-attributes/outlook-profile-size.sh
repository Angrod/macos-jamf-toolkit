#!/bin/bash
#
# Title:            Outlook Profile Size
# Description:      Reports the size of the console user's (legacy) Outlook profile
#                   folder: "Less than 5GB" or the size in GB. Helps spot users
#                   heading for mailbox/OneDrive sync problems.
# Usage/Context:    Jamf Pro Extension Attribute (Data Type: String, Input: Script).
# Jamf Parameters:  None (extension attributes do not receive script parameters).
# Requirements:     macOS 11+; Microsoft Outlook (legacy profile storage).
# Author:           Angrod (https://github.com/Angrod)
#

thresholdMB=5120

currentUser=$(/usr/sbin/scutil <<< "show State:/Users/ConsoleUser" | /usr/bin/awk '/Name :/ && ! /loginwindow/ { print $3 }')
if [[ -z "$currentUser" ]]; then
    echo "<result>No user logged in</result>"
    exit 0
fi

userHome=$(/usr/bin/dscl . -read "/Users/$currentUser" NFSHomeDirectory | /usr/bin/awk '{ print $2 }')
profileDir="$userHome/Library/Group Containers/UBF8T346G9.Office/Outlook/Outlook 15 Profiles"

if [[ ! -d "$profileDir" ]]; then
    echo "<result>No Outlook profile</result>"
    exit 0
fi

sizeMB=$(/usr/bin/du -ms "$profileDir" 2>/dev/null | /usr/bin/awk '{ print $1 }')

if (( sizeMB < thresholdMB )); then
    echo "<result>Less than 5GB</result>"
else
    echo "<result>$(/usr/bin/awk -v mb="$sizeMB" 'BEGIN { printf "%.2fGB", mb / 1024 }')</result>"
fi
exit 0
