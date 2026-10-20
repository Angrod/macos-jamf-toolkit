#!/bin/bash
#
# Title:            Install CrowdStrike Falcon
# Description:      Installs a cached Falcon sensor package and licenses it to
#                   your tenant with the Customer ID (CID), then confirms the
#                   sensor reports in.
# Usage/Context:    Jamf Pro policy script (run "After" the package cache step).
# Jamf Parameters:
#   $4  CrowdStrike Customer ID with checksum, e.g. "0123...ABCD-12"  [required]
#   $5  Installer package path         [optional, default: Waiting Room package]
# Requirements:     macOS 12+; run as root. Deploy the Falcon system extension,
#                   PPPC (Full Disk Access) and web content filter profiles first,
#                   or the sensor will install but not run.
# Author:           Angrod (https://github.com/Angrod)
#

log() { echo "$(/bin/date '+%Y-%m-%d %H:%M:%S') | $*"; }

customerId="${4:-}"
packagePath="${5:-/Library/Application Support/JAMF/Waiting Room/FalconSensorMacOS.pkg}"
falconctl="/Applications/Falcon.app/Contents/Resources/falconctl"

if [[ -z "$customerId" || "$customerId" == "[INSERT_"* ]]; then
    log "ERROR: Parameter 4 (CrowdStrike CID) is required."
    exit 1
fi
if [[ ! -f "$packagePath" ]]; then
    log "ERROR: Installer not found at $packagePath"
    exit 1
fi

log "Installing $(/usr/bin/basename "$packagePath")"
if ! /usr/sbin/installer -pkg "$packagePath" -target /; then
    log "ERROR: Falcon package install failed."
    exit 1
fi

log "Licensing sensor"
if ! "$falconctl" license "$customerId"; then
    log "ERROR: falconctl license failed (check the CID and that the sensor isn't already licensed)."
    exit 1
fi

/bin/sleep 5
if "$falconctl" stats &>/dev/null; then
    log "Falcon sensor installed and reporting."
    /bin/rm -f "$packagePath"
    exit 0
fi

log "ERROR: Falcon installed but 'falconctl stats' failed. Check the required profiles."
exit 1
