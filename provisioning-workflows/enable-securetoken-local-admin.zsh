#!/bin/zsh
#
# Title:            Enable SecureToken for Local Admin
# Description:      Grants a SecureToken to a local admin using its own
#                   credentials. Only works when the Mac has no SecureToken
#                   holders yet (e.g. the admin is created before the first user
#                   logs in). Otherwise use grant-securetoken.sh.
# Usage/Context:    Jamf Pro policy script (enrollment).
# Jamf Parameters:
#   $4  Local admin username, Base64-encoded                          [required]
#   $5  Local admin password, Base64-encoded                          [required]
#       Base64 only keeps the value from being readable at a glance in the
#       policy view; it is NOT encryption. Restrict who can view the policy.
# Requirements:     macOS 11+ on APFS; run as root.
# Author:           Angrod (https://github.com/Angrod)
#

log() { echo "$(/bin/date '+%Y-%m-%d %H:%M:%S') | $*"; }

if [[ -z "${4:-}" || -z "${5:-}" ]]; then
    log "ERROR: Parameters 4 and 5 (Base64 username/password) are required."
    exit 1
fi

username=$(echo "$4" | /usr/bin/base64 -d 2>/dev/null)
password=$(echo "$5" | /usr/bin/base64 -d 2>/dev/null)
if [[ -z "$username" || -z "$password" ]]; then
    log "ERROR: Could not decode the Base64 parameters."
    exit 1
fi

if [[ "$(/usr/sbin/sysadminctl -secureTokenStatus "$username" 2>&1)" == *"ENABLED"* ]]; then
    log "SecureToken already enabled for '$username'."
    exit 0
fi

/usr/sbin/sysadminctl -adminUser "$username" -adminPassword "$password" \
    -secureTokenOn "$username" -password "$password" &>/dev/null
unset password

if [[ "$(/usr/sbin/sysadminctl -secureTokenStatus "$username" 2>&1)" == *"ENABLED"* ]]; then
    log "Enabled SecureToken for '$username'."
    exit 0
fi

log "ERROR: Could not enable SecureToken for '$username'. Check the credentials, or use grant-securetoken.sh if a token holder already exists."
exit 1
