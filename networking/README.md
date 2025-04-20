# Networking - Homelab

### 🔥 Best Choice for Homelab

→ ipvlan or macvlan

Why?
- Containers and VM get a direct LAN IP like 192.168.1.60.
- No port forwarding needed.
- Easy to access from anywhere on your LAN.
- Works perfectly with Traefik, Pi-hole, and k3s communication.

👀 **Requisites**
  - QEMU/KVM/Virsh/Virt Manager
  - Docker
  - dnsmasq

👀  **Plan**

Everyone is on the same subnet (like 192.168.1.0/24) → Full communication ✅
```
[ Host Machine ]
    |
    |-- LAYER 3 (OSI) <--- NAT
    |-- LAYER 2 (OSI) <--- All attached here
          |
          |-- [Docker Containers]
          |-- [Minikube]
          |-- [VM1]
          |-- [VM2]
          |-- [Host Itself]
```

```
[ Host 192.168.1.1 ]
    |-- LAYER 3 (OSI) <--- NAT
    |-- LAYER 2 (OSI) <--- All attached here
        |
        |-- [VM1 192.168.1.10] (virt-manager, bridged to virbr0)
        |-- [VM2 192.168.1.201]  (virt-manager, bridged to virbr0)
        |-- [VM2 192.168.1.202]  (virtualbox, bridged to virbr0)      
        |-- [Container1 192.168.1.20] (Docker with ipvlan on virbr0)
        |-- [Container2 192.168.1.21] .. portainer...
```

```
                       [ Internet ]
                            |
                    [ Network Interface ]
                            |
                    ( NAT / MASQUERADE )
                            |
                   [ Host - Arch Linux ]
                        192.168.1.1
                            |
                      [ Linux Bridge ]
         -------------------------------------------------
        |             |               |                |
 [VM1 - virt-manager] [VM2 - virt-manager] [VM3 - VirtualBox] [Docker Containers]
  192.168.1.10         192.168.1.201       192.168.1.202  
                                                |                 
                         ------------------------------------------
                        |                                          |
             [Container1 - nginx]                        [Container2 - Portainer]
               192.168.1.20                                192.168.1.21

```

👀 **Implementations**
  - [Linux Bridge](/linux-bridge.md)
  - [Libvirt Networking](/libvirt.md)