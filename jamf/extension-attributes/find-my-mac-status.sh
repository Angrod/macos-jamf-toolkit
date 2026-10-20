#!/bin/bash
#
# Title:            Find My Mac Status
# Description:      Reports whether Find My Mac is enabled by checking NVRAM for
#                   the Find My token. Useful before reassigning or wiping a Mac
#                   (Activation Lock risk).
# Usage/Context:    Jamf Pro Extension Attribute (Data Type: String, Input: Script).
# Jamf Parameters:  None (extension attributes do not receive script parameters).
# Requirements:     macOS 11+.
# Author:           Angrod (https://github.com/Angrod)
#

if /usr/sbin/nvram -x -p | /usr/bin/grep -q "fmm-mobileme-token-FMM"; then
    echo "<result>Enabled</result>"
else
    echo "<result>Disabled</result>"
fi
exit 0
