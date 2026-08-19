#!/bin/zsh
set -euo pipefail

SCRIPT_DIR="${0:A:h}"
python3 "$SCRIPT_DIR/https_server.py" --prepare >/dev/null

BOOTED_DEVICE_IDS=$(xcrun simctl list devices booted -j | python3 -c '
import json, sys
payload = json.load(sys.stdin)
for runtime_devices in payload.get("devices", {}).values():
    for device in runtime_devices:
        if device.get("state") == "Booted":
            print(device["udid"])
')

if [[ -z "$BOOTED_DEVICE_IDS" ]]; then
  print "No booted iOS simulator found. Boot one and run this script again to install the local HTTPS certificate."
else
  for DEVICE_ID in ${(f)BOOTED_DEVICE_IDS}; do
    xcrun simctl keychain "$DEVICE_ID" add-root-cert "$SCRIPT_DIR/.certs/local.crt"
    print "Installed the local HTTPS certificate in simulator $DEVICE_ID."
  done
fi

exec python3 "$SCRIPT_DIR/https_server.py"
