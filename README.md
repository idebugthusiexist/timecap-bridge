# TimeCap-Bridge 

![Linux's Tux using a stethoscope on an Apple NAS device](https://i.imgur.com/gWBUAbF.png)

Virtualized SMB1 → SMB3 Protocol Bridge. For restoring access to legacy Apple Network Storage for the modern LAN.

### *The Protocol Time Machine*

**TimeCap-Bridge** is a purpose-built, virtualized gateway designed to bridge the \"Security Gap\" between modern Linux environments and legacy Apple Time Capsule hardware. By acting as a protocol translator, it allows modern kernels to safely interact with ancient **SMB1/NTLM** storage without compromising host security.

---

## The Architecture

The bridge operates as a lightweight layer:
1.  **Legacy Inbound:** The VM mounts the Time Capsule via **SMB1.0** (Debian Jessie-era kernel).
2.  **Protocol Translation:** A local **Samba** instance re-shares the mount point.
3.  **Modern Outbound:** Your LAN accesses the share via **SMB 3.0**, bypassing NFS export restrictions and SSH handshake failures.

---

## Debugger’s Log: \"The Handshake Crisis\"

|||
| :--- | :--- |
| **NFS Export Errors** | Bypassed; NFS refuses to re-export CIFS on 3.16 kernels. |
| **SSH Reset** | Ignored; Cipher mismatch between OpenSSH 6.7 and 10.0. |
| **AFPFS-NG Auth** | Failed no matter what UAM used |
