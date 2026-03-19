#!/bin/bash
virt-install \
    --name timecap-bridge-vm \
    --ram 256 \
    --vcpus 1 \
    --import \
    --disk path=timecap-bridge.qcow2,format=qcow2 \
    --os-variant debian8 \
    --network network=default \
    --graphics none \
    --noautoconsole
