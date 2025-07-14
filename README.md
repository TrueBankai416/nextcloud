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
docker run -d \
  --name nextcloud \
  -p 8080:80 \
  -p 7867:7867 \
  -v nextcloud_data:/var/www/html \
  your-registry/nextcloud:latest
```

### Docker Compose
```yaml
version: '3.8'
services:
  nextcloud:
    image: your-registry/nextcloud:latest
    ports:
      - "8080:80"
      - "7867:7867"  # notify_push port
    volumes:
      - nextcloud_data:/var/www/html
    environment:
      - NEXTCLOUD_ADMIN_USER=admin
      - NEXTCLOUD_ADMIN_PASSWORD=secure_password
      - MYSQL_HOST=db
      - MYSQL_DATABASE=nextcloud
      - MYSQL_USER=nextcloud
      - MYSQL_PASSWORD=secure_db_password
    depends_on:
      - db
      - redis

  db:
    image: mariadb:10.6
    environment:
      - MYSQL_ROOT_PASSWORD=root_password
      - MYSQL_DATABASE=nextcloud
      - MYSQL_USER=nextcloud
      - MYSQL_PASSWORD=secure_db_password
    volumes:
      - db_data:/var/lib/mysql

  redis:
    image: redis:7-alpine
    volumes:
      - redis_data:/data

volumes:
  nextcloud_data:
  db_data:
  redis_data:
```

## notify_push Configuration

The notify_push service is automatically configured and runs on port 7867. To use it:

1. **Install the notify_push app** (automatically done on first run)
2. **Configure your reverse proxy** to handle WebSocket connections on `/push`
3. **Test the connection**:
   ```bash
   php occ notify_push:self-test
   ```

### Nginx Configuration Example
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

## Building the Image

```bash
docker build -t your-registry/nextcloud:latest .
```

## Troubleshooting

### notify_push Issues
1. Check if the service is running: `docker exec container_name supervisorctl status notify_push`
2. Test the connection: `docker exec -u www-data container_name php occ notify_push:self-test`
3. Check logs: `docker logs container_name`

### Memory Issues
If you encounter memory issues with large photo libraries:
```bash
docker run -e PHP_MEMORY_LIMIT=2048M your-registry/nextcloud:latest
```

## Support

For issues related to:
- **Base Nextcloud functionality**: See [official Nextcloud documentation](https://docs.nextcloud.com/)
- **notify_push**: See [notify_push repository](https://github.com/nextcloud/notify_push)
- **Memories app**: See [Memories documentation](https://memories.gallery/)
- **Recognize app**: See [Recognize repository](https://github.com/nextcloud/recognize)
