#!/bin/bash
#
# Title:            Microsoft AutoUpdate Present
# Description:      Reports whether Microsoft AutoUpdate (MAU) is installed.
#                   Pairs with jamf/policy-scripts/remove-microsoft-autoupdate.sh.
# Usage/Context:    Jamf Pro Extension Attribute (Data Type: String, Input: Script).
# Jamf Parameters:  None (extension attributes do not receive script parameters).
# Requirements:     macOS 11+.
# Author:           Angrod (https://github.com/Angrod)
#

if [[ -e "/Library/Application Support/Microsoft/MAU2.0/Microsoft AutoUpdate.app" ]]; then
    echo "<result>True</result>"
else
    echo "<result>False</result>"
fi
exit 0
