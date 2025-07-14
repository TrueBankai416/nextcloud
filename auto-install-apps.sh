#!/bin/bash
set -e

echo "🚀 Starting Nextcloud app auto-installation..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to check if app is installed
is_app_installed() {
    local app_name=$1
    if php occ app:list | grep -q "^  - $app_name:"; then
        return 0
    else
        return 1
    fi
}

# Function to install and enable app
install_app() {
    local app_name=$1
    local display_name=$2
    
    echo -e "${YELLOW}Installing $display_name...${NC}"
    
    if is_app_installed "$app_name"; then
        echo -e "${GREEN}✅ $display_name is already installed${NC}"
        return 0
    fi
    
    if php occ app:install "$app_name" 2>/dev/null; then
        echo -e "${GREEN}✅ $display_name installed successfully${NC}"
        php occ app:enable "$app_name" 2>/dev/null || true
        return 0
    else
        echo -e "${RED}❌ Failed to install $display_name${NC}"
        return 1
    fi
}

# Function to configure app
configure_app() {
    local app_name=$1
    local config_commands=$2
    
    echo -e "${YELLOW}Configuring $app_name...${NC}"
    eval "$config_commands"
}

# Wait for Nextcloud to be ready
echo "⏳ Waiting for Nextcloud to be ready..."
until php occ status >/dev/null 2>&1; do
    sleep 5
done
echo -e "${GREEN}✅ Nextcloud is ready${NC}"

# Install notify_push app
if [ "${INSTALL_NOTIFY_PUSH:-false}" = "true" ]; then
    if install_app "notify_push" "Notify Push"; then
        configure_app "notify_push" "
            php occ config:app:set notify_push base_endpoint --value='ws://localhost:${NOTIFY_PUSH_PORT:-7867}'
            php occ config:app:set notify_push binary_path --value='/usr/local/bin/notify_push'
            echo -e '${GREEN}✅ notify_push configured${NC}'
        "
    fi
fi

# Install Collabora Office
if [ "${INSTALL_COLLABORA:-false}" = "true" ]; then
    if install_app "richdocuments" "Nextcloud Office (Collabora)"; then
        configure_app "richdocuments" "
            php occ config:app:set richdocuments wopi_url --value='https://${NEXTCLOUD_DOMAIN:-localhost}/collabora/'
            php occ config:app:set richdocuments public_wopi_url --value='https://${NEXTCLOUD_DOMAIN:-localhost}/collabora/'
            echo -e '${GREEN}✅ Nextcloud Office configured for Collabora${NC}'
        "
    fi
fi

# Install OnlyOffice
if [ "${INSTALL_ONLYOFFICE:-false}" = "true" ]; then
    if install_app "onlyoffice" "OnlyOffice"; then
        configure_app "onlyoffice" "
            php occ config:app:set onlyoffice DocumentServerUrl --value='https://${NEXTCLOUD_DOMAIN:-localhost}:${ONLYOFFICE_PORT:-8000}/'
            php occ config:app:set onlyoffice jwt_secret --value='${ONLYOFFICE_JWT_SECRET:-change_me_jwt_secret}'
            echo -e '${GREEN}✅ OnlyOffice configured${NC}'
        "
    fi
fi

# Install Memories app
if [ "${INSTALL_MEMORIES:-false}" = "true" ]; then
    if install_app "memories" "Memories"; then
        configure_app "memories" "
            php occ config:app:set memories enabled --value='yes'
            php occ config:app:set memories timeline_path --value='/Photos'
            echo -e '${GREEN}✅ Memories configured${NC}'
        "
    fi
fi

# Install Recognize app
if [ "${INSTALL_RECOGNIZE:-false}" = "true" ]; then
    if install_app "recognize" "Recognize"; then
        configure_app "recognize" "
            php occ config:app:set recognize enabled --value='yes'
            php occ config:app:set recognize tensorflow.gpu --value='${NVIDIA_VISIBLE_DEVICES:+true}'
            echo -e '${GREEN}✅ Recognize configured${NC}'
        "
    fi
fi

# Run maintenance tasks
echo -e "${YELLOW}Running maintenance tasks...${NC}"
php occ maintenance:update:htaccess 2>/dev/null || true
php occ db:add-missing-indices 2>/dev/null || true
php occ db:add-missing-columns 2>/dev/null || true
php occ db:add-missing-primary-keys 2>/dev/null || true

echo -e "${GREEN}🎉 App auto-installation completed!${NC}"

# Show installed apps
echo -e "${YELLOW}📦 Installed apps:${NC}"
php occ app:list --output=json | jq -r '.enabled | keys[]' | sort
