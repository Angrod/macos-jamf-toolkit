#!/bin/bash
#
# Title:            Set Firewall Block-All Mode
# Description:      Turns the Application Firewall's "block all incoming
#                   connections" and stealth mode on or off together. Useful as
#                   an incident-response lockdown and its matching undo.
# Usage/Context:    Jamf Pro policy script (create one policy per state).
# Jamf Parameters:
#   $4  "on" or "off"                                    [optional, default: on]
# Requirements:     macOS 11+; run as root. For a permanent baseline prefer a
#                   Firewall configuration profile, which users can't change.
# Author:           Angrod (https://github.com/Angrod)
#

log() { echo "$(/bin/date '+%Y-%m-%d %H:%M:%S') | $*"; }

socketfilterfw="/usr/libexec/ApplicationFirewall/socketfilterfw"
state=$(echo "${4:-on}" | /usr/bin/tr '[:upper:]' '[:lower:]')

if [[ "$state" != "on" && "$state" != "off" ]]; then
    log "ERROR: Parameter 4 must be 'on' or 'off'."
    exit 1
fi

if ! "$socketfilterfw" --setblockall "$state" || ! "$socketfilterfw" --setstealthmode "$state"; then
    log "ERROR: socketfilterfw could not apply '$state'."
    exit 1
fi

log "Block-all and stealth mode set to '$state'. Current state:"
"$socketfilterfw" --getblockall
"$socketfilterfw" --getstealthmode
exit 0
