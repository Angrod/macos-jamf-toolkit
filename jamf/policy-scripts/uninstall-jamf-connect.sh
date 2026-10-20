#!/bin/bash
#
# Title:            Uninstall Jamf Connect
# Description:      Restores the standard macOS login window (authchanger -reset)
#                   and removes the Jamf Connect app, login bundle, PAM module and
#                   menu bar LaunchAgent. Resetting authchanger first avoids
#                   leaving the Mac with a broken login window.
# Usage/Context:    Jamf Pro policy script.
# Jamf Parameters:  None.
# Requirements:     macOS 11+; run as root. Remove the Jamf Connect configuration
#                   profiles too, or the menu bar app may be redeployed.
# Author:           Angrod (https://github.com/Angrod)
#

log() { echo "$(/bin/date '+%Y-%m-%d %H:%M:%S') | $*"; }

authchanger="/usr/local/bin/authchanger"

if [[ -x "$authchanger" ]]; then
    if ! "$authchanger" -reset; then
        log "ERROR: authchanger -reset failed; leaving Jamf Connect in place."
        exit 1
    fi
    log "Login window restored to macOS default."
fi

targets=(
    "/Applications/Jamf Connect.app"
    "$authchanger"
    "/usr/local/lib/pam/pam_saml.so.2"
    "/Library/Security/SecurityAgentPlugins/JamfConnectLogin.bundle"
    "/Library/LaunchAgents/com.jamf.connect.plist"
)
for target in "${targets[@]}"; do
    if [[ -e "$target" ]]; then
        /bin/rm -rf "$target"
        log "Removed $target"
    fi
done

log "Jamf Connect removed."
exit 0
