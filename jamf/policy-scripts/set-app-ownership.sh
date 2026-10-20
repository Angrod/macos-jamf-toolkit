#!/bin/bash
#
# Title:            Set App Ownership to Current User
# Description:      Changes ownership of an app in /Applications to the logged-in
#                   user (user:staff) and optionally opens it. Apps with their own
#                   updaters (Slack, Zoom, Chrome...) need this when installed by
#                   root, or self-updates fail for standard users.
# Usage/Context:    Jamf Pro policy script (run after the app install).
# Jamf Parameters:
#   $4  App bundle name, e.g. "Slack.app"                             [required]
#   $5  "no" to skip opening the app afterwards        [optional, default: open]
# Requirements:     macOS 11+; run as root with a user logged in.
# Author:           Angrod (https://github.com/Angrod)
#

log() { echo "$(/bin/date '+%Y-%m-%d %H:%M:%S') | $*"; }

appName="${4:-}"
openApp="${5:-yes}"

if [[ -z "$appName" || "$appName" == *"/"* ]]; then
    log "ERROR: Parameter 4 must be an app bundle name such as 'Slack.app'."
    exit 1
fi
appName="${appName%.app}.app"
appPath="/Applications/$appName"
if [[ ! -d "$appPath" ]]; then
    log "ERROR: $appPath not found."
    exit 1
fi

currentUser=$(/usr/sbin/scutil <<< "show State:/Users/ConsoleUser" | /usr/bin/awk '/Name :/ && ! /loginwindow/ { print $3 }')
if [[ -z "$currentUser" ]]; then
    log "ERROR: No user logged in."
    exit 1
fi

if ! /usr/sbin/chown -R "$currentUser":staff "$appPath"; then
    log "ERROR: chown failed for $appPath"
    exit 1
fi
log "Ownership of $appName set to $currentUser:staff."

if [[ "$openApp" != "no" ]]; then
    /bin/launchctl asuser "$(/usr/bin/id -u "$currentUser")" /usr/bin/sudo -u "$currentUser" /usr/bin/open "$appPath"
    log "Opened $appName as $currentUser."
fi
exit 0
