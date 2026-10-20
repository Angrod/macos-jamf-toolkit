#!/bin/bash
#
# Title:            Install Rapid7 Insight Agent
# Description:      Runs the architecture-appropriate Rapid7 Insight Agent
#                   installer (arm64 or x86_64) with your install token, then
#                   verifies the agent binary is present. Skips Macs that
#                   already have the agent.
# Usage/Context:    Jamf Pro policy script (run after the installer scripts are
#                   deployed by a package).
# Jamf Parameters:
#   $4  Rapid7 install token, e.g. "us:xxxxxxxx-xxxx-..."             [required]
#   $5  Folder containing agent_installer-arm64.sh / -x86_64.sh
#                                     [optional, default: /Library/Management/rapid7]
# Requirements:     macOS 11+; run as root.
# Author:           Angrod (https://github.com/Angrod)
#

log() { echo "$(/bin/date '+%Y-%m-%d %H:%M:%S') | $*"; }

installToken="${4:-}"
installerDir="${5:-/Library/Management/rapid7}"
agentBinary="/opt/rapid7/ir_agent/ir_agent"

if [[ -z "$installToken" || "$installToken" == "[INSERT_"* ]]; then
    log "ERROR: Parameter 4 (install token) is required."
    exit 1
fi

if [[ -e "$agentBinary" ]]; then
    log "Rapid7 Insight Agent already installed. Nothing to do."
    exit 0
fi

if [[ "$(/usr/sbin/sysctl -in hw.optional.arm64)" == "1" ]]; then
    installer="$installerDir/agent_installer-arm64.sh"
else
    installer="$installerDir/agent_installer-x86_64.sh"
fi

if [[ ! -f "$installer" ]]; then
    log "ERROR: Installer not found at $installer"
    exit 1
fi

/bin/chmod u+x "$installer"
log "Running $(/usr/bin/basename "$installer")"
if ! "$installer" install_start --token "$installToken"; then
    log "ERROR: Rapid7 installer returned an error."
    exit 1
fi

if [[ -e "$agentBinary" ]]; then
    log "Rapid7 Insight Agent installed."
    exit 0
fi

log "ERROR: Installer finished but $agentBinary is missing."
exit 1
