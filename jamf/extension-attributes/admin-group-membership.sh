#!/bin/bash
#
# Title:            Admin Group Membership
# Description:      Reports the members of the local "admin" group and any nested
#                   groups, so unexpected administrators stand out in inventory.
# Usage/Context:    Jamf Pro Extension Attribute (Data Type: String, Input: Script).
# Jamf Parameters:  None (extension attributes do not receive script parameters).
# Requirements:     macOS 11+. No third-party dependencies.
# Author:           Angrod (https://github.com/Angrod)
#

members=$(/usr/bin/dscl . -read /Groups/admin GroupMembership 2>/dev/null | /usr/bin/sed 's/^GroupMembership: *//')
nested=$(/usr/bin/dscl . -read /Groups/admin NestedGroups 2>/dev/null | /usr/bin/sed 's/^NestedGroups: *//')

echo "<result>Members: ${members:-none}; Nested groups: ${nested:-none}</result>"
exit 0
