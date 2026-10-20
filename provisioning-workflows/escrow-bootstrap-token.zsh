#!/bin/zsh
#
# Title:            Escrow Bootstrap Token to MDM
# Description:      Escrows the Mac's Bootstrap Token to Jamf Pro using a
#                   SecureToken-enabled admin account. A Bootstrap Token lets MDM
#                   grant SecureTokens to new users and approve software updates
#                   on Apple Silicon without interactive admin credentials.
#                   Pairs with jamf/extension-attributes/bootstrap-token-status.zsh.
# Usage/Context:    Jamf Pro policy script (enrollment or remediation Smart Group).
# Jamf Parameters:
#   $4  Admin username (SecureToken holder), Base64-encoded           [required]
#   $5  Admin password, Base64-encoded                                [required]
#       Base64 is obfuscation only, not encryption.
# Requirements:     macOS 10.15+; run as root; MDM must support Bootstrap Token.
# Author:           Angrod (https://github.com/Angrod)
#

log() { echo "$(/bin/date '+%Y-%m-%d %H:%M:%S') | $*"; }

tokenStatus() { /usr/bin/profiles status -type bootstraptoken 2>&1; }

if [[ "$(tokenStatus)" == *"escrowed to server: YES"* ]]; then
    log "Bootstrap Token already escrowed."
    exit 0
fi
if [[ "$(tokenStatus)" == *"supported on server: NO"* ]]; then
    log "ERROR: The MDM server does not support Bootstrap Token."
    exit 1
fi

if [[ -z "${4:-}" || -z "${5:-}" ]]; then
    log "ERROR: Parameters 4 and 5 (Base64 username/password) are required."
    exit 1
fi

# Pass credentials through the environment so quotes, $ or [ in the password
# can't break (or inject into) the expect script.
export BT_USER=$(echo "$4" | /usr/bin/base64 -d 2>/dev/null)
export BT_PASS=$(echo "$5" | /usr/bin/base64 -d 2>/dev/null)
if [[ -z "$BT_USER" || -z "$BT_PASS" ]]; then
    log "ERROR: Could not decode the Base64 parameters."
    exit 1
fi

/usr/bin/expect <<'EXPECT' >/dev/null
set timeout 60
spawn /usr/bin/profiles install -type bootstraptoken
expect "Enter the admin user name:"
send -- "$env(BT_USER)\r"
expect "Enter the password for user*"
send -- "$env(BT_PASS)\r"
expect eof
EXPECT
unset BT_USER BT_PASS

if [[ "$(tokenStatus)" == *"escrowed to server: YES"* ]]; then
    log "Bootstrap Token escrowed to MDM."
    exit 0
fi

log "ERROR: Escrow failed. Is the account an admin with a SecureToken, and are the credentials correct?"
exit 1
