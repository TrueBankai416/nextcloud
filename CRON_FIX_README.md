# Nextcloud Cron Fix

This update resolves issues with Nextcloud background jobs getting stuck with epoch timestamps (1970-01-01).

## Changes Made

### 1. Fixed Dockerfile
- **Before**: Added specific cron jobs for face recognition and preview generation
- **After**: Uses the standard Nextcloud cron job (`cron.php`) that handles all background tasks
- **Why**: Nextcloud's `cron.php` is the recommended way to handle background jobs and manages all tasks internally

### 2. Improved cron.sh
- Added proper crontab setup with permissions
- Ensures the cron job exists even if the container restarts
- Better logging and error handling

### 3. Added Cleanup Script
- `cleanup-stuck-jobs.sh`: Safely removes stuck background jobs from the database
- Counts stuck jobs before deletion
- Deletes in batches to avoid database lock issues
- Resets the background job system after cleanup

## How to Use

### 1. Rebuild Your Containers
```bash
docker-compose down
docker-compose build --no-cache
docker-compose up -d
```

### 2. Clean Up Existing Stuck Jobs (if needed)
```bash
# Make the cleanup script executable
chmod +x cleanup-stuck-jobs.sh

# Run the cleanup (it automatically loads credentials from your .env file)
./cleanup-stuck-jobs.sh
```

### 3. Verify the Fix
After rebuilding, check your Nextcloud admin panel:
- Go to Settings > Administration > Basic settings
- The background jobs section should show recent execution times
- The red warning about old cron jobs should disappear

## Technical Details

### Why This Fixes the Issue

1. **Proper Cron Job**: Uses Nextcloud's official `cron.php` instead of specific OCC commands
2. **Correct Timing**: Runs every 5 minutes as recommended by Nextcloud
3. **Job Management**: Nextcloud's cron system properly manages job timing and prevents stuck jobs
4. **Memory Efficiency**: The main cron.php is more memory-efficient than running individual OCC commands

### Cron Job Comparison

| Old Approach | New Approach |
|--------------|--------------|
| `12 * * * * php /var/www/html/occ face:background_job` | `*/5 * * * * php /var/www/html/cron.php` |
| `37 * * * * php /var/www/html/occ preview:pre-generate` | (All tasks managed by cron.php) |

The new approach lets Nextcloud handle all background tasks through its internal job scheduler, which is more reliable and prevents timestamp issues.
