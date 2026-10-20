#!/bin/zsh
#
# Title:            Uninstall Adobe Creative Cloud
# Description:      Uninstalls every Creative Cloud app registered with Adobe's
#                   HyperDrive installer (one pass per *.adbarg receipt, run twice
#                   to catch dependencies), then Acrobat DC and finally the
#                   Creative Cloud desktop app itself.
# Usage/Context:    Jamf Pro policy script (offboarding / licence reclaim).
# Jamf Parameters:  None.
# Requirements:     macOS 11+; run as root. User preferences are kept
#                   (--deleteUserPreferences=false).
# Author:           Angrod (https://github.com/Angrod)
# Credits:          Approach loosely based on Anthony Reimer's write-up
#                   (https://maclabs.jazzace.ca/2020/11/01/unistalling-adobe-apps.html)
#                   and Adobe's enterprise uninstall documentation.
#

log() { echo "$(/bin/date '+%Y-%m-%d %H:%M:%S') | $*"; }

uninstallDir="/Library/Application Support/Adobe/Uninstall"
setup="/Library/Application Support/Adobe/Adobe Desktop Common/HDBox/Setup"
acrobatApp="/Applications/Adobe Acrobat DC/Adobe Acrobat.app"
ccUninstaller="/Applications/Utilities/Adobe Creative Cloud/Utils/Creative Cloud Uninstaller.app/Contents/MacOS/Creative Cloud Uninstaller"

remove_adobe_apps() {
    if [[ ! -d "$uninstallDir" || ! -x "$setup" ]]; then
        log "No Creative Cloud apps registered for uninstall."
        return
    fi

    local receipt appName sapCode prodVer
    for receipt in "$uninstallDir"/*.adbarg(N); do
        appName=${receipt:t:r}
        sapCode=$(/usr/bin/awk -F'=' '/^--sapCode=/ { print $2 }' "$receipt")
        prodVer=$(/usr/bin/awk -F'=' '/^--productVersion=/ { print $2 }' "$receipt")
        log "Uninstalling $appName (sapCode: $sapCode, productVersion: $prodVer)"
        "$setup" --uninstall=1 --sapCode="$sapCode" --productVersion="$prodVer" \
            --platform=osx10-64 --deleteUserPreferences=false \
            || log "WARNING: Adobe Setup returned an error for $appName"
    done
}

log "First pass"
remove_adobe_apps
log "Second pass (catches apps that depended on ones removed above)"
remove_adobe_apps

# Acrobat DC 2015
acrobatRemover15="$acrobatApp/Contents/Helpers/Acrobat Uninstaller.app/Contents/MacOS/RemoverTool"
if [[ -x "$acrobatRemover15" ]]; then
    log "Uninstalling Acrobat DC (2015)"
    "$acrobatRemover15" "$acrobatRemover15" "$acrobatApp"
fi

# Acrobat DC 2018 and later
acrobatRemover="$acrobatApp/Contents/Helpers/Acrobat Uninstaller.app/Contents/Library/LaunchServices/com.adobe.Acrobat.RemoverTool"
if [[ -x "$acrobatRemover" ]]; then
    log "Uninstalling Acrobat DC"
    "$acrobatRemover" "$acrobatApp/Contents/Helpers/Acrobat Uninstaller.app/Contents/MacOS/Acrobat Uninstaller" "$acrobatApp"
fi

if [[ -x "$ccUninstaller" ]]; then
    log "Uninstalling the Creative Cloud desktop app"
    "$ccUninstaller" -u
fi

log "Adobe Creative Cloud removal complete."
exit 0
