#!/bin/bash
#
# Title:            Install / Update Slack
# Description:      Compares the installed Slack version with the latest release
#                   in Slack's RSS feed, downloads the universal DMG when needed,
#                   installs it, and hands ownership of Slack.app to the logged-in
#                   user so Slack's own updater keeps working afterwards.
# Usage/Context:    Jamf Pro policy script (recurring check-in or Self Service).
# Jamf Parameters:
#   $4  "kill" to quit Slack if it is running; otherwise the update is
#       skipped while Slack is open                                   [optional]
# Requirements:     macOS 11+; run as root; outbound HTTPS to slack.com.
# Author:           Angrod (https://github.com/Angrod)
# Credits:          Original script by Shaquir Tannis (Jamf Nation, 2019), with
#                   help from Ian Davidson (@iancd), owen.pragel and anverhousseini.
#                   Changes: universal DMG, new RSS parsing, temp mount point,
#                   abort-if-running fix, user-context relaunch, exit codes.
#

log() { echo "$(/bin/date '+%Y-%m-%d %H:%M:%S') | $*"; }

killSlack="${4:-}"
appPath="/Applications/Slack.app"

currentUser=$(/usr/sbin/scutil <<< "show State:/Users/ConsoleUser" | /usr/bin/awk '/Name :/ && ! /loginwindow/ { print $3 }')

set_ownership() {
    if [[ -n "$currentUser" && -d "$appPath" ]]; then
        /usr/sbin/chown -R "$currentUser":staff "$appPath"
        log "Ownership of Slack.app set to $currentUser."
    fi
}

latestVersion=$(/usr/bin/curl -fsSL "https://slack.com/release-notes/mac/rss" \
    | /usr/bin/grep -oE '<title>Slack [0-9]+\.[0-9]+\.[0-9]+' \
    | /usr/bin/grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | /usr/bin/head -n 1)
installedVersion=$(/usr/bin/defaults read "$appPath/Contents/Info.plist" CFBundleShortVersionString 2>/dev/null)
log "Installed: ${installedVersion:-none} | Latest: ${latestVersion:-unknown}"

if [[ -n "$installedVersion" && "$installedVersion" == "$latestVersion" ]]; then
    log "Slack is up to date."
    set_ownership
    exit 0
fi

wasRunning=false
if /usr/bin/pgrep -x Slack &>/dev/null; then
    wasRunning=true
    if [[ "$killSlack" != "kill" ]]; then
        log "Slack is running and Parameter 4 is not 'kill'. Skipping update."
        exit 0
    fi
    log "Quitting Slack."
    /usr/bin/pkill -x Slack
    /bin/sleep 5
    if /usr/bin/pgrep -x Slack &>/dev/null; then
        log "ERROR: Slack is still running. Try again later."
        exit 1
    fi
fi

workDir=$(/usr/bin/mktemp -d /private/tmp/slack.XXXXXX)
mountPoint="$workDir/mount"
/bin/mkdir -p "$mountPoint"
trap '/usr/bin/hdiutil detach "$mountPoint" -quiet -force &>/dev/null; /bin/rm -rf "$workDir"' EXIT

downloadUrl=$(/usr/bin/curl -fsSLI -o /dev/null -w '%{url_effective}' "https://slack.com/ssb/download-osx-universal")
log "Downloading $downloadUrl"
if ! /usr/bin/curl -fsSL -o "$workDir/Slack.dmg" "$downloadUrl"; then
    log "ERROR: Download failed."
    exit 1
fi

if ! /usr/bin/hdiutil attach "$workDir/Slack.dmg" -nobrowse -noverify -quiet -mountpoint "$mountPoint"; then
    log "ERROR: Could not mount the Slack DMG."
    exit 1
fi

/bin/rm -rf "$appPath"
if ! /usr/bin/ditto "$mountPoint/Slack.app" "$appPath"; then
    log "ERROR: Copying Slack.app failed."
    exit 1
fi
log "Installed Slack $(/usr/bin/defaults read "$appPath/Contents/Info.plist" CFBundleShortVersionString)."

set_ownership

if [[ -n "$currentUser" ]] && { $wasRunning || [[ -z "$installedVersion" ]]; }; then
    /bin/launchctl asuser "$(/usr/bin/id -u "$currentUser")" /usr/bin/sudo -u "$currentUser" /usr/bin/open "$appPath"
fi

exit 0
