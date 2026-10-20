#!/bin/bash
#
# Title:            Remove macOS Installers
# Description:      Deletes leftover "Install macOS *.app" / "Install OS X *.app"
#                   bundles (12+ GB each) from /Applications, optionally keeping
#                   the one you are currently deploying.
# Usage/Context:    Jamf Pro policy script (disk clean-up).
# Jamf Parameters:
#   $4  Installer to keep, e.g. "Install macOS Sequoia.app"           [optional]
# Requirements:     macOS 11+; run as root.
# Author:           Angrod (https://github.com/Angrod)
#

log() { echo "$(/bin/date '+%Y-%m-%d %H:%M:%S') | $*"; }

keep="${4:-}"
keep="${keep:+${keep%.app}.app}"

shopt -s nullglob
removed=0
for installer in "/Applications/Install macOS "*.app "/Applications/Install OS X "*.app; do
    if [[ -n "$keep" && "$(/usr/bin/basename "$installer")" == "$keep" ]]; then
        log "Keeping $installer"
        continue
    fi
    /bin/rm -rf "$installer"
    log "Removed $installer"
    removed=$((removed + 1))
done

log "Done. $removed installer(s) removed."
exit 0
