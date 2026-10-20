#!/bin/bash
#
# Title:            Uptime (Days)
# Description:      Reports whole days since the last boot, computed from
#                   kern.boottime. Drives the restart-reminder Smart Group used by
#                   utilities-and-maintenance/uptime-check.sh.
# Usage/Context:    Jamf Pro Extension Attribute (Data Type: Integer, Input: Script).
# Jamf Parameters:  None (extension attributes do not receive script parameters).
# Requirements:     macOS 11+.
# Author:           Angrod (https://github.com/Angrod)
#

bootEpoch=$(/usr/sbin/sysctl -n kern.boottime | /usr/bin/awk -F'[ ,]' '{ print $4 }')
nowEpoch=$(/bin/date +%s)

if [[ "$bootEpoch" =~ ^[0-9]+$ ]]; then
    echo "<result>$(( (nowEpoch - bootEpoch) / 86400 ))</result>"
else
    echo "<result>0</result>"
fi
exit 0
