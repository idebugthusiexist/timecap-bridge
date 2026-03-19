#!/bin/bash
# 1. Load .env
if [ -f .env ]; then
    set -a
    . .env
    set +a
else
    echo "Error: .env file not found."
    exit 1
fi

# 2. SSH Key Check
SSH_KEY="$HOME/.ssh/id_rsa.pub"
if [ ! -f "$SSH_KEY" ]; then
    echo "SSH key not found. Generating..."
    mkdir -p "$HOME/.ssh"
    ssh-keygen -t rsa -b 4096 -f "${SSH_KEY%.pub}" -N ''
fi

# 3. Create a temporary config file for the VM
cat <<EOF > vm_config.env
TIMECAP_BRIDGE_IP="$TIMECAP_BRIDGE_IP"
TIMECAP_BRIDGE_SHARE="$TIMECAP_BRIDGE_SHARE"
TIMECAP_BRIDGE_USER="$TIMECAP_BRIDGE_USER"
TIMECAP_BRIDGE_PASS="$TIMECAP_BRIDGE_PASS"
TIMECAP_BRIDGE_LAN_SUBNET="$TIMECAP_BRIDGE_LAN_SUBNET"
EOF

# 4. Clean up previous builds
rm -f timecap-bridge.qcow2

# 5. The Bake (Using --upload for compatibility)
virt-builder debian-8 \
    --size 7G \
    --format qcow2 \
    --upload vm_config.env:/tmp/vm_config.env \
    --run setup-bridge.sh \
    --root-password password:"$TIMECAP_BRIDGE_VM_ROOT_PASS" \
    --ssh-inject root:file:"$SSH_KEY" \
    -o timecap-bridge.qcow2

# Cleanup
rm vm_config.env
echo "Build complete."
