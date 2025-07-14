#!/bin/bash

# Conditional Nextcloud cron script
# Only runs commands for installed and enabled apps

# Colors for logging
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to check if app is installed and enabled
is_app_enabled() {
    local app_name=$1
    php /var/www/html/occ app:list --output=json 2>/dev/null | jq -r '.enabled | keys[]' 2>/dev/null | grep -q "^$app_name$"
}

# Function to check if occ command exists
command_exists() {
    local command=$1
    php /var/www/html/occ list --format=json 2>/dev/null | jq -r '.commands[].name' 2>/dev/null | grep -q "^$command$"
}

# Function to run conditional cron job
run_conditional_job() {
    local app_name=$1
    local command=$2
    local job_name=$3
    
    echo -e "${YELLOW}[$(date)] Checking $job_name...${NC}"
    
    # Check if app is required and installed
    if [ -n "$app_name" ] && ! is_app_enabled "$app_name"; then
        echo -e "${YELLOW}[$(date)] Skipping $job_name - $app_name not installed${NC}"
        return 0
    fi
    
    # Check if command exists
    if ! command_exists "$command"; then
        echo -e "${YELLOW}[$(date)] Skipping $job_name - command '$command' not available${NC}"
        return 0
    fi
    
    # Run the job
    echo -e "${GREEN}[$(date)] Running $job_name...${NC}"
    if php /var/www/html/occ "$command" 2>&1; then
        echo -e "${GREEN}[$(date)] $job_name completed successfully${NC}"
    else
        echo -e "${RED}[$(date)] $job_name failed${NC}"
    fi
}

# Wait for Nextcloud to be ready
echo -e "${YELLOW}[$(date)] Waiting for Nextcloud to be ready...${NC}"
until php /var/www/html/occ status --output=json 2>/dev/null | jq -r '.installed' 2>/dev/null | grep -q "true"; do
    sleep 10
done
echo -e "${GREEN}[$(date)] Nextcloud is ready${NC}"

# Determine which cron job to run based on parameters
case "$1" in
    "face")
        # Face recognition background job
        run_conditional_job "facerecognition" "face:background_job" "Face Recognition"
        ;;
    "recognize")
        # Recognize app background job  
        run_conditional_job "recognize" "recognize:classify" "Recognize Classification"
        ;;
    "preview")
        # Preview generation
        run_conditional_job "" "preview:generate" "Preview Generation"
        ;;
    "memories")
        # Memories indexing
        run_conditional_job "memories" "memories:index" "Memories Indexing"
        ;;
    "general")
        # General Nextcloud cron
        echo -e "${GREEN}[$(date)] Running general Nextcloud cron...${NC}"
        php -f /var/www/html/cron.php
        ;;
    *)
        echo -e "${RED}[$(date)] Unknown cron job: $1${NC}"
        exit 1
        ;;
esac
