#!/bin/bash
#
# Title:            Demote Local Admins
# Description:      Removes admin rights from every local user (UID 500-999)
#                   except the accounts you list. Refuses to run unless at least
#                   one of the kept accounts is currently an admin, so a Mac can
#                   never be left with no administrator.
# Usage/Context:    Jamf Pro policy script (least-privilege rollout).
# Jamf Parameters:
#   $4  Comma-separated accounts that keep admin rights,
#       e.g. "it-admin,jamf-mgmt"                                    [required]
# Requirements:     macOS 11+; run as root.
# Author:           Angrod (https://github.com/Angrod)
#

log() { echo "$(/bin/date '+%Y-%m-%d %H:%M:%S') | $*"; }

keepList="${4:-}"
if [[ -z "$keepList" || "$keepList" == *"[INSERT_"* ]]; then
    log "ERROR: Parameter 4 (accounts that keep admin) is required."
    exit 1
fi
IFS=',' read -r -a keepAccounts <<< "${keepList// /}"

is_admin() { /usr/sbin/dseditgroup -o checkmember -m "$1" admin &>/dev/null; }
is_kept() {
    local kept
    for kept in "${keepAccounts[@]}"; do
        [[ "$1" == "$kept" ]] && return 0
    done
    return 1
}

keptAdminFound=false
for kept in "${keepAccounts[@]}"; do
    is_admin "$kept" && keptAdminFound=true
done
if ! $keptAdminFound; then
    log "ERROR: None of [$keepList] is currently an admin. Aborting so the Mac keeps an administrator."
    exit 1
fi

demoted=0
while read -r user uid; do
    (( uid >= 500 && uid < 1000 )) || continue
    is_kept "$user" && continue
    is_admin "$user" || continue
    if /usr/sbin/dseditgroup -o edit -n /Local/Default -d "$user" -t user admin; then
        log "Removed admin rights from $user"
        demoted=$((demoted + 1))
    else
        log "ERROR: Could not demote $user"
    fi
done < <(/usr/bin/dscl . -list /Users UniqueID)

log "Done. $demoted account(s) demoted."
exit 0
