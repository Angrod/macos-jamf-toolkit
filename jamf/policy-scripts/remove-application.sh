#!/bin/bash
#
# Title:            Remove Application
# Description:      Quits an app and deletes its bundle from /Applications.
#                   Handy for sandboxed / App Store apps that ship without an
#                   uninstaller. One generic script instead of one per app.
# Usage/Context:    Jamf Pro policy script.
# Jamf Parameters:
#   $4  App name, with or without ".app" (e.g. "Slack")              [required]
#   $5  Process name to quit, if different from the app name          [optional]
# Requirements:     macOS 11+; run as root.
# Author:           Angrod (https://github.com/Angrod)
#

log() { echo "$(/bin/date '+%Y-%m-%d %H:%M:%S') | $*"; }

appName="${4%.app}"
processName="${5:-$appName}"

if [[ -z "$appName" || "$appName" == *"/"* || "$appName" == "."* ]]; then
    log "ERROR: Parameter 4 must be an app name such as 'Slack' (no paths)."
    exit 1
fi

appPath="/Applications/${appName}.app"
if [[ ! -d "$appPath" ]]; then
    log "$appPath is not installed. Nothing to do."
    exit 0
fi

if /usr/bin/pkill -x "$processName"; then
    log "Quit $processName."
    /bin/sleep 2
fi

/bin/rm -rf "$appPath"
if [[ -e "$appPath" ]]; then
    log "ERROR: Could not remove $appPath"
    exit 1
fi

log "Removed $appPath"
exit 0
