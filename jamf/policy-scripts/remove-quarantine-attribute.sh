#!/bin/bash
#
# Title:            Remove Quarantine Attribute
# Description:      Recursively strips the com.apple.quarantine attribute from an
#                   app so users aren't shown the "downloaded from the Internet"
#                   prompt for software IT has already vetted and deployed.
# Usage/Context:    Jamf Pro policy script (run after an app install).
# Jamf Parameters:
#   $4  App name in /Applications (e.g. "VLC" or "VLC.app") or a full path [required]
# Requirements:     macOS 11+; run as root. Only use on apps you trust:
#                   Gatekeeper's notarization check still applies.
# Author:           Angrod (https://github.com/Angrod)
#

log() { echo "$(/bin/date '+%Y-%m-%d %H:%M:%S') | $*"; }

target="${4:-}"
if [[ -z "$target" ]]; then
    log "ERROR: Parameter 4 (app name or path) is required."
    exit 1
fi
if [[ "$target" != /* ]]; then
    target="/Applications/${target%.app}.app"
fi
if [[ ! -e "$target" ]]; then
    log "ERROR: $target not found."
    exit 1
fi

if /usr/bin/xattr -dr com.apple.quarantine "$target"; then
    log "Removed quarantine attribute from $target"
    exit 0
fi

log "ERROR: Failed to clear the quarantine attribute on $target"
exit 1
