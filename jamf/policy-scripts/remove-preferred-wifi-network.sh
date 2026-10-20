#!/bin/bash
#
# Title:            Remove Preferred Wi-Fi Network(s)
# Description:      Removes up to three SSIDs from the preferred-network list of
#                   every Wi-Fi interface, e.g. to stop corporate laptops from
#                   auto-joining a guest or IoT network.
# Usage/Context:    Jamf Pro policy script.
# Jamf Parameters:
#   $4  SSID to remove                                                [required]
#   $5  Additional SSID to remove                                     [optional]
#   $6  Additional SSID to remove                                     [optional]
# Requirements:     macOS 11+; run as root.
# Author:           Angrod (https://github.com/Angrod)
#

log() { echo "$(/bin/date '+%Y-%m-%d %H:%M:%S') | $*"; }

ssids=()
for ssid in "${4:-}" "${5:-}" "${6:-}"; do
    [[ -n "$ssid" ]] && ssids+=("$ssid")
done

if (( ${#ssids[@]} == 0 )); then
    log "ERROR: Parameter 4 (SSID) is required."
    exit 1
fi

wifiDevices=$(/usr/sbin/networksetup -listallhardwareports | /usr/bin/awk '/Hardware Port: (Wi-Fi|AirPort)/ { getline; print $2 }')
if [[ -z "$wifiDevices" ]]; then
    log "No Wi-Fi interface found. Nothing to do."
    exit 0
fi

while IFS= read -r device; do
    for ssid in "${ssids[@]}"; do
        if /usr/sbin/networksetup -removepreferredwirelessnetwork "$device" "$ssid" &>/dev/null; then
            log "Removed '$ssid' from $device"
        else
            log "'$ssid' was not in the preferred list on $device"
        fi
    done
done <<< "$wifiDevices"

exit 0
