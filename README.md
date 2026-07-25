# Enhanced Nextcloud Docker Image

This is an enhanced Nextcloud Docker image with additional features for better performance and functionality.

## Key Features

### 🚀 notify_push Support
- **Real-time notifications**: Includes the notify_push binary for instant client notifications
- **Proper container integration**: Uses supervisord instead of systemd for container-friendly operation
- **Automatic setup**: Automatically installs and configures the notify_push app on first run

### 📸 Nextcloud Memories Support
- **Video processing**: Includes ffmpeg for video transcoding and preview generation
- **Metadata extraction**: Includes exiftool for reading photo/video metadata
- **Optimized performance**: Enhanced PHP configuration for better memory handling

### 🤖 Nextcloud Recognize Support
- **Face recognition**: Includes dlib and pdlib for advanced face recognition capabilities
- **Machine learning**: Pre-built with optimized machine learning libraries
- **Background processing**: Configured cron jobs for automated face recognition processing

### 🔧 Additional Improvements
- **Supervisor process management**: Proper multi-process container management
- **Enhanced PHP configuration**: Optimized memory limits and opcache settings
- **Better logging**: Structured logging for all services
- **Health checks**: Built-in health monitoring

## Usage

### Basic Usage
```bash
sudo docker run -d \
  --name nextcloud \
  -p 8080:80 \
  -p 7867:7867 \
  -v nextcloud_data:/var/www/html \
  your-registry/nextcloud:latest
```

### Docker Compose (Recommended)

A comprehensive `docker-compose.yaml` file is included with the following services:

#### Basic Setup
```bash
# Copy environment file and customize
cp .env.example .env
# Edit .env file with your passwords and configuration

# Start with basic services
sudo docker compose up -d
```

#### With Nginx Reverse Proxy
```bash
# Start with Nginx for HTTPS and WebSocket handling
sudo docker compose --profile with-nginx up -d
```

#### With Collabora Online
```bash
# Start with document editing support
sudo docker compose --profile with-collabora up -d
```

#### Full Setup with All Services
```bash
# Start with all optional services
sudo docker compose --profile with-nginx --profile with-collabora up -d
```

**Services included:**
- **nextcloud**: Enhanced Nextcloud with notify_push
- **db**: MariaDB database with optimized configuration
- **redis**: Redis for caching and session storage
- **nginx**: (Optional) Reverse proxy with SSL and WebSocket support
- **collabora**: (Optional) Document editing server

## notify_push Configuration

The notify_push service is automatically configured and runs on port 7867. To use it:

1. **Install the notify_push app** (automatically done on first run)
2. **Configure your reverse proxy** to handle WebSocket connections on `/push`
3. **Test the connection**:
   ```bash
   docker exec -u www-data nextcloud php occ notify_push:self-test
   ```

### Using the Included Nginx Configuration

The included `docker-compose.yaml` provides a pre-configured Nginx reverse proxy:

```bash
# Start with Nginx reverse proxy
sudo docker compose --profile with-nginx up -d
```

The `nginx.conf` file includes:
- Proper WebSocket handling for notify_push
- Rate limiting for login attempts
- SSL/HTTPS support (configuration included)
- Optimized static file caching
- Large file upload support

### Manual Nginx Configuration
If using your own Nginx setup:
```nginx
location /push/ {
    proxy_pass http://127.0.0.1:7867/;
    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection "Upgrade";
    proxy_set_header Host $host;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
}
```

## Recommended Apps

This image is optimized for these Nextcloud apps:

- **[notify_push](https://github.com/nextcloud/notify_push)**: Real-time notifications (auto-installed)
- **[Memories](https://github.com/pulsejet/memories)**: Fast photo and video gallery
- **[Recognize](https://github.com/nextcloud/recognize)**: Object recognition and face clustering
- **[Face Recognition](https://github.com/matiasdelellis/facerecognition)**: Advanced face recognition

## Environment Variables

All standard Nextcloud environment variables are supported, plus:

- `NEXTCLOUD_UPDATE=1`: Enables automatic updates (default: enabled)
- `PORT=7867`: notify_push service port (default: 7867)

## Performance Tuning

The image includes several performance optimizations:

- **PHP memory limit**: 1024M (configurable via PHP_MEMORY_LIMIT)
- **OPcache memory**: 512M (optimized for larger installations)
- **APCu**: Enabled for CLI operations
- **Background jobs**: Configured for face recognition and preview generation

## Quick Start

### 1. Clone and Configure
```bash
git clone <repository-url>
cd nextcloud
cp .env.example .env
# Edit .env with your secure passwords
```

### 2. Start Services
```bash
# Basic setup
sudo docker compose up -d

# Or with Nginx reverse proxy
sudo docker compose --profile with-nginx up -d

# Or with all services
sudo docker compose --profile with-nginx --profile with-collabora up -d
```

### 3. Access Nextcloud
- **HTTP**: http://localhost:8080
- **HTTPS** (with nginx): https://localhost
- **notify_push**: WebSocket on port 7867

### 4. Verify notify_push
```bash
sudo docker exec -u www-data nextcloud php occ notify_push:self-test
```

## Building the Image

```bash
sudo docker build -t your-registry/nextcloud:latest .
```

## Configuration Files

- **docker-compose.yaml**: Complete multi-service setup
- **nginx.conf**: Reverse proxy configuration with WebSocket support
- **.env.example**: Environment variables template
- **README.md**: This documentation

## Troubleshooting

### notify_push Issues
1. Check if the service is running: `docker exec container_name supervisorctl status notify_push`
2. Test the connection: `docker exec -u www-data container_name php occ notify_push:self-test`
3. Check logs: `docker logs container_name`

### Memory Issues
If you encounter memory issues with large photo libraries:
```bash
sudo docker run -e PHP_MEMORY_LIMIT=2048M your-registry/nextcloud:latest
```

## Support

For issues related to:
- **Base Nextcloud functionality**: See [official Nextcloud documentation](https://docs.nextcloud.com/)
- **notify_push**: See [notify_push repository](https://github.com/nextcloud/notify_push)
- **Memories app**: See [Memories documentation](https://memories.gallery/)
- **Recognize app**: See [Recognize repository](https://github.com/nextcloud/recognize)
