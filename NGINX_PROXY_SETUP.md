# Nginx Proxy Setup Guide

This guide explains how to configure nginx for different deployment scenarios with your Nextcloud setup.

## 🏗️ **Two Deployment Options**

### **Option 1: External Nginx + Internal Nginx (Recommended)**
Perfect for existing nginx installations or multi-service setups.

### **Option 2: Direct External Nginx**
For standalone Nextcloud deployments without existing nginx.

---

## 🚀 **Option 1: External Nginx + Internal Nginx**

### **Architecture**
```
Internet → External Nginx (SSL, :80/:443) → Internal Nginx (:11000) → Services
                                                    ├─ / → Nextcloud
                                                    ├─ /collabora/ → Collabora
                                                    └─ /push/ → notify_push
```

### **1. Docker Compose Configuration**
```bash
# .env
NEXTCLOUD_DOMAIN=cloud.example.com
NGINX_INTERNAL_PORT=11000  # Port for external nginx to connect to

# Start services
docker-compose --profile with-nginx --profile with-collabora up -d
```

### **2. External Nginx Configuration**
```nginx
# /etc/nginx/sites-available/nextcloud
server {
    listen 80;
    listen 443 ssl http2;
    server_name cloud.example.com;
    
    # SSL configuration
    ssl_certificate /path/to/your/cert.pem;
    ssl_certificate_key /path/to/your/key.pem;
    
    # Proxy everything to internal nginx
    location / {
        proxy_pass http://127.0.0.1:11000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Forwarded-Host $host;
        proxy_set_header X-Forwarded-Port $server_port;
        
        # WebSocket support
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection $connection_upgrade;
        
        # Timeouts and buffering
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
        proxy_buffering off;
        proxy_request_buffering off;
        
        # Large file uploads
        client_max_body_size 2048M;
    }
}

# WebSocket upgrade map
map $http_upgrade $connection_upgrade {
    default upgrade;
    '' close;
}
```

### **3. Enable External Nginx**
```bash
# Create and enable the site
sudo ln -s /etc/nginx/sites-available/nextcloud /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

---

## 🌐 **Option 2: Direct External Nginx**

### **Architecture**
```
Internet → Direct Nginx (SSL, :80/:443) → Services
                    ├─ / → Nextcloud
                    ├─ /collabora/ → Collabora
                    └─ /push/ → notify_push
```

### **1. Docker Compose Configuration**
```bash
# .env
NEXTCLOUD_DOMAIN=cloud.example.com
HTTP_PORT_NGINX=80
HTTPS_PORT=443

# Start services with external nginx
docker-compose --profile with-nginx-external --profile with-collabora up -d
```

### **2. SSL Certificate Setup**
```bash
# Place your SSL certificates in ./ssl/
mkdir -p ssl
cp /path/to/your/cert.pem ssl/
cp /path/to/your/key.pem ssl/
```

---

## 📊 **Comparison: External vs Direct**

| Feature | External + Internal | Direct External |
|---------|-------------------|-----------------|
| **SSL Management** | Host nginx | Container nginx |
| **Multiple Services** | Easy to add | Container only |
| **Certificate Updates** | Host system | Container restart |
| **Performance** | Two-tier proxy | Single proxy |
| **Flexibility** | High | Medium |
| **Complexity** | Medium | Low |

---

## 🔧 **Environment Variables**

### **Common Variables**
```bash
# Domain configuration
NEXTCLOUD_DOMAIN=cloud.example.com

# Collabora configuration
COLLABORA_PORT=9980
COLLABORA_USERNAME=admin
COLLABORA_PASSWORD=change_me_collabora_password

# notify_push configuration
NOTIFY_PUSH_PORT=7867
```

### **External + Internal Nginx**
```bash
# Internal nginx port for external proxy
NGINX_INTERNAL_PORT=11000
```

### **Direct External Nginx**
```bash
# External ports
HTTP_PORT_NGINX=80
HTTPS_PORT=443
```

---

## 🚀 **Quick Start Commands**

### **External + Internal Setup**
```bash
# 1. Configure external nginx (see above)
# 2. Set environment variables
echo "NEXTCLOUD_DOMAIN=cloud.example.com" > .env
echo "NGINX_INTERNAL_PORT=11000" >> .env

# 3. Start services
docker-compose --profile with-nginx --profile with-collabora up -d

# 4. Configure Nextcloud Office
# URL: https://cloud.example.com/collabora/
```

### **Direct External Setup**
```bash
# 1. Set environment variables
echo "NEXTCLOUD_DOMAIN=cloud.example.com" > .env
echo "HTTP_PORT_NGINX=80" >> .env
echo "HTTPS_PORT=443" >> .env

# 2. Place SSL certificates in ./ssl/
mkdir -p ssl
# Copy your certificates here

# 3. Start services
docker-compose --profile with-nginx-external --profile with-collabora up -d

# 4. Configure Nextcloud Office
# URL: https://cloud.example.com/collabora/
```

---

## 🔍 **Troubleshooting**

### **External + Internal Issues**
```bash
# Check internal nginx is running
docker logs nextcloud_nginx

# Test internal nginx connection
curl -H "Host: cloud.example.com" http://127.0.0.1:11000/status.php

# Check external nginx logs
sudo tail -f /var/log/nginx/error.log
```

### **Direct External Issues**
```bash
# Check container nginx
docker logs nextcloud_nginx_external

# Test direct connection
curl -k https://cloud.example.com/status.php

# Check SSL certificates
openssl s_client -connect cloud.example.com:443
```

### **Common Issues**
- **Port conflicts**: Ensure no other services use your configured ports
- **SSL certificates**: Verify certificate paths and permissions
- **WebSocket issues**: Check upgrade headers in nginx config
- **Large uploads**: Verify client_max_body_size settings

---

## 🎯 **Best Practices**

### **Security**
- Use HTTPS in production
- Keep SSL certificates updated
- Bind internal nginx to localhost only
- Use strong passwords in `.env`

### **Performance**
- Enable gzip compression
- Use HTTP/2 for better performance
- Configure proper timeouts
- Monitor resource usage

### **Maintenance**
- Regular backup of configurations
- Monitor nginx logs
- Update containers regularly
- Test configuration changes

---

## 📚 **Related Documentation**

- [COLLABORA_SETUP.md](./COLLABORA_SETUP.md) - Collabora configuration details
- [README.md](./README.md) - General setup and usage
- [.env.example](./.env.example) - All environment variables
