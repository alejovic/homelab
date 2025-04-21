# Kubernetes - Homelab

### 🔥 Best Choice for Homelab?

minikube is a great choice for local Kubernetes development and testing. It allows you to run a single-node Kubernetes cluster on your local machine, making it easy to experiment with Kubernetes features and configurations.

**⚡ Note:** You need docker or a VM driver (like KVM) to run minikube. It is not a full-fledged Kubernetes cluster but rather a simplified version for local development.

I still recommend using k3s for better performance and resource management in a homelab environment. k3s is a lightweight Kubernetes distribution that is optimized for resource-constrained environments, making it ideal for homelabs.

### 🤓 minikube

Minikube is a lightweight Kubernetes implementation that runs a single-node cluster on your local machine. It is ideal for development, testing, and learning Kubernetes without needing a full-scale cluster.

**Use Cases:**
- Local Development: Test Kubernetes configurations and applications locally.
- Learning Kubernetes: Experiment with Kubernetes features in a controlled environment.
- CI/CD Pipelines: Use Minikube for testing Kubernetes deployments in CI workflows.
- Integration Testing: Validate how applications interact within a Kubernetes cluster.
- Homelab Setup: Integrate with tools like libvirt, Docker, and Portainer for a self-contained Kubernetes environment.

**Expected**
- Easy to integrate with libvirt network
- Integration with KVM, Docker
- Integration with Portainer
- Developer Experience

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
                        [ virbr0 (bridge - libvirt) ]
         -------------------------------------------------
        |             |               |                |
 [VM1 - virt-manager] [VM2 - virt-manager] [VM3 - VirtualBox] [Docker Containers]
  192.168.1.10         192.168.1.201       192.168.1.202        192.168.1.100/27 (30 containers)
                                                                     |
                                            -------------------------------------------------
                                            |                      |                          |
                                 [Container1 - nginx]   [Container2 - Portainer]   [Minikube (Docker driver + KVM)]
                                    192.168.1.101             192.168.1.102                 192.168.1.103   
                                                                                                  |
                                                                                 -------------------------------
                                                                                |               |               |
                                                                          [k8s Pod1]     [k8s Pod2]     [k8s Pod3]

```

### 👀 **Steps to start Minikube with KVM on a specific libvirt network:**

Make sure to have the following installed:
```shell
⋊> ~ sudo virsh net-list --all                                                                                                                                                                 20:30:02
 Name      State    Autostart   Persistent
--------------------------------------------
 default   active   yes         yes
```
Once we have the network up and running, we can start Minikube with the `kvm2` driver and specify the network to use.
Use the `--kvm-network` flag to specify the custom libvirt network
```shell
minikube start --driver=kvm2 --kvm-network=default
```

You can also customize the vCPU, RAM, and other parameters for Minikube:
```shell
minikube start --driver=kvm2 --kvm-network=br-homelan --cpus=2 --memory=4096
```
Workaround for the `--kvm-network` flag:'
```shell
minikube start --driver=kvm2 --kvm-network=br-homelan

# docker network
minikube start --driver=docker --network docker-homelan --static-ip=192.168.8.10
````

What if you want to use a different network? You can create a new network in libvirt and specify it when starting Minikube:
```shell
virsh net-define /etc/libvirt/qemu/networks/net-homelan.xml
virsh net-startnet-homelan
virsh net-autostart net-homelan
```
The XML (/etc/libvirt/qemu/networks/net-homelan.xml) might look like this:
```xml
<network>
  <name>net-homelan</name>
  <bridge name="virbr0" />
  <ip address="192.168.100.1" netmask="255.255.255.0">
    <dhcp>
      <range start="192.168.100.100" end="192.168.100.200" />
    </dhcp>
  </ip>
</network>
```
Then, start minikube
```ssh
minikube start --driver=kvm2 --kvm-network=net-homelan
minikube ssh
ip addr show
```