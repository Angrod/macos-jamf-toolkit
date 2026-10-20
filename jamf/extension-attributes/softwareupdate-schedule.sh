#!/bin/bash
#
# Title:            Software Update Schedule
# Description:      Reports whether automatic checking for macOS updates is
#                   turned on ("On", "Off" or "Unknown").
# Usage/Context:    Jamf Pro Extension Attribute (Data Type: String, Input: Script).
# Jamf Parameters:  None (extension attributes do not receive script parameters).
# Requirements:     macOS 11+; runs as root (Jamf default).
# Author:           Angrod (https://github.com/Angrod)
#

schedule=$(/usr/sbin/softwareupdate --schedule 2>/dev/null)

case "$schedule" in
    *" on"*)  echo "<result>On</result>" ;;
    *" off"*) echo "<result>Off</result>" ;;
    *)        echo "<result>Unknown</result>" ;;
esac
exit 0
