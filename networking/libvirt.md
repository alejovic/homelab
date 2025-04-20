# Networking - Homelab

### 🔥 Best Choice for Homelab

Why?
- Ease of use for VM
-  DHCP/NAT services built-in (dnsmasq + iptables rules automatically)
- Integration with virt-manager or virsh
- Portable
- It creates a macvlan that can be reused by docker

### 🤓 Libvirt Network

A Libvirt network is a managed network on top of what Linux already provides (including Linux bridges). When you create a network in virsh (or virt-manager), behind the scenes, libvirt usually creates a Linux bridge plus maybe dnsmasq for DHCP, NAT rules for internet access, etc.

It's basically an orchestrated or automated network setup.

In fact, virsh net just manages Linux bridges (and extra stuff) for you.

**Expected**

Everyone is on the same subnet (like 192.168.1.0/24) → Full communication ✅
```
[ Host Machine ]
    |
    |-- virbr0 NAT (default libvirt)
    |-- virbr0 BRIDGE (default libvirt) <--- All attached here
    |-- dnsmasq  DNS (libvirt) <--- attached to the network
          |
          |-- [Docker Containers]
          |-- [Minikube]
          |-- [VM1]
          |-- [VM2]
          |-- [Host Itself]
```

+ virbr0 is NAT-only (libvirt makes it for VMs behind NAT).
+ you can start minikube like this: minikube start --driver=kvm2 --network=virbr0 and use the same network segment.
- Host and Docker don't attach there automatically, we'd need a docker bridge network.

This is waht a Libvirt network looks like:

virsh network (default)
```sh
⋊> ~ sudo virsh net-list --all                                                                 
[sudo] password for avictoria:
 Name          State      Autostart   Persistent
--------------------------------------------------
 default       active     no          yes
```
default → virbr0
```sh
5: virbr0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc htb state UP group default qlen 1000
    link/ether 52:54:00:15:d9:76 brd ff:ff:ff:ff:ff:ff
    inet 192.168.1.1/24 brd 192.168.1.255 scope global virbr0
       valid_lft forever preferred_lft forever
```
### 👀 **Steps**

### **Step 1:Create a custom virsh network**

Enable NAT + forwarding by adding the interface, e.g wlan0

We could create the network in virt-manager, the XML outcome is:
```xml
<network connections="3">
  <name>default</name>
  <uuid>156055ce-07c9-43a4-8b49-72c455d14b2a</uuid>
  <forward dev="wlan0" mode="nat">
    <nat>
      <port start="1024" end="65535"/>
    </nat>
    <interface dev="wlan0"/>
  </forward>
  <bridge name="virbr0" stp="on" delay="0"/>
  <mac address="AA:BB:CC:00:11:22"/>
  <domain name="default"/>
  <ip address="192.168.1.1" netmask="255.255.255.0">
    <dhcp>
      <range start="192.168.1.128" end="192.168.1.254"/>
    </dhcp>
  </ip>
</network>
```

if using virsh, then create the file `bridge-network.xml`
```xml
<network>
  <name>virbr0</name>
  <forward mode='bridge'/>
  <bridge name='virbr0' />
</network>
```
```sh
virsh net-define bridge-network.xml
virsh net-autostart virbr0
virsh net-start virbr0
```
✅ Now virbr0 will behave as a pure Linux bridge.

```
# Move IP from eth0 to bridge virbr0
ip addr flush dev eth0
ip link set eth0 up
ip link set virbr0 up
ip addr add 192.168.1.1/24 dev virbr0
ip route add default via 192.168.1.1
brctl addif virbr0 eth0

```
✅ Now the host itself talks through virbr0

**Note:** 
- Assuming eth0 has access to internet, you can edit the xml and enable NAT + Forwarding features.
-  `ip link add` is not persistent across reboots by default. I covered it on the [Linux Bridge](/linux-bridge.md) tutorial


### **Step 3: Attach Docker containers to virbr0**
Docker by default uses its own bridge (docker0).
You need to make a custom Docker network using virbr0:
```sh
docker network create \
  --driver=bridge \
  --subnet=192.168.1.0/24 \
  --opt "com.docker.network.bridge.name"="virbr0" \
  docker-virbr0

```
🤓  ***virbr0*** is a macvlan network type
```sh
docker run  \
--name alpine-test --hostname alpine-test \
--network docker-virbr0 --ip 192.168.1.201  \
-it alpine sh
```
**Considerations:** 

#### DHCP
Using DHCP for containers interferes with Docker's network management. While it's technically possible, it falls outside the recommended setup for development purposes.

⚡ Hint: `--ip 192.168.1.201` or `--ip-range=192.168.1.200/29` then containers attached to my-macvlan will get IPs between 192.168.1.201 and 192.168.1.206.

#### DNS
Docker uses 127.0.0.11 for its embedded DNS server.

In /etc/docker/daemon.json, define your preferred DNS servers:
```
{
  "dns": ["192.168.1.1", "8.8.8.8"],
  "dns-search": ["home"]
}
```
Then restart Docker.



### **Step 4: Update Libvirt (virt-manager) to use the bridge**
Open virt-manager GUI

Edit → Connection Details → Virtual Networks → Start virbr0

or Add: 
- Add new NIC to VM
- Network source → virbr0
- Device model → virtio (faster)


```
[ Host 192.168.1.1 ]
    |-- virbr0 (NAT, Linux Bridge) <--- All attached here
      |-- dnsmasq; (DNS)
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
                        [ wlan0 ]
                            |
                    ( NAT / MASQUERADE )
                            |
                   [ Host - Arch Linux ]
                        192.168.1.1
                            |
                        [ virbr0 ]
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