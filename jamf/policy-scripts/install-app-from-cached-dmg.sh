#!/bin/bash
#
# Title:            Install App from Cached DMG
# Description:      Installs an app from a DMG that a Jamf policy has cached to
#                   the Waiting Room (or any path). Copies a .app bundle into
#                   /Applications, or runs a .pkg found inside the DMG, then
#                   unmounts and deletes the DMG. Mounting to a private temp
#                   mount point means the DMG's volume name doesn't matter.
# Usage/Context:    Jamf Pro policy script (run "After" a package cache step).
# Jamf Parameters:
#   $4  DMG file name in the Waiting Room, or a full path            [required]
#       e.g. "LarkSuite.dmg"
#   $5  Item inside the DMG to install: "Name.app" or "Installer.pkg" [required]
#   $6  Set to "keep" to leave the DMG on disk afterwards            [optional]
# Requirements:     macOS 11+; run as root.
# Author:           Angrod (https://github.com/Angrod)
#

log() { echo "$(/bin/date '+%Y-%m-%d %H:%M:%S') | $*"; }

waitingRoom="/Library/Application Support/JAMF/Waiting Room"
dmgArg="${4:-}"
itemName="${5:-}"
keepDmg="${6:-}"

if [[ -z "$dmgArg" || -z "$itemName" ]]; then
    log "ERROR: Parameters 4 (DMG) and 5 (item to install) are required."
    exit 1
fi
if [[ "$dmgArg" == /* ]]; then dmgPath="$dmgArg"; else dmgPath="$waitingRoom/$dmgArg"; fi
if [[ ! -f "$dmgPath" ]]; then
    log "ERROR: DMG not found at $dmgPath"
    exit 1
fi

mountPoint=$(/usr/bin/mktemp -d /private/tmp/dmgmount.XXXXXX)
# shellcheck disable=SC2317  # invoked by the EXIT trap
cleanup() {
    /usr/bin/hdiutil detach "$mountPoint" -quiet -force &>/dev/null
    /bin/rmdir "$mountPoint" &>/dev/null
}
trap cleanup EXIT

if ! /usr/bin/hdiutil attach "$dmgPath" -nobrowse -noverify -quiet -mountpoint "$mountPoint"; then
    log "ERROR: Could not mount $dmgPath"
    exit 1
fi

source="$mountPoint/$itemName"
if [[ ! -e "$source" ]]; then
    log "ERROR: '$itemName' not found inside the DMG."
    exit 1
fi

case "$itemName" in
    *.pkg)
        log "Installing package $itemName"
        if ! /usr/sbin/installer -pkg "$source" -target /; then
            log "ERROR: installer failed for $itemName"
            exit 1
        fi
        ;;
    *.app)
        destination="/Applications/$itemName"
        if [[ -d "$destination" ]]; then
            log "Removing existing $destination"
            /bin/rm -rf "$destination"
        fi
        log "Copying $itemName to /Applications"
        if ! /usr/bin/ditto "$source" "$destination"; then
            log "ERROR: Copy failed for $itemName"
            exit 1
        fi
        ;;
    *)
        log "ERROR: Parameter 5 must end in .app or .pkg"
        exit 1
        ;;
esac

if [[ "$keepDmg" != "keep" ]]; then
    /bin/rm -f "$dmgPath"
    log "Deleted cached DMG."
fi

log "Installed $itemName successfully."
exit 0
