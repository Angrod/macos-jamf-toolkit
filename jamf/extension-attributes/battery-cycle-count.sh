#!/bin/bash
#
# Title:            Battery Cycle Count
# Description:      Reports the battery cycle count from system_profiler.
# Usage/Context:    Jamf Pro Extension Attribute (Data Type: Integer, Input: Script).
# Jamf Parameters:  None (extension attributes do not receive script parameters).
# Requirements:     macOS 11+. Desktops return an empty result so the Integer
#                   field stays valid.
# Author:           Angrod (https://github.com/Angrod)
#

cycleCount=$(/usr/sbin/system_profiler SPPowerDataType | /usr/bin/awk -F': ' '/Cycle Count/ { print $2; exit }')

echo "<result>${cycleCount}</result>"
exit 0
