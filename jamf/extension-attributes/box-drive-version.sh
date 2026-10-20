#!/bin/bash
#
# Title:            Box Drive Version
# Description:      Reports the installed Box Drive version (CFBundleVersion).
# Usage/Context:    Jamf Pro Extension Attribute (Data Type: String, Input: Script).
# Jamf Parameters:  None (extension attributes do not receive script parameters).
# Requirements:     macOS 11+.
# Author:           Angrod (https://github.com/Angrod)
#

infoPlist="/Applications/Box.app/Contents/Info.plist"

if [[ -f "$infoPlist" ]]; then
    echo "<result>$(/usr/bin/defaults read "$infoPlist" CFBundleVersion 2>/dev/null)</result>"
else
    echo "<result>Not Installed</result>"
fi
exit 0
