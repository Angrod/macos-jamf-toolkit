#!/bin/bash
#
# Title:            Remove GarageBand and iMovie
# Description:      Removes GarageBand (plus its multi-GB sound library) and iMovie,
#                   which ship preinstalled on many Macs, to reclaim disk space on
#                   managed machines that don't need them.
# Usage/Context:    Jamf Pro policy script (enrollment clean-up or Self Service).
# Jamf Parameters:  None.
# Requirements:     macOS 11+; run as root.
# Author:           Angrod (https://github.com/Angrod)
#

log() { echo "$(/bin/date '+%Y-%m-%d %H:%M:%S') | $*"; }

targets=(
    "/Applications/GarageBand.app"
    "/Library/Application Support/GarageBand"
    "/Library/Application Support/Logic"
    "/Applications/iMovie.app"
)

removed=0
for target in "${targets[@]}"; do
    if [[ -e "$target" ]]; then
        /bin/rm -rf "$target"
        log "Removed $target"
        removed=$((removed + 1))
    fi
done

if (( removed == 0 )); then
    log "GarageBand and iMovie are not installed. Nothing to do."
fi
exit 0
