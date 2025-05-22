# Homepage - Homelab

### 🤓 Homepage 
https://github.com/gethomepage/homepage

The homepage is a simple, static website that serves as a central hub for your homelab. It can provide links to all your services, documentation, and any other resources you want to share. It's lightweight and easy to set up, making it perfect for a homelab environment.
### Expected
- **Easy to set up**: The homepage is a simple static website that can be hosted on any web server.
- **Customizable**: You can easily customize the content and layout to fit your needs.
- **Lightweight**: The homepage is lightweight and doesn't require a lot of resources to run.
- **Easy to integrate with other services**: You can easily link to other services and resources from your homepage.
- **Documentation**: You can use the homepage to document your homelab setup and share it with others.
- **Self-hosted**: You can host the homepage on your own server, giving you full control over your data and privacy.
- **Open-source**: The homepage is open-source, allowing you to contribute to its development and customize it to your liking.
- **Community-driven**: The homepage has a growing community of users and contributors, making it easy to find help and support.

### Installation
**Option 1:**
```sh
docker run --name homepage \
  -e HOMEPAGE_ALLOWED_HOSTS=gethomepage.dev \
  -e PUID=1000 \
  -e PGID=1000 \
  -p 3000:3000 \
  -v /path/to/config:/app/config \
  -v /var/run/docker.sock:/var/run/docker.sock:ro \
  --restart unless-stopped \
  ghcr.io/gethomepage/homepage:latest
 ```
**Option 2:** [docker-compose](docker-compose.yml) file
