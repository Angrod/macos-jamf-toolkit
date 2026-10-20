#!/bin/bash
#
# Title:            Ensure Management Account Exists
# Description:      Self-healing check: if the local IT/management account is
#                   missing, call the Jamf policy that creates it.
# Usage/Context:    Jamf Pro policy script (recurring check-in).
# Jamf Parameters:
#   $4  Management account short name                                 [required]
#   $5  Custom trigger of the policy that creates the account         [required]
# Requirements:     macOS 11+; run as root; Jamf Pro agent.
# Author:           Angrod (https://github.com/Angrod)
#

log() { echo "$(/bin/date '+%Y-%m-%d %H:%M:%S') | $*"; }

account="${4:-}"
trigger="${5:-}"

if [[ -z "$account" || -z "$trigger" || "$account" == "[INSERT_"* || "$trigger" == "[INSERT_"* ]]; then
    log "ERROR: Parameters 4 (account) and 5 (policy trigger) are required."
    exit 1
fi

if /usr/bin/dscl . -read "/Users/$account" RecordName &>/dev/null; then
    log "'$account' exists. Nothing to do."
    exit 0
fi

log "'$account' is missing. Running policy trigger '$trigger'."
/usr/local/bin/jamf policy -event "$trigger"

if /usr/bin/dscl . -read "/Users/$account" RecordName &>/dev/null; then
    log "'$account' created."
    exit 0
fi

log "ERROR: '$account' still missing after running '$trigger'."
exit 1
