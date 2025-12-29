# Collabora Online Setup Guide

This guide shows how to configure Collabora Online to work with the same domain as Nextcloud, eliminating the need for a separate domain.

## 🎯 **Single Domain Setup (Recommended)**

### 1. Environment Configuration

In your `.env` file, set:
```bash
# Your main domain
NEXTCLOUD_DOMAIN=your-domain.com
PORT=8080

# Collabora will use the same domain
COLLABORA_USERNAME=admin
COLLABORA_PASSWORD=change_me_collabora_password
```

### 2. Start Services

```bash
# Start with Nginx and Collabora
docker-compose --profile with-nginx --profile with-collabora up -d
```

### 3. Configure Nextcloud

1. **Access Nextcloud Admin Settings**:
   - Go to `Settings > Administration > Office`

2. **Configure Collabora Integration**:
   - **Use your own server**: Select this option
   - **Collabora Online server**: Enter one of these URLs:
     - With Nginx: `https://your-domain.com/collabora/`
     - Direct access: `http://your-domain.com:9980/`

3. **Test the Connection**:
   - Click "Save" and test by creating a new document

## 🔧 **Configuration Options**

### Option A: Behind Nginx Proxy (Recommended)
```bash
# .env configuration
NEXTCLOUD_DOMAIN=your-domain.com
HTTP_PORT_NGINX=80
HTTPS_PORT=443

# In Nextcloud Office settings
Collabora URL: https://your-domain.com/collabora/
```

**Benefits:**
- Single domain for everything
- HTTPS termination at proxy
- Better security and performance

### Option B: Direct Access
```bash
# .env configuration  
NEXTCLOUD_DOMAIN=your-domain.com
COLLABORA_PORT=9980
PORT=8080

# In Nextcloud Office settings
Collabora URL: http://your-domain.com:9980/
```

**Benefits:**
- Simpler setup
- No proxy configuration needed

## 🐳 **Docker Compose Profiles**

### Basic Setup (Nextcloud + Collabora)
```bash
docker-compose --profile with-collabora up -d
```

### Production Setup (Nextcloud + Nginx + Collabora)
```bash
docker-compose --profile with-nginx --profile with-collabora up -d
```

## 🔍 **Troubleshooting**

### Connection Issues
1. **Check Collabora status**:
   ```bash
   docker exec -it collabora curl -f http://localhost:9980/
   ```

2. **Check Nextcloud logs**:
   ```bash
   docker logs nextcloud
   ```

3. **Test direct access**:
   - Visit `http://your-domain.com:9980/` directly
   - You should see the Collabora welcome page

### Domain Configuration Issues
1. **Check environment variables**:
   ```bash
   docker exec -it collabora env | grep domain
   ```

2. **Verify Nextcloud trusted domains**:
   ```bash
   docker exec -u www-data nextcloud php occ config:system:get trusted_domains
   ```

### SSL/HTTPS Issues
1. **For Nginx setup**: Ensure SSL certificates are properly configured
2. **For HTTP setup**: Use HTTP URLs consistently (no mixing HTTP/HTTPS)

## 📋 **Nextcloud Office App Configuration**

After setup, configure the Nextcloud Office app:

1. **Install the app**:
   ```bash
   docker exec -u www-data nextcloud php occ app:install richdocuments
   ```

2. **Enable the app**:
   ```bash
   docker exec -u www-data nextcloud php occ app:enable richdocuments
   ```

3. **Configure the server URL**:
   ```bash
   # For Nginx proxy setup
   docker exec -u www-data nextcloud php occ config:app:set richdocuments wopi_url --value="https://your-domain.com/collabora/"
   
   # For direct access setup
   docker exec -u www-data nextcloud php occ config:app:set richdocuments wopi_url --value="http://your-domain.com:9980/"
   ```

## 🚀 **Testing Your Setup**

1. **Create a new document** in Nextcloud Files
2. **Click on it** to open in Collabora
3. **Edit and save** to confirm everything works

## 🔒 **Security Considerations**

- Use HTTPS in production (`--profile with-nginx`)
- Keep Collabora behind the proxy (don't expose port 9980 directly)
- Use strong passwords in your `.env` file
- Consider firewall rules to restrict access

## 📚 **Additional Resources**

- [Collabora Online Documentation](https://sdk.collaboraonline.com/docs/installation/index.html)
- [Nextcloud Office App Documentation](https://docs.nextcloud.com/server/latest/admin_manual/office/index.html)
