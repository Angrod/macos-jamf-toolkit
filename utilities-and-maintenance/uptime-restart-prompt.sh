#!/bin/bash
#
# Title:            Uptime Restart Prompt
# Description:      jamfHelper dialog asking the user to restart, with a delay
#                   drop-down (now, 1 min, 5 min, 1 hr, 2 hrs) and a Cancel button.
#                   Called by uptime-check.sh when uptime passes the threshold.
# Usage/Context:    Jamf Pro policy script (custom trigger, e.g.
#                   "uptime-restart-prompt").
# Jamf Parameters:
#   $4  Window title                 [optional, default: "IT Helpdesk"]
#   $5  Heading             [optional, default: "Please restart your computer"]
#   $6  Delay options in seconds, comma-separated
#                                 [optional, default: "0, 60, 300, 3600, 7200"]
# Requirements:     macOS 11+; run as root; Jamf Pro agent (jamfHelper); a user
#                   logged in.
# Author:           Angrod (https://github.com/Angrod)
# Credits:          jamfHelper delay-options prompt adapted from "Adam T." (2020)
#                   via Jamf Nation.
#

log() { echo "$(/bin/date '+%Y-%m-%d %H:%M:%S') | $*"; }

jamfHelper="/Library/Application Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfHelper"
title="${4:-IT Helpdesk}"
heading="${5:-Please restart your computer}"
delayOptions="${6:-0, 60, 300, 3600, 7200}"
icon="/System/Library/CoreServices/Software Update.app/Contents/Resources/SoftwareUpdate.icns"
description="Your computer has not been restarted in at least seven days. A more frequent restart is recommended.

Doing so optimizes the performance of your computer and lets us deploy security updates and new applications to you automatically.

Please restart now."

currentUser=$(/usr/sbin/scutil <<< "show State:/Users/ConsoleUser" | /usr/bin/awk '/Name :/ && ! /loginwindow/ { print $3 }')
if [[ -z "$currentUser" ]]; then
    log "No user logged in. Skipping prompt."
    exit 0
fi

# With -showDelayOptions, jamfHelper prints "<seconds chosen><button number>".
selection=$("$jamfHelper" -windowType utility -title "$title" -heading "$heading" \
    -description "$description" -icon "$icon" \
    -button1 "Cancel" -button2 "Restart" -cancelButton 1 \
    -showDelayOptions "$delayOptions")

buttonClicked="${selection: -1}"
timeChosen="${selection%?}"
log "Button: ${buttonClicked:-none}; delay: ${timeChosen:-0}s"

if [[ "$buttonClicked" == "2" ]]; then
    if [[ -n "$timeChosen" && "$timeChosen" -gt 0 ]]; then
        minutes=$(( (timeChosen + 59) / 60 ))
        log "Restart scheduled in $minutes minute(s)."
        /sbin/shutdown -r "+$minutes" &
    else
        log "Restarting now."
        /sbin/shutdown -r now
    fi
else
    log "User cancelled the restart."
fi
exit 0
