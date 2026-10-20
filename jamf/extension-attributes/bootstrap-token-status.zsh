#!/bin/zsh
#
# Title:            Bootstrap Token Status
# Description:      Reports whether the Mac's Bootstrap Token is escrowed to MDM.
#                   Pairs with provisioning-workflows/escrow-bootstrap-token.zsh.
# Usage/Context:    Jamf Pro Extension Attribute (Data Type: String, Input: Script).
# Jamf Parameters:  None (extension attributes do not receive script parameters).
# Requirements:     macOS 10.15+ enrolled in an MDM that supports Bootstrap Token.
# Author:           Angrod (https://github.com/Angrod)
#

tokenStatus=$(/usr/bin/profiles status -type bootstraptoken 2>&1)

if [[ "$tokenStatus" == *"escrowed to server: YES"* ]]; then
    echo "<result>Escrowed</result>"
elif [[ "$tokenStatus" == *"supported on server: NO"* ]]; then
    echo "<result>Not supported by MDM</result>"
else
    echo "<result>Not escrowed</result>"
fi
exit 0
