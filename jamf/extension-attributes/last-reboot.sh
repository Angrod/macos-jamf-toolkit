#!/bin/bash
#
# Title:            Last Reboot
# Description:      Reports the last boot time from kern.boottime in a format
#                   Jamf Pro can store as a Date (YYYY-MM-DD hh:mm:ss).
# Usage/Context:    Jamf Pro Extension Attribute (Data Type: Date, Input: Script).
# Jamf Parameters:  None (extension attributes do not receive script parameters).
# Requirements:     macOS 11+.
# Author:           Angrod (https://github.com/Angrod)
#

bootEpoch=$(/usr/sbin/sysctl -n kern.boottime | /usr/bin/awk -F'[ ,]' '{ print $4 }')

if [[ "$bootEpoch" =~ ^[0-9]+$ ]]; then
    echo "<result>$(/bin/date -r "$bootEpoch" '+%Y-%m-%d %H:%M:%S')</result>"
else
    echo "<result></result>"
fi
exit 0
