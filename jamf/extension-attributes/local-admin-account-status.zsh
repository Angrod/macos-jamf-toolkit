#!/bin/zsh
#
# Title:            Local Admin Account Status
# Description:      Reports whether a named local admin account exists, whether it
#                   is hidden, and whether it holds a SecureToken.
#                   Example result: "Exists (it-admin), hidden, Secure Token enabled"
# Usage/Context:    Jamf Pro Extension Attribute (Data Type: String, Input: Script).
# Jamf Parameters:  None (extension attributes do not receive script parameters).
#                   Set adminAccount below before uploading to Jamf Pro.
# Requirements:     macOS 11+ (APFS / SecureToken).
# Author:           Angrod (https://github.com/Angrod)
#

adminAccount="[INSERT_ADMIN_USER]"

if [[ -z "$adminAccount" || "$adminAccount" == "[INSERT_"* ]]; then
    echo "<result>Not configured (set adminAccount in the EA script)</result>"
    exit 0
fi

if ! /usr/bin/dscl . -read "/Users/$adminAccount" RecordName &>/dev/null; then
    echo "<result>Not exists ($adminAccount)</result>"
    exit 0
fi

if [[ "$(/usr/bin/dscl . -read "/Users/$adminAccount" IsHidden 2>/dev/null)" == *": 1"* ]]; then
    hideStatus="hidden"
else
    hideStatus="unhidden"
fi

if [[ "$(/usr/sbin/sysadminctl -secureTokenStatus "$adminAccount" 2>&1)" == *"ENABLED"* ]]; then
    secureTokenStatus="Secure Token enabled"
else
    secureTokenStatus="Secure Token disabled"
fi

echo "<result>Exists ($adminAccount), $hideStatus, $secureTokenStatus</result>"
exit 0
