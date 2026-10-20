#!/bin/bash
#
# Title:            Uninstall Microsoft Office
# Description:      Removes Microsoft 365 / Office for Mac following Microsoft's
#                   documented uninstall steps. Three modes:
#                     full      apps + licensing helpers + AutoUpdate + user data
#                     apps      apps + the logged-in user's Office data
#                     userdata  only the logged-in user's Office data (resets
#                               preferences/caches without reinstalling)
#                   Only Office items are targeted; Edge, Teams, OneDrive and
#                   Defender are left alone.
# Usage/Context:    Jamf Pro policy script (Self Service or remediation).
# Jamf Parameters:
#   $4  Mode: full | apps | userdata                   [optional, default: full]
# Requirements:     macOS 11+; run as root (user data steps need a user logged in).
# Author:           Angrod (https://github.com/Angrod)
# Credits:          Steps based on Microsoft's "Uninstall Office for Mac" article.
#

log() { echo "$(/bin/date '+%Y-%m-%d %H:%M:%S') | $*"; }

mode="${4:-full}"
if [[ "$mode" != "full" && "$mode" != "apps" && "$mode" != "userdata" ]]; then
    log "ERROR: Parameter 4 must be full, apps or userdata."
    exit 1
fi

remove() {
    local target
    for target in "$@"; do
        if [[ -e "$target" ]]; then
            /bin/rm -rf "$target"
            log "Removed $target"
        fi
    done
}

officeApps=("Microsoft Word" "Microsoft Excel" "Microsoft PowerPoint" "Microsoft Outlook" "Microsoft OneNote")

if [[ "$mode" != "userdata" ]]; then
    for app in "${officeApps[@]}"; do
        /usr/bin/pkill -x "$app" &>/dev/null
        remove "/Applications/$app.app"
    done
fi

if [[ "$mode" == "full" ]]; then
    shopt -s nullglob
    remove "/Library/Application Support/Microsoft/MAU2.0/Microsoft AutoUpdate.app" \
        /Library/LaunchDaemons/com.microsoft.office.* \
        /Library/PrivilegedHelperTools/com.microsoft.office.* \
        /Library/Preferences/com.microsoft.office.*
    shopt -u nullglob
fi

currentUser=$(/usr/sbin/scutil <<< "show State:/Users/ConsoleUser" | /usr/bin/awk '/Name :/ && ! /loginwindow/ { print $3 }')
if [[ -z "$currentUser" ]]; then
    log "No user logged in; skipping per-user Office data."
else
    userHome=$(/usr/bin/dscl . -read "/Users/$currentUser" NFSHomeDirectory | /usr/bin/awk '{ print $2 }')
    for container in Word Excel Powerpoint Outlook onenote.mac errorreporting netlib.shipassertprocess Office365ServiceV2 RMS-XPCService; do
        remove "$userHome/Library/Containers/com.microsoft.$container"
    done
    for group in ms Office OfficeOsfWebHost; do
        remove "$userHome/Library/Group Containers/UBF8T346G9.$group"
    done
fi

log "Office uninstall ($mode) complete. Updating inventory."
/usr/local/bin/jamf recon
exit 0
