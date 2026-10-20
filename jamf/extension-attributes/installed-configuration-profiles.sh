#!/bin/bash
#
# Title:            Installed Configuration Profiles
# Description:      Lists the display names of every configuration profile
#                   installed on the Mac, one per line.
# Usage/Context:    Jamf Pro Extension Attribute (Data Type: String, Input: Script).
# Jamf Parameters:  None (extension attributes do not receive script parameters).
# Requirements:     macOS 11+; runs as root (Jamf default).
# Author:           Angrod (https://github.com/Angrod)
#

profileNames=$(/usr/bin/profiles -P -v 2>/dev/null | /usr/bin/awk -F'name: ' '/attribute: name:/ { print $2 }')

echo "<result>${profileNames:-None}</result>"
exit 0
