#!/bin/bash
set -e

echo "Nextcloud Background Jobs Cleanup Script"
echo "========================================"

# Function to run commands in the nextcloud container
run_in_container() {
    docker exec -u www-data nextcloud "$@"
}

# Function to run database commands
run_db_command() {
    docker exec -i mariadb mysql -u "${MYSQL_USER:-nextcloud}" -p"${MYSQL_PASSWORD}" "${MYSQL_DATABASE:-nextcloud}" -e "$1"
}

# Check if containers are running
if ! docker ps | grep -q "nextcloud"; then
    echo "Error: Nextcloud container is not running!"
    exit 1
fi

if ! docker ps | grep -q "mariadb"; then
    echo "Error: MariaDB container is not running!"
    exit 1
fi

echo "Checking current background jobs status..."
run_in_container php occ background:job:list --limit 10

echo ""
echo "Counting stuck jobs (jobs with timestamp 1970-01-01 or 0)..."

# Count stuck jobs
STUCK_COUNT=$(run_db_command "SELECT COUNT(*) as count FROM oc_jobs WHERE last_run = 0 OR last_run < 946684800;" | tail -n1)
echo "Found $STUCK_COUNT stuck jobs"

if [ "$STUCK_COUNT" -gt 0 ]; then
    echo ""
    echo "WARNING: This will delete $STUCK_COUNT background jobs from the database."
    echo "This action cannot be undone!"
    echo ""
    read -p "Do you want to proceed? (y/N): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "Cleaning up stuck jobs in batches of 1000..."
        
        while true; do
            DELETED=$(run_db_command "DELETE FROM oc_jobs WHERE (last_run = 0 OR last_run < 946684800) LIMIT 1000; SELECT ROW_COUNT();" | tail -n1)
            
            if [ "$DELETED" -eq 0 ]; then
                break
            fi
            
            echo "Deleted $DELETED jobs..."
            sleep 1
        done
        
        echo "Cleanup completed!"
        
        # Reset the job system
        echo "Resetting background job system..."
        run_in_container php occ background:cron
        
        echo "Running one background job to test..."
        run_in_container php occ background:job:execute --force-execute
        
        echo ""
        echo "Cleanup completed successfully!"
        echo "The cron system should now work properly."
    else
        echo "Cleanup cancelled."
    fi
else
    echo "No stuck jobs found. Your background job system appears to be healthy."
fi

echo ""
echo "Current status:"
run_in_container php occ status
