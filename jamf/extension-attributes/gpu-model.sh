#!/bin/bash
#
# Title:            GPU Model
# Description:      Reports the GPU chipset model(s); multiple GPUs are comma-separated.
# Usage/Context:    Jamf Pro Extension Attribute (Data Type: String, Input: Script).
# Jamf Parameters:  None (extension attributes do not receive script parameters).
# Requirements:     macOS 11+.
# Author:           Angrod (https://github.com/Angrod)
#

gpus=$(/usr/sbin/system_profiler SPDisplaysDataType | /usr/bin/awk -F': ' '/Chipset Model/ { print $2 }' | /usr/bin/paste -sd ',' - | /usr/bin/sed 's/,/, /g')

echo "<result>${gpus:-Unknown}</result>"
exit 0
