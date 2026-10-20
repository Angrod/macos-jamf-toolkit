#!/bin/bash
#
# Title:            Rotate Local Admin Password
# Description:      Changes the password of one or two local admin accounts with
#                   sysadminctl (authenticating as the account itself, so its
#                   SecureToken and login keychain stay in sync), then verifies the
#                   new password works.
# Usage/Context:    Jamf Pro policy script. On Jamf Pro 10.46+ consider the
#                   built-in LAPS for the management account instead.
# Jamf Parameters:
#   $4  Account username                                              [required]
#   $5  Current password                                              [required]
#   $6  New password                                                  [required]
#   $7  Second account username                                       [optional]
#   $8  Second account current password                   [required if $7 set]
#   $9  Second account new password                       [required if $7 set]
# Requirements:     macOS 11+; run as root. Passwords are briefly visible in the
#                   process list while sysadminctl runs; restrict policy access.
# Author:           Angrod (https://github.com/Angrod)
#

log() { echo "$(/bin/date '+%Y-%m-%d %H:%M:%S') | $*"; }

rotate() {
    local account="$1" currentPassword="$2" newPassword="$3"
    if [[ -z "$account" || -z "$currentPassword" || -z "$newPassword" || "$account" == "[INSERT_"* ]]; then
        log "ERROR: Username, current password and new password are all required."
        return 1
    fi
    if ! /usr/bin/id "$account" &>/dev/null; then
        log "ERROR: Account '$account' does not exist."
        return 1
    fi
    /usr/sbin/sysadminctl -adminUser "$account" -adminPassword "$currentPassword" \
        -resetPasswordFor "$account" -newPassword "$newPassword" &>/dev/null
    if /usr/bin/dscl /Local/Default -authonly "$account" "$newPassword" &>/dev/null; then
        log "Password rotated for '$account'."
        return 0
    fi
    log "ERROR: Password rotation failed for '$account' (wrong current password?)."
    return 1
}

status=0
rotate "${4:-}" "${5:-}" "${6:-}" || status=1
if [[ -n "${7:-}" ]]; then
    /bin/sleep 2
    rotate "$7" "${8:-}" "${9:-}" || status=1
fi
exit "$status"
