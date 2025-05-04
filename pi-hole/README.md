# Networking Pi-hole DHCP && DNS - Homelab

### 🔥 Best Choice for Homelab

pi-hole is a great choice for a homelab DNS server. It provides ad-blocking, tracking protection, and DNS caching, making it an excellent addition to your home network.

### 🤓 Pi-hole
* Pi-hole is a network-wide ad blocker that acts as a DNS sinkhole. It intercepts DNS queries and blocks requests to known ad-serving domains, effectively preventing ads from being displayed on devices connected to your network.
* It can be installed on various platforms, including Raspberry Pi, Docker, and virtual machines. Pi-hole also provides a web interface for monitoring and managing DNS queries and blocked domains.
* It is highly configurable and can be integrated with other tools like Unbound for DNS-over-HTTPS (DoH) or DNS-over-TLS (DoT) for enhanced privacy and security.
* It can also be used in conjunction with other DNS servers like Unbound or dnscrypt-proxy for added security and privacy.

### Expected
- Easy to integrate with libvirt and docker network
- DNS caching
- Web interface for monitoring and managing DNS queries
- Highly configurable
- Integration with other tools like Unbound for DNS-over-HTTPS (DoH) or DNS-over-TLS (DoT) for enhanced privacy and security

key points:
- Pi-hole uses its own embedded dnsmasq, but it’s actually managed by FTL (pihole-FTL), a fork of dnsmasq.
- You cannot just "mount" your existing dnsmasq config into Pi-hole, because Pi-hole expects to control its whole DNS setup.
- However, you can migrate most of your current dnsmasq settings to Pi-hole’s custom.dnsmasq config, or mount your settings in the right place.

⚠️ **Warning:**
- Your existing `dnsmasq` is being used by `libvirt` (for VM network management — `virbr0` default network uses it).
- If you stop the system-wide `dnsmasq`, you might break `libvirt` networking unless you manage it carefully.
- `libvirt` runs its own `dnsmasq` instance separately, not system-wide. So it might not conflict unless you installed and started your own global dnsmasq service.

`libvirt` spawns its own dnsmasq instance per network (like virbr0), it doesn't use the system dnsmasq.
That small dnsmasq listens only on the virtual network, not on your host's main IP.

🛠️ Clean Plan:

Arch Linux Host — wlan0 is uplink to internet (e.g., your Wi-Fi).

* Create a new bridge br-homelan.
* Attach a dummy device dummy0 to the bridge (so the host is inside).
* Create a libvirt network using br-homelan.
* Create a Docker network using br-homelan.
* Install Pi-hole in Docker.
* Set all VMs + Containers to use Pi-hole for DNS.

The lab was implemented in the section [networking/linux-bridge-pihole.md](../networking/linux-bridge-pihole.md)
```
[ Arch Host (192.168.8.2) ]
    ↳ br-homelan ← software bridge (192.168.8.1/24)
        ↳ Pi-hole (Docker container, separate IP 192.168.8.2)
        ↳ libvirt VMs (internal bridge virbr0, 192.168.8.x)
```

### 👀 **Steps to install Pi-hole:**

**Option 1:** docker run command
```sh
docker run -d \
  --name svc.pihole \
  --hostname pihole.local-lab.site \
  --network docker-homelan \
  --ip 192.168.8.2 \
    -p 53:53/tcp \
    -p 53:53/udp \
    -p 80:80 \
    -p 443:443 \
    -p 67:67/udp \
  -e TZ="Australia/Melbourne" \
  -e WEBPASSWORD="yourpassword" \
  -e DHCP_ACTIVE="true" \
  -e DHCP_START="192.168.8.100" \
  -e DHCP_END="192.168.8.200" \
  -e DHCP_ROUTER="192.168.8.1" \
  -e DHCP_LEASETIME="24h" \
  -e PIHOLE_INTERFACE="br-homelan" \
  --cap-add=NET_ADMIN \
  -v "./etc-pihole:/etc/pihole" \
  -v "./etc-dnsmasq.d:/etc/dnsmasq.d" \
  --restart unless-stopped \
  pihole/pihole:latest
```

**Option 2:** [docker-compose](docker-compose.yml) file

## Add traefik labels

To enable Traefik to route traffic to the Pi-hole container, you need to add the following labels to the `pihole` service in your `docker-compose.yml` file. This will allow Traefik to handle incoming requests and direct them to the Pi-hole service.

```yaml
  labels:
    - "traefik.enable=true"
    - "traefik.http.routers.pihole.rule=Host(`pihole.local.local-lab.sites`)" #CNAME
    - "traefik.http.services.pihole.loadbalancer.server.port=80"
    - "traefik.http.routers.pihole.entrypoints=web"
    - "traefik.http.routers.pihole.middlewares=auth"
```