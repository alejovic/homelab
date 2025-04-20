# Networking - Homelab

### 🔥 Good Choice for building knowledge

Why?
- Fine-grained manual control (you set up everything yourself).
- DHCP/NAT services (you need to configure yourself)
- No Integration with virt-manager or virsh
- No Portable (attached to the host). Create a VM for this lab instead.


###  🤓 Linux bridge

A Linux bridge (like one created with brctl or ip link add type bridge) is a very basic, low-level network switch at layer 2 (Ethernet). It's simple, flexible, and widely used — especially outside of virtualization too. You manually manage it: create the bridge, add interfaces (like tap devices or physical NICs), set up IPs and routing if needed.

**Expected**

Everyone is on the same bridge → Same subnet (like 192.168.1.0/24) → Full communication ✅
```
[ Host Machine ]
    |
    |-- br-homelan (Linux Bridge) <--- All attached here
          |
          |-- [Docker Containers]
          |-- [Minikube]
          |-- [VM1]
          |-- [VM2]
          |-- [Host Itself]
```

### **Requisites**

Remove or disable all virsh networks if present
```
⋊> ~ sudo virsh net-list --all                                                                 
[sudo] password for avictoria:
 Name          State      Autostart   Persistent
--------------------------------------------------
 default       inactive   no          yes
 lxc-network   active     yes         yes
```
lxc-network → virbr0
```
5: virbr0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc htb state UP group default qlen 1000
    link/ether 52:54:00:78:4a:a1 brd ff:ff:ff:ff:ff:ff
    inet 192.168.122.1/24 brd 192.168.122.255 scope global virbr0
       valid_lft forever preferred_lft forever
```
### 👀 **Steps**

### **Step 1: Create a Linux bridge (br-homelan)**

Option 1: nmcli (network manager)

```sh
# Check devices
nmcli device status
# DEVICE             TYPE      STATE                   CONNECTION
# wlan0              wifi      connected               Altibox362784

# Create bridge
sudo nmcli connection add type bridge ifname br-homelan con-name br-homelan
# Connection 'br-homelan' (fd50db0b-119d-4349-874d-46d38a0fd1be) successfully added.

# Attach real NIC (replace eth0 if different)
# sudo nmcli connection add type bridge-slave ifname eth0 master br0
sudo nmcli connection add type bridge-slave ifname wlan0 master br-homelan

# Configure bridge IP
sudo nmcli connection modify br-homelan ipv4.addresses 192.168.1.1/24
sudo nmcli connection modify br-homelan ipv4.method manual
sudo nmcli connection modify br-homelan ipv6.method ignore

# Bring up the bridge
sudo nmcli connection down "Altibox123456"   # Or your current eth0 connection name
sudo nmcli connection up br-homelan
```

Option 2: ip link add
```sh
# Install required packages (sudo pacman -Rdd iptables)
sudo pacman -Syu bridge-utils dnsmasq iptables-nft

# Create bridge
sudo ip link add name br-homelan type bridge

# Assign an IP to the bridge (new subnet, example 192.168.100.1/24)
sudo ip addr add 192.168.1.1/24 dev br-homelan

# Bring up the bridge
sudo ip link set br-homelan up

# ip link add is not persistent across reboots by default.
sudo nmcli connection modify br-homelan ipv4.addresses 192.168.1.1/24
sudo nmcli connection modify br-homelan connection.autoconnect yes
sudo nmcli connection modify br-homelan ipv4.method manual
sudo nmcli connection modify br-homelan ipv6.method ignore

```

⚡ **Important:**
Don't add wlan0 to the bridge directly. Instead, enable IP forwarding and NAT between br-homelan and wlan0.

🔥 After Bridge Creation
Then enable NAT + forwarding:

2. Enable IP forwarding:
```sh
echo "net.ipv4.ip_forward=1" | sudo tee -a /etc/sysctl.d/99-sysctl.conf
sudo sysctl -p
```
3. Set up NAT:
```sh
# Replace wlan0 if your wireless interface has a different name
sudo iptables -t nat -A POSTROUTING -o wlan0 -j MASQUERADE
sudo iptables -A FORWARD -i br-homelan -o wlan0 -j ACCEPT
sudo iptables -A FORWARD -i wlan0 -o br-homelan -m state --state RELATED,ESTABLISHED -j ACCEPT
```

After you have all your working rules (NAT, FORWARD, etc.), save them:
4. Now, anytime you need to save your iptables rules, you can just run:
```sh
sudo iptables-save | sudo tee /etc/iptables/iptables.rules > /dev/null

# sh script
sudo chmod +x /usr/local/bin/save-iptables.sh
sudo save-iptables.sh
```

⚡ Hint: Restore without rebooting
```sh
sudo iptables-restore < /etc/iptables/iptables.rules
```
Enable the service that loads rules at boot
```sh
sudo systemctl enable iptables
sudo systemctl start iptables
```


### **Step 2: Update Libvirt (virt-manager) to use the bridge**
Open virt-manager GUI

Edit → Connection Details → Virtual Networks → Disable virbr0 if you want

Instead: 
- Add new NIC to VM
- Network source → Specify shared device name → Type br-homelan
- Device model → virtio (faster)


### **Step 3: DNS **
Option 1: Manually set DNS inside the VM
In the VM (Linux guest), edit /etc/resolv.conf:
```
sudo nano /etc/resolv.conf

Add:
nameserver 192.168.1.1
nameserver 8.8.8.8
nameserver 1.1.1.1
```
✅ Now DNS resolution should work.

Option 2: Run a simple dnsmasq DHCP + DNS server on your host

Configure /etc/dnsmasq.conf
```conf
interface=br-homelan

## Don't bind only to interface (optional but good for docker, VMs)
bind-interfaces
dhcp-range=192.168.1.200,192.168.1.250,12h

## Give 192.168.1.1 as gateway and DNS to clients
# Gateway
dhcp-option=3,192.168.1.1

# DNS Server
dhcp-option=6,192.168.1.1

## Forward unknown DNS requests to Google (8.8.8.8) and Cloudflare (1.1.1.1)
# Upstream DNS servers
server=8.8.8.8
server=1.1.1.1
```
Allow DHCP/DNS in your iptables firewall (if needed)
```sh
sudo iptables -A INPUT -i br-homelan -p udp --dport 67:68 --sport 67:68 -j ACCEPT
sudo iptables -A INPUT -i br-homelan -p udp --dport 53 -j ACCEPT
sudo iptables -A INPUT -i br-homelan -p tcp --dport 53 -j ACCEPT

## save
udo iptables-save | sudo tee /etc/iptables/iptables.rules > /dev/null
```
✅ This allows:
- DHCP (ports 67/68 UDP)
- DNS (port 53 TCP/UDP)



⚡ Hint: 
```sh
# check changes..
sudo grep -v -e "^#" -e "^$" /etc/dnsmasq.conf
```

### **Step 3: Create Docker IPvlan network pointing to br-homelan**

```sh
docker network create -d ipvlan \
    --subnet=192.168.1.0/24 \
    --gateway=192.168.1.1 \
    -o parent=br-homelan \
    docker-homelan
```


docker network create -d macvlan \
  --subnet=192.168.1.0/24 \
  --gateway=192.168.1.254 \
  -o parent=br-homelan docker-homelan

sudo ip link add mac-homelan link br-homelan type macvlan mode bridge
# Bring it up
sudo ip addr add 192.168.1.254/24 dev mac-homelan
sudo ip link set mac-homelan up


```
docker run  \
--name alpine-test --hostname alpine-test \
--network docker-homelan --ip 192.168.1.201 --dns 192.168.1.254 \
-it alpine sh
```

🔥 Trooubleshooting
- VM (192.168.1.100) ↔ Container (works ✅)
- Container ↔ Host (broken ❌)
Linux kernel blocks communication between container and parent host (security reason).

```sh
sudo sysctl -w net.ipv4.conf.docker-d0.proxy_arp=1
sudo sysctl -w net.ipv4.conf.br-homelan.proxy_arp=1

nmcli connection add type dummy ifname docker-d0 ip4 192.168.1.254/24
nmcli connection up dummy-docker
```


```
[ Host 192.168.1.1 ]
    |-- dnsmasq; (DNS)
    |-- bridge-slave (NAT) <--- attached to wlan0
      |-- br-homelan (bridge) <--- All attached here
        |
        |-- [VM1 192.168.1.10] (virt-manager, bridged to br-homelan)
        |-- [VM2 192.168.1.201]  (virt-manager, bridged to br-homelan)
        |-- [VM2 192.168.1.202]  (virtualbox, bridged to br-homelan)      
        |-- [Container1 192.168.1.20] (Docker with ipvlan on br-homelan)
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
                      [ br-homelan ]
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