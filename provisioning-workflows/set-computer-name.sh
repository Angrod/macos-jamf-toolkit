#!/bin/bash
#
# Title:            Set Computer Name
# Description:      Sets ComputerName, HostName and LocalHostName, with an
#                   optional prefix (e.g. a site or department code), then updates
#                   inventory. HostName/LocalHostName default to a DNS-safe
#                   version of the ComputerName.
# Usage/Context:    Jamf Pro policy script (enrollment or Self Service).
# Jamf Parameters:
#   $4  ComputerName (friendly name)                                  [required]
#   $5  HostName              [optional, default: DNS-safe version of $7 + $4]
#   $6  LocalHostName (Bonjour)          [optional, default: same as HostName]
#   $7  Prefix prepended to all three names, e.g. "NYC-"              [optional]
# Requirements:     macOS 11+; run as root; Jamf Pro agent (for recon).
# Author:           Angrod (https://github.com/Angrod)
#

log() { echo "$(/bin/date '+%Y-%m-%d %H:%M:%S') | $*"; }

# LocalHostName only allows letters, digits and hyphens.
dns_safe() { echo "$1" | /usr/bin/sed -E 's/[[:space:]_]+/-/g; s/[^A-Za-z0-9-]//g; s/-+/-/g; s/^-+|-+$//g'; }

prefix="${7:-}"
computerName="${4:-}"
if [[ -z "$computerName" ]]; then
    log "ERROR: Parameter 4 (ComputerName) is required."
    exit 1
fi
computerName="${prefix}${computerName}"
hostName="${5:+${prefix}$5}"
hostName=$(dns_safe "${hostName:-$computerName}")
localHostName=$(dns_safe "${6:+${prefix}$6}")
localHostName="${localHostName:-$hostName}"

if [[ -z "$hostName" ]]; then
    log "ERROR: No DNS-safe characters left in the requested name."
    exit 1
fi

if ! /usr/sbin/scutil --set ComputerName "$computerName" \
    || ! /usr/sbin/scutil --set HostName "$hostName" \
    || ! /usr/sbin/scutil --set LocalHostName "$localHostName"; then
    log "ERROR: scutil failed to set one of the names."
    exit 1
fi

log "ComputerName=$computerName HostName=$hostName LocalHostName=$localHostName"
/usr/local/bin/jamf recon
exit 0
