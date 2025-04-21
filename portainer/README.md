# Portainer - Homelab

### 🔥 Best Choice for Homelab

Portainer is a great choice for managing Docker containers in a homelab environment. It provides a user-friendly web interface for managing Docker containers, images, networks, and volumes, making it easy to deploy and manage applications in your homelab.

### 🤓 Portainer
* Portainer is a lightweight management UI that allows you to easily manage your Docker containers, images, networks, and volumes. It provides a simple and intuitive web interface for managing your Docker environment.
* It can be installed as a Docker container, making it easy to deploy and manage.
* Portainer supports multiple Docker environments, allowing you to manage multiple Docker hosts from a single interface.
* It provides features like user management, role-based access control, and activity logging, making it suitable for team environments.
* Portainer also supports Kubernetes, allowing you to manage both Docker and Kubernetes environments from a single interface.
* It is highly configurable and can be integrated with other tools like Prometheus for monitoring and Grafana for visualization.

### Expected
- Easy to integrate with libvirt and docker network
- User management and role-based access control
- Activity logging
- Integration with other tools like Prometheus and Grafana
- Support for Kubernetes
- Web interface for managing Docker containers, images, networks, and volumes
- Lightweight and easy to deploy

### 👀 **Steps setup portainer:**

**Option 1:** Docker run command
```sh
docker run -d \
  --name svc.portainer \
  --hostname portainer.local-lab.site \
  --restart unless-stopped \
  -p 9000:9000 \
  --network docker-homelan --ip 192.168.8.3 \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v ./portainer_data:/data \
  portainer/portainer-ce:lts
```

**Option 2:** [docker-compose](docker-compose.yml) file