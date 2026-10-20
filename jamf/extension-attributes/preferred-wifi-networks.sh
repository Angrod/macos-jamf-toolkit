#!/bin/bash
#
# Title:            Preferred Wi-Fi Networks
# Description:      Lists the SSIDs saved in the Wi-Fi preferred-network list, one
#                   per line. Useful for spotting guest/personal networks that
#                   should be removed (see remove-preferred-wifi-network.sh).
# Usage/Context:    Jamf Pro Extension Attribute (Data Type: String, Input: Script).
# Jamf Parameters:  None (extension attributes do not receive script parameters).
# Requirements:     macOS 11+ with a Wi-Fi interface.
# Author:           Angrod (https://github.com/Angrod)
#

wifiDevice=$(/usr/sbin/networksetup -listallhardwareports | /usr/bin/awk '/Hardware Port: (Wi-Fi|AirPort)/ { getline; print $2; exit }')
if [[ -z "$wifiDevice" ]]; then
    echo "<result>No Wi-Fi interface</result>"
    exit 0
fi

networks=$(/usr/sbin/networksetup -listpreferredwirelessnetworks "$wifiDevice" 2>/dev/null | /usr/bin/sed '1d; s/^[[:space:]]*//')

echo "<result>${networks:-None}</result>"
exit 0
