#!/bin/bash

# --- SAFETY GATE ---
if [ -f /etc/os-release ]; then
    . /etc/os-release
    # Check if VERSION_ID is 8 (Jessie)
    if [ "$VERSION_ID" != "8" ]; then
        echo "#########################################################"
        echo "ERROR: TARGET ENVIRONMENT MISMATCH"
        echo "This script is for Debian 8 (Jessie) VMs ONLY."
        echo "Detected Host: $PRETTY_NAME"
        echo "Aborting to prevent host configuration corruption."
        echo "#########################################################"
        exit 1
    fi
else
    echo "Unknown OS. Aborting for safety."
    exit 1
fi
# --- END SAFETY GATE ---

# Source the namespaced config
if [ -f /tmp/vm_config.env ]; then
    . /tmp/vm_config.env
fi

# 1. Fix DNS immediately
echo "nameserver 1.1.1.1" > /etc/resolv.conf
echo "nameserver 8.8.8.8" >> /etc/resolv.conf

# 2. Wait for Network (The "Senior" Latency Check)
# Sometimes the virtual interface takes a second to route traffic
RETRY=0
while ! ping -c 1 -W 2 1.1.1.1 >/dev/null 2>&1 && [ $RETRY -lt 10 ]; do
    echo "Waiting for network connectivity..."
    sleep 2
    ((RETRY++))
done

# 2. Configure APT to ignore expired keys and validity dates
cat <<EOF > /etc/apt/apt.conf.d/999ignore-security
Acquire::Check-Valid-Until "false";
APT::Get::AllowUnauthenticated "true";
Acquire::AllowInsecureRepositories "true";
Acquire::AllowDowngradeToInsecureRepositories "true";
EOF

# Switch to Archive Repos
cat <<EOF > /etc/apt/sources.list
deb http://archive.debian.org/debian/ jessie main
deb http://archive.debian.org/debian-security/ jessie/updates main
EOF

# Install Dependencies (bypass expired keys)
apt-get update -o Acquire::Check-Valid-Until=false
apt-get install -y --force-yes cifs-utils nfs-kernel-server

mkdir -p /mnt/timecapsule

# Handshake logic with TIMECAP_BRIDGE_* variables
echo "//$TIMECAP_BRIDGE_IP/$TIMECAP_BRIDGE_SHARE /mnt/timecapsule cifs username=$TIMECAP_BRIDGE_USER,password=$TIMECAP_BRIDGE_PASS,sec=ntlm,vers=1.0,_netdev 0 0" >> /etc/fstab

# If you still want the rest of the LAN to see it, add that too:
if [ -n "$TIMECAP_BRIDGE_LAN_SUBNET" ]; then
    echo "/mnt/timecapsule $TIMECAP_BRIDGE_LAN_SUBNET(rw,sync,no_subtree_check,all_squash,anonuid=0,anongid=0)" >> /etc/exports
fi

cat <<EOF > /etc/exports
/mnt/timecapsule 192.168.122.0/24(rw,sync,no_subtree_check,all_squash,anonuid=0,anongid=0)
/mnt/timecapsule 192.168.0.0/24(rw,sync,no_subtree_check,all_squash,anonuid=0,anongid=0)
EOF

exportfs -va
