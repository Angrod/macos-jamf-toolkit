#!/bin/bash
#
# Title:            Enable SSH for Admin Account
# Description:      Turns on Remote Login (SSH) and restricts it to a single
#                   account by rebuilding the com.apple.access_ssh group.
# Usage/Context:    Jamf Pro policy script.
# Jamf Parameters:
#   $4  Account allowed to use SSH (e.g. your IT admin account)      [required]
# Requirements:     macOS 11+; run as root. On macOS 13+ the calling process
#                   (Jamf) needs Full Disk Access for `systemsetup -setremotelogin`.
# Author:           Angrod (https://github.com/Angrod)
#

log() { echo "$(/bin/date '+%Y-%m-%d %H:%M:%S') | $*"; }

sshAccount="${4:-}"

if [[ -z "$sshAccount" || "$sshAccount" == "[INSERT_"* ]]; then
    log "ERROR: Parameter 4 (SSH account) is required."
    exit 1
fi
if ! /usr/bin/id "$sshAccount" &>/dev/null; then
    log "ERROR: Account '$sshAccount' does not exist on this Mac."
    exit 1
fi

if ! /usr/sbin/systemsetup -f -setremotelogin on; then
    log "ERROR: Could not enable Remote Login (check Full Disk Access for Jamf)."
    exit 1
fi
log "Remote Login enabled."

# Recreate the access group so only the named account is allowed in.
/usr/sbin/dseditgroup -o delete -t group com.apple.access_ssh &>/dev/null
/usr/sbin/dseditgroup -o create -q com.apple.access_ssh
if /usr/sbin/dseditgroup -o edit -a "$sshAccount" -t user com.apple.access_ssh; then
    log "SSH access restricted to '$sshAccount'."
    exit 0
fi

log "ERROR: Failed to add '$sshAccount' to com.apple.access_ssh."
exit 1
