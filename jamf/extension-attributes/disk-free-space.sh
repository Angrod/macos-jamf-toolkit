#!/bin/bash
#
# Title:            Disk Free Space
# Description:      Reports free space on the boot volume as shown by diskutil
#                   (e.g. "123.4 GB"). On APFS this is the container free space.
# Usage/Context:    Jamf Pro Extension Attribute (Data Type: String, Input: Script).
# Jamf Parameters:  None (extension attributes do not receive script parameters).
# Requirements:     macOS 11+.
# Author:           Angrod (https://github.com/Angrod)
#

freeSpace=$(/usr/sbin/diskutil info / | /usr/bin/awk -F': *' '/Free Space|Available Space/ { split($2, a, " "); print a[1] " " a[2]; exit }')

echo "<result>${freeSpace:-Unknown}</result>"
exit 0
