#!/bin/bash
# init-host.sh - Prepares the surrogate host for the TimeCap Bridge

echo "--- Starting Host Initialization for Motherly-Mocha ---"

# 1. Hardware Capability Check (The "Anti-E7200" Gate)
VIRT_CHECK=$(grep -Eoc '(vmx|svm)' /proc/cpuinfo)

if [ "$VIRT_CHECK" -eq 0 ]; then
    echo "ERROR: This CPU does not support VT-x/AMD-V or it is disabled in BIOS."
    echo "Aborting. This host cannot run the Bridge efficiently."
    exit 1
else
    echo "SUCCESS: Hardware virtualization support detected ($VIRT_CHECK cores)."
fi

# 2. Software Stack Installation
echo "Installing KVM/Libvirt toolchain..."
apt-get update
apt-get install -y \
    qemu-kvm \
    libvirt-daemon-system \
    libvirt-clients \
    bridge-utils \
    virtinst \
    libguestfs-tools \
    cpu-checker \
    nfs-common

# 3. Kernel Module Verification
echo "Verifying kernel modules..."
modprobe kvm-intel 2>/dev/null || modprobe kvm-amd 2>/dev/null

# 4. Final KVM Readiness Check
if kvm-ok | grep -q "KVM acceleration can be used"; then
    echo "SUCCESS: KVM acceleration is active and ready."
else
    echo "ERROR: KVM acceleration is NOT available."
    echo "Please check your BIOS settings (Virtualization Technology: Enabled)."
    exit 1
fi

# 5. Network Preparation
echo "Starting default KVM network..."
virsh net-start default 2>/dev/null
virsh net-autostart default

echo "--- Host Initialization Complete ---"

# --- Infrastructure Documentation Section ---
echo "--------------------------------------------------------"
echo "POST-INSTALL ACTION REQUIRED: Static IP Reservation"
echo "--------------------------------------------------------"
echo "To ensure the TimeCap Bridge is always at 192.168.122.46:"
echo "1. Run: virsh net-edit default"
echo "2. Add the following inside the <dhcp> block:"
echo "   <host mac='$(virsh dumpxml timecap-bridge-vm | grep "mac address" | cut -d\' -f2)' name='timecap-bridge-vm' ip='192.168.122.46'/>"
echo "3. Restart the virtual network:"
echo "   virsh net-destroy default && virsh net-start default"
echo "--------------------------------------------------------"

