#!/bin/bash
#
# Title:            Install If Missing
# Description:      Self-healing baseline check: if an app is missing, run the
#                   Jamf policy that installs it. One script, reused by a policy
#                   per app (Chrome, Slack, Zoom, Office apps...).
# Usage/Context:    Jamf Pro policy script (recurring check-in or enrollment).
# Jamf Parameters:
#   $4  App name in /Applications ("Google Chrome") or a full path    [required]
#   $5  Custom trigger of the policy that installs it ("chrome")      [required]
# Requirements:     macOS 11+; run as root; Jamf Pro agent.
# Author:           Angrod (https://github.com/Angrod)
#

log() { echo "$(/bin/date '+%Y-%m-%d %H:%M:%S') | $*"; }

appArg="${4:-}"
trigger="${5:-}"

if [[ -z "$appArg" || -z "$trigger" ]]; then
    log "ERROR: Parameters 4 (app) and 5 (policy trigger) are required."
    exit 1
fi
if [[ "$appArg" == /* ]]; then appPath="$appArg"; else appPath="/Applications/${appArg%.app}.app"; fi

if [[ -d "$appPath" ]]; then
    log "$appPath is installed. Nothing to do."
    exit 0
fi

log "$appPath is missing. Running policy trigger '$trigger'."
/usr/local/bin/jamf policy -event "$trigger"

if [[ -d "$appPath" ]]; then
    log "$appPath installed."
    exit 0
fi

log "ERROR: $appPath still missing after running '$trigger'."
exit 1
