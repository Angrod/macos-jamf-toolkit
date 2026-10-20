#!/bin/bash
#
# Title:            Uptime Check
# Description:      Runs daily; if the Mac has been up longer than the threshold,
#                   calls the policy that shows the restart prompt
#                   (uptime-restart-prompt.sh). Long uptimes block updates and
#                   cause odd behaviour, and many users never restart.
# Usage/Context:    Jamf Pro policy script (Once per day, recurring check-in).
# Jamf Parameters:
#   $4  Uptime threshold in days                           [optional, default: 7]
#   $5  Custom trigger of the restart-prompt policy
#                                 [optional, default: uptime-restart-prompt]
# Requirements:     macOS 11+; run as root; Jamf Pro agent.
# Author:           Angrod (https://github.com/Angrod)
# Credits:          Two-policy uptime workflow adapted from "Adam T." (2020) and
#                   the Jamf Nation thread "Computing uptime and notifying users
#                   of long uptime" (discussion 28361).
#

log() { echo "$(/bin/date '+%Y-%m-%d %H:%M:%S') | $*"; }

thresholdDays="${4:-7}"
trigger="${5:-uptime-restart-prompt}"

if [[ ! "$thresholdDays" =~ ^[0-9]+$ ]]; then
    log "ERROR: Parameter 4 must be a whole number of days."
    exit 1
fi

bootEpoch=$(/usr/sbin/sysctl -n kern.boottime | /usr/bin/awk -F'[ ,]' '{ print $4 }')
uptimeDays=$(( ($(/bin/date +%s) - bootEpoch) / 86400 ))
log "Uptime: $uptimeDays day(s); threshold: $thresholdDays."

if (( uptimeDays >= thresholdDays )); then
    log "Threshold reached. Running policy trigger '$trigger'."
    /usr/local/bin/jamf policy -event "$trigger"
fi
exit 0
