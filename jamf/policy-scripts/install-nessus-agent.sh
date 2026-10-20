#!/bin/bash
#
# Title:            Install Nessus Agent
# Description:      Installs a cached Tenable Nessus Agent DMG, then (re)links the
#                   agent to Tenable with your linking key, naming it
#                   "<ComputerName>_<console user>".
# Usage/Context:    Jamf Pro policy script (run "After" the package cache step).
# Jamf Parameters:
#   $4  Agent version in the cached DMG name, e.g. "10.4.1"
#       (expects "NessusAgent-<version>.dmg" in the Waiting Room)    [required]
#   $5  Tenable linking key                                           [required]
#   $6  Agent group(s), comma-separated                               [optional]
#   $7  Manager host                       [optional, default: cloud.tenable.com]
#   $8  Manager port                                     [optional, default: 443]
# Requirements:     macOS 11+; run as root.
# Author:           Angrod (https://github.com/Angrod)
# Credits:          Based on the Nessus Agent installation script by Caine Hörr
#                   (2016). Changes: parameterized key/groups/host, removed
#                   hard-coded values, exit-code checks, agent naming.
#

log() { echo "$(/bin/date '+%Y-%m-%d %H:%M:%S') | $*"; /usr/bin/logger -t nessus-install "$*"; }

agentVersion="${4:-}"
linkingKey="${5:-}"
agentGroups="${6:-}"
managerHost="${7:-cloud.tenable.com}"
managerPort="${8:-443}"
nessuscli="/Library/NessusAgent/run/sbin/nessuscli"
dmgPath="/Library/Application Support/JAMF/Waiting Room/NessusAgent-${agentVersion}.dmg"

if [[ -z "$agentVersion" || -z "$linkingKey" || "$linkingKey" == "[INSERT_"* ]]; then
    log "ERROR: Parameters 4 (agent version) and 5 (linking key) are required."
    exit 1
fi
if [[ ! -f "$dmgPath" ]]; then
    log "ERROR: $dmgPath not found."
    exit 1
fi

mountPoint=$(/usr/bin/mktemp -d /private/tmp/nessus.XXXXXX)
trap '/usr/bin/hdiutil detach "$mountPoint" -quiet -force &>/dev/null; /bin/rmdir "$mountPoint" &>/dev/null' EXIT

log "Mounting Nessus Agent $agentVersion"
if ! /usr/bin/hdiutil attach "$dmgPath" -nobrowse -noverify -quiet -mountpoint "$mountPoint"; then
    log "ERROR: Could not mount $dmgPath"
    exit 1
fi

log "Installing Nessus Agent"
if ! /usr/sbin/installer -pkg "$mountPoint/Install Nessus Agent.pkg" -target /; then
    log "ERROR: Nessus Agent package failed to install."
    exit 1
fi
if [[ ! -x "$nessuscli" ]]; then
    log "ERROR: nessuscli not found after install."
    exit 1
fi

if ! /bin/launchctl list com.tenablesecurity.nessusagent &>/dev/null; then
    log "ERROR: Nessus Agent service is not running."
    exit 1
fi

# Unlink first so upgrades and re-links don't fail on an existing link.
"$nessuscli" agent unlink &>/dev/null

consoleUser=$(/usr/bin/stat -f "%Su" /dev/console)
computerName=$(/usr/sbin/scutil --get ComputerName)
agentName="${computerName}_${consoleUser}"

linkArgs=(agent link --key="$linkingKey" --host="$managerHost" --port="$managerPort" --name="$agentName")
if [[ -n "$agentGroups" ]]; then
    linkArgs+=(--groups="$agentGroups")
fi

log "Linking agent '$agentName' to $managerHost"
if "$nessuscli" "${linkArgs[@]}"; then
    log "Nessus Agent installed and linked."
    /bin/rm -f "$dmgPath"
    exit 0
fi

log "ERROR: Agent installed but linking failed."
exit 1
