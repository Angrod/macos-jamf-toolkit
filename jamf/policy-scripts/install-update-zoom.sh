#!/bin/bash
#
# Title:            Install / Update Zoom
# Description:      Downloads Zoom's IT installer package (ZoomInstallerIT.pkg),
#                   optionally verifies its SHA-256, and installs it. By default
#                   it skips Macs where Zoom is running; Parameter 5 = "kill"
#                   quits Zoom first (for forced/deadline updates).
# Usage/Context:    Jamf Pro policy script (recurring or Self Service).
# Jamf Parameters:
#   $4  Expected SHA-256 of the package (blank = skip verification) [optional]
#   $5  "kill" to quit Zoom if it is running                          [optional]
# Requirements:     macOS 11+; run as root; outbound HTTPS to zoom.us.
# Author:           Angrod (https://github.com/Angrod)
# Credits:          Download/checksum structure adapted from William Smith's
#                   (talkingmoose) Microsoft installer script, CC BY 4.0:
#                   https://gist.github.com/talkingmoose/b6637160b65b751824943ede022daa17
#                   Changes: Zoom IT package URL, force-quit option, logging.
#

log() { echo "$(/bin/date '+%Y-%m-%d %H:%M:%S') | $*"; }

sha256Checksum="${4:-}"
killZoom="${5:-}"
url="https://zoom.us/client/latest/ZoomInstallerIT.pkg"
appProcess="zoom.us"

if /usr/bin/pgrep -x "$appProcess" &>/dev/null; then
    if [[ "$killZoom" != "kill" ]]; then
        log "Zoom is running and Parameter 5 is not 'kill'. Skipping."
        exit 0
    fi
    log "Quitting Zoom."
    /usr/bin/pkill -x "$appProcess"
    /bin/sleep 3
fi

tempDirectory=$(/usr/bin/mktemp -d /private/tmp/zoom.XXXXXX)
trap '/bin/rm -rf "$tempDirectory"' EXIT
pkgFile="$tempDirectory/ZoomInstallerIT.pkg"

log "Downloading $url"
if ! /usr/bin/curl -fsSL -o "$pkgFile" "$url"; then
    log "ERROR: Download failed."
    exit 1
fi

downloadChecksum=$(/usr/bin/shasum -a 256 "$pkgFile" | /usr/bin/awk '{ print $1 }')
log "Downloaded package SHA-256: $downloadChecksum"
if [[ -n "$sha256Checksum" && "$sha256Checksum" != "$downloadChecksum" ]]; then
    log "ERROR: Checksum mismatch (expected $sha256Checksum)."
    exit 1
fi

if /usr/sbin/installer -pkg "$pkgFile" -target /; then
    log "Zoom installed/updated."
    exit 0
fi

log "ERROR: Zoom package failed to install."
exit 1
