#!/bin/bash
#
# Title:            Chip Architecture
# Description:      Reports "Apple Silicon" or "Intel". Uses hw.optional.arm64,
#                   which stays correct even when the caller runs under Rosetta 2.
# Usage/Context:    Jamf Pro Extension Attribute (Data Type: String, Input: Script).
# Jamf Parameters:  None (extension attributes do not receive script parameters).
# Requirements:     macOS 11+.
# Author:           Angrod (https://github.com/Angrod)
#

if [[ "$(/usr/sbin/sysctl -in hw.optional.arm64)" == "1" ]]; then
    echo "<result>Apple Silicon</result>"
else
    echo "<result>Intel</result>"
fi
exit 0
