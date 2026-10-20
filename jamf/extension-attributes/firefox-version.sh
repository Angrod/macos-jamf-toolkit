#!/bin/bash
#
# Title:            Firefox Version
# Description:      Reports the version of the release-channel Firefox installed
#                   in /Applications (ignores Developer/Nightly builds).
# Usage/Context:    Jamf Pro Extension Attribute (Data Type: String, Input: Script).
# Jamf Parameters:  None (extension attributes do not receive script parameters).
# Requirements:     macOS 11+.
# Author:           Angrod (https://github.com/Angrod)
#

result="Not Installed"

shopt -s nullglob
for app in /Applications/Firefox*.app; do
    if /usr/bin/grep -q "mozilla-release" "$app/Contents/Resources/application.ini" 2>/dev/null; then
        result=$(/usr/bin/defaults read "$app/Contents/Info.plist" CFBundleShortVersionString 2>/dev/null)
    fi
done

echo "<result>$result</result>"
exit 0
