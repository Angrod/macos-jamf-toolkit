#!/bin/bash
#
# Title:            jamfHelper Alert
# Description:      Shows a centered jamfHelper utility window with a title,
#                   heading, message and one button. Reusable for any policy
#                   that needs to tell the user something (e.g. "log out to
#                   finish Jamf Connect setup").
# Usage/Context:    Jamf Pro policy script.
# Jamf Parameters:
#   $4  Window title                                                  [required]
#   $5  Heading                                                       [optional]
#   $6  Message body; "\n" is turned into a line break                [required]
#   $7  Button label                                    [optional, default: OK]
# Requirements:     macOS 11+; Jamf Pro agent (jamfHelper); a user logged in.
# Author:           Angrod (https://github.com/Angrod)
#

log() { echo "$(/bin/date '+%Y-%m-%d %H:%M:%S') | $*"; }

jamfHelper="/Library/Application Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfHelper"
title="${4:-}"
heading="${5:-}"
description=$(printf '%b' "${6:-}")
buttonText="${7:-OK}"

if [[ -z "$title" || -z "$description" ]]; then
    log "ERROR: Parameters 4 (title) and 6 (message) are required."
    exit 1
fi
if [[ ! -x "$jamfHelper" ]]; then
    log "ERROR: jamfHelper not found."
    exit 1
fi

"$jamfHelper" -windowType utility -title "$title" \
    -heading "$heading" -alignHeading center \
    -description "$description" -alignDescription center \
    -button1 "$buttonText" -defaultButton 1

log "Alert shown and dismissed."
exit 0
