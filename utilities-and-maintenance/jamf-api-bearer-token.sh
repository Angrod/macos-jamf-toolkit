#!/bin/bash
#
# Title:            Jamf Pro API Bearer Token
# Description:      Gets, reuses and invalidates a Jamf Pro API bearer token,
#                   then calls /api/v1/jamf-pro-version as a smoke test. Works
#                   with API Roles & Clients (OAuth client credentials, preferred)
#                   or a user account. Copy the functions into your own API
#                   scripts.
# Usage/Context:    Standalone admin tool, run from your own Mac:
#                     export JAMF_URL="https://your-instance.jamfcloud.com"
#                     export JAMF_CLIENT_ID="..." JAMF_CLIENT_SECRET="..."
#                     ./jamf-api-bearer-token.sh
#                   (or set JAMF_USER / JAMF_PASSWORD instead of the client pair)
# Jamf Parameters:  None (not a policy script). Credentials come from environment
#                   variables, never from the file.
# Requirements:     macOS 12+ (plutil -extract ... raw), curl. Jamf Pro 10.49+ for
#                   API clients. Give the client/role only the privileges it needs.
# Author:           Angrod (https://github.com/Angrod)
# Credits:          Token handling follows Jamf's developer documentation examples
#                   for bearer tokens and client credentials.
#

url="${JAMF_URL:-https://your-instance.jamfcloud.com}"
url="${url%/}"
clientId="${JAMF_CLIENT_ID:-}"
clientSecret="${JAMF_CLIENT_SECRET:-}"
apiUser="${JAMF_USER:-}"
apiPassword="${JAMF_PASSWORD:-}"

bearerToken=""
tokenExpirationEpoch=0

die() { echo "ERROR: $*" >&2; exit 1; }

if [[ "$url" == *"your-instance"* ]]; then
    die "Set JAMF_URL to your Jamf Pro URL."
fi
if [[ -z "$clientId$apiUser" ]]; then
    die "Set JAMF_CLIENT_ID/JAMF_CLIENT_SECRET (preferred) or JAMF_USER/JAMF_PASSWORD."
fi

getBearerToken() {
    local response
    if [[ -n "$clientId" ]]; then
        response=$(/usr/bin/curl -fsS -X POST "$url/api/oauth/token" \
            --data-urlencode "client_id=$clientId" \
            --data-urlencode "grant_type=client_credentials" \
            --data-urlencode "client_secret=$clientSecret") || die "Token request failed."
        bearerToken=$(/usr/bin/plutil -extract access_token raw - <<< "$response")
        local expiresIn
        expiresIn=$(/usr/bin/plutil -extract expires_in raw - <<< "$response")
        tokenExpirationEpoch=$(( $(/bin/date +%s) + expiresIn - 5 ))
    else
        response=$(/usr/bin/curl -fsS -X POST -u "$apiUser:$apiPassword" "$url/api/v1/auth/token") \
            || die "Token request failed."
        bearerToken=$(/usr/bin/plutil -extract token raw - <<< "$response")
        local expires
        expires=$(/usr/bin/plutil -extract expires raw - <<< "$response" | /usr/bin/awk -F. '{ print $1 }')
        tokenExpirationEpoch=$(/bin/date -j -u -f "%Y-%m-%dT%T" "$expires" +"%s")
    fi
    [[ -n "$bearerToken" ]] || die "No token in the response."
}

checkTokenExpiration() {
    if (( tokenExpirationEpoch > $(/bin/date +%s) )); then
        echo "Token valid until epoch $tokenExpirationEpoch"
    else
        echo "No valid token available, getting a new one"
        getBearerToken
    fi
}

invalidateToken() {
    local responseCode
    responseCode=$(/usr/bin/curl -s -o /dev/null -w "%{http_code}" -X POST \
        -H "Authorization: Bearer $bearerToken" "$url/api/v1/auth/invalidate-token")
    case "$responseCode" in
        204) echo "Token invalidated"; bearerToken=""; tokenExpirationEpoch=0 ;;
        401) echo "Token already invalid" ;;
        *)   echo "Unexpected response invalidating token: $responseCode" ;;
    esac
}

checkTokenExpiration
/usr/bin/curl -fsS -H "Authorization: Bearer $bearerToken" "$url/api/v1/jamf-pro-version"
echo
invalidateToken
exit 0
