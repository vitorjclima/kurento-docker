#!/bin/bash

#/ Docker script - Run Kurento Media Server.

# Bash options for strict error checking
set -o errexit -o errtrace -o pipefail -o nounset

# Trace all commands
set -o xtrace

# Settings
BASE_RTP_FILE="/etc/kurento/modules/kurento/BaseRtpEndpoint.conf.ini"
WEBRTC_FILE="/etc/kurento/modules/kurento/WebRtcEndpoint.conf.ini"

# Aux function: set value to a given parameter
function set_parameter() {
    local FILE="${1:-}"
    local PARAM="${2:-}"
    local VALUE="${3:-}"

    if grep -q -E "\s*${PARAM}=.*" "$FILE"; then
        sed -i -r "s/;+\s*${PARAM}=.*/${PARAM}=${VALUE}/" "$FILE"
    else
        echo "${PARAM}=${VALUE}" >>"$FILE"
    fi
}

# BaseRtpEndpoint settings
if [[ -n "${KMS_MTU:-}" ]]; then
    set_parameter "$BASE_RTP_FILE" "mtu" "$KMS_MTU"
fi

# WebRtcEndpoint settings
if [[ -n "${KMS_NETWORK_INTERFACES:-}" ]]; then
    set_parameter "$WEBRTC_FILE" "networkInterfaces" "$KMS_NETWORK_INTERFACES"
fi
if [[ -n "${KMS_STUN_IP:-}" ]] && [[ -n "${KMS_STUN_PORT:-}" ]]; then
    set_parameter "$WEBRTC_FILE" "stunServerAddress" "$KMS_STUN_IP"
    set_parameter "$WEBRTC_FILE" "stunServerPort" "$KMS_STUN_PORT"
fi
if [[ -n "${KMS_TURN_URL:-}" ]]; then
    set_parameter "$WEBRTC_FILE" "turnURL" "$KMS_TURN_URL"
fi

# Remove the IPv6 loopback until IPv6 is well supported
# Note: `sed -i /etc/hosts` won't work inside a Docker container
cat /etc/hosts | sed '/::1/d' | tee /etc/hosts >/dev/null

# Run Kurento Media Server
exec /usr/bin/kurento-media-server "$@"
