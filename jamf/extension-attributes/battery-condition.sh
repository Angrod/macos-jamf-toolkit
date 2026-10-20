#!/bin/bash
#
# Title:            Battery Condition
# Description:      Reports the battery condition (e.g. "Normal",
#                   "Service Recommended") from system_profiler.
# Usage/Context:    Jamf Pro Extension Attribute (Data Type: String, Input: Script).
# Jamf Parameters:  None (extension attributes do not receive script parameters).
# Requirements:     macOS 11+. Desktops report "No Battery".
# Author:           Angrod (https://github.com/Angrod)
#

condition=$(/usr/sbin/system_profiler SPPowerDataType | /usr/bin/awk -F': ' '/Condition/ { print $2; exit }')

echo "<result>${condition:-No Battery}</result>"
exit 0
