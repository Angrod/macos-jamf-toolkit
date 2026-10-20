#!/bin/bash
#
# Title:            Uninstall Nessus Agent
# Description:      Unlinks the Tenable Nessus Agent from its manager, stops the
#                   service and removes its files, following Tenable's macOS
#                   agent removal steps.
# Usage/Context:    Jamf Pro policy script.
# Jamf Parameters:  None.
# Requirements:     macOS 11+; run as root.
# Author:           Angrod (https://github.com/Angrod)
#

log() { echo "$(/bin/date '+%Y-%m-%d %H:%M:%S') | $*"; /usr/bin/logger -t nessus-uninstall "$*"; }

nessuscli="/Library/NessusAgent/run/sbin/nessuscli"
daemonPlist="/Library/LaunchDaemons/com.tenablesecurity.nessusagent.plist"

if [[ ! -d "/Library/NessusAgent" && ! -f "$daemonPlist" ]]; then
    log "Nessus Agent not installed. Nothing to do."
    exit 0
fi

if [[ -x "$nessuscli" ]]; then
    "$nessuscli" agent unlink && log "Agent unlinked from manager."
fi

/bin/launchctl bootout system/com.tenablesecurity.nessusagent &>/dev/null \
    || /bin/launchctl remove com.tenablesecurity.nessusagent &>/dev/null
log "Service stopped."

for target in "/Library/NessusAgent" "$daemonPlist" "/Library/PreferencePanes/Nessus Agent Preferences.prefPane"; do
    if [[ -e "$target" ]]; then
        /bin/rm -rf "$target"
        log "Removed $target"
    fi
done

if [[ -d "/Library/NessusAgent" ]]; then
    log "ERROR: /Library/NessusAgent could not be removed."
    exit 1
fi

log "Nessus Agent removed."
exit 0
