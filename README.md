# TimeCap-Bridge 

![Linux's Tux using a stethoscope on an Apple NAS device](https://i.imgur.com/VTHFzBo.png)

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

## Notes:

If you intend to re-share this mount via SMBv3, this approach worked for me:
1.  Edit your fstab to add the following mount: `//{vm-ip-address}/TimeCapsule /mnt/timecapsule cifs guest,vers=3.0,nofail,_netdev,rw,noperm,file_mode=0777,dir_mode=0777,iocharset=utf8 0 0`
2.  Create a service that checks to see if your VM's share is mounted:
```
/etc/systemd/system/tc-data-ready.service

[Unit]
Description=Wait for Time Capsule Magic File
After=libvirtd.service
Requires=libvirtd.service

[Service]
Type=oneshot
ExecStart=/bin/bash -c 'until [ -f "/mnt/timecapsule/.com.apple.timemachine.supported" ]; do mount /mnt/timecapsule 2>/dev/null; sleep 5; done'
TimeoutStartSec=300
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
```
3.  Then configure SAMBA to wait until that service is ready before bringing up SAMBA:
```
systemctl edit smbd

[Unit]
After=timecapsule-data-ready.service
Requires=timecapsule-data-ready.service
```
