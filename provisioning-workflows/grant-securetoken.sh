#!/bin/bash
#
# Title:            Grant SecureToken
# Description:      Grants a SecureToken to a local admin account using another
#                   account that already holds one (e.g. after the first user
#                   logged in before the IT admin account existed).
# Usage/Context:    Jamf Pro policy script (remediation Smart Group based on
#                   local-admin-account-status.zsh).
# Jamf Parameters:
#   $4  Target account username, Base64-encoded                       [required]
#   $5  Target account password, Base64-encoded                       [required]
#   $6  Existing SecureToken holder username, Base64-encoded          [required]
#   $7  Existing SecureToken holder password, Base64-encoded          [required]
#       Base64 is obfuscation only, not encryption.
# Requirements:     macOS 11+ on APFS; run as root.
# Author:           Angrod (https://github.com/Angrod)
#

log() { echo "$(/bin/date '+%Y-%m-%d %H:%M:%S') | $*"; }

decode() { echo "$1" | /usr/bin/base64 -d 2>/dev/null; }

for param in "${4:-}" "${5:-}" "${6:-}" "${7:-}"; do
    if [[ -z "$param" ]]; then
        log "ERROR: Parameters 4-7 (Base64 credentials) are all required."
        exit 1
    fi
done

targetUser=$(decode "$4")
targetPass=$(decode "$5")
tokenUser=$(decode "$6")
tokenPass=$(decode "$7")

if [[ "$(/usr/sbin/sysadminctl -secureTokenStatus "$targetUser" 2>&1)" == *"ENABLED"* ]]; then
    log "'$targetUser' already has a SecureToken."
    exit 0
fi

log "Granting SecureToken to '$targetUser' using '$tokenUser'."
/usr/sbin/sysadminctl -secureTokenOn "$targetUser" -password "$targetPass" \
    -adminUser "$tokenUser" -adminPassword "$tokenPass" &>/dev/null
unset targetPass tokenPass

if [[ "$(/usr/sbin/sysadminctl -secureTokenStatus "$targetUser" 2>&1)" == *"ENABLED"* ]]; then
    log "SecureToken granted to '$targetUser'."
    exit 0
fi

log "ERROR: Could not grant a SecureToken to '$targetUser'. Check both sets of credentials."
exit 1
