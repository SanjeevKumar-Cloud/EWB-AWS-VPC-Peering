#!/usr/bin/env bash
# ==============================================================================
# Script: test-connectivity.sh
# Purpose: Execute ping verification between instances across VPC Peering
# Author: Sanjeev Kumar (EWB Cloud Labs)
# ==============================================================================

set -euo pipefail

echo "============================================================"
echo "          EWB AWS VPC PEERING TEST RUNNER                   "
echo "============================================================"
echo "Host Name:       $(hostname)"
echo "Private IP(s):   $(hostname -I | tr -d '
')"
echo "Timestamp:       $(date)"
echo "============================================================"

TARGET_IP="${1:-}"

if [[ -z "$TARGET_IP" ]]; then
    echo "Usage: $0 <DESTINATION_PRIVATE_IP>"
    echo "Example on App-A (pinging App-B): $0 10.20.1.10"
    echo "Example on App-B (pinging App-A): $0 10.10.2.10"
    exit 1
fi

echo "[*] Pinging $TARGET_IP with 4 ICMP packets..."
echo "------------------------------------------------------------"
ping -c 4 "$TARGET_IP"
echo "------------------------------------------------------------"
echo "[+] Test finished. Check summary for packet loss."
