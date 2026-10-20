#!/bin/bash
#
# Title:            Uninstall CylancePROTECT
# Description:      Silently uninstalls CylancePROTECT using the tenant's
#                   uninstall password, then updates inventory.
# Usage/Context:    Jamf Pro policy script (EDR migration).
# Jamf Parameters:
#   $4  Cylance uninstall password                                    [required]
# Requirements:     macOS 11+; run as root.
# Author:           Angrod (https://github.com/Angrod)
#

log() { echo "$(/bin/date '+%Y-%m-%d %H:%M:%S') | $*"; }

uninstallPassword="${4:-}"
uninstaller="/Applications/Cylance/Uninstall CylancePROTECT.app/Contents/MacOS/Uninstall CylancePROTECT"

if [[ ! -x "$uninstaller" ]]; then
    log "CylancePROTECT not detected. Nothing to do."
    exit 0
fi
if [[ -z "$uninstallPassword" ]]; then
    log "ERROR: Parameter 4 (uninstall password) is required."
    exit 1
fi

log "Uninstalling CylancePROTECT."
if ! "$uninstaller" --noui --password="$uninstallPassword"; then
    log "ERROR: Uninstaller returned an error."
    exit 1
fi

if [[ -d "/Applications/Cylance" ]]; then
    log "ERROR: /Applications/Cylance still present after uninstall."
    exit 1
fi

log "CylancePROTECT removed. Updating inventory."
/usr/local/bin/jamf recon
exit 0
