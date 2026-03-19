#!/bin/bash
virsh destroy timecap-bridge-vm
virsh undefine timecap-bridge-vm
rm -f timecap-bridge.qcow2
