#!/bin/bash
# This script runs when the MySQL container first starts
# It creates the application database user and databases

set -e

mysql -u root -p"${MYSQL_ROOT_PASSWORD}" <<-EOSQL
    -- Create application database user
    CREATE USER IF NOT EXISTS 'cocktailscout4'@'%' IDENTIFIED BY '${COCKTAILSCOUT4_DATABASE_PASSWORD}';

    -- Create production databases
    CREATE DATABASE IF NOT EXISTS cocktailscout4_production CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
    CREATE DATABASE IF NOT EXISTS cocktailscout4_production_cache CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
    CREATE DATABASE IF NOT EXISTS cocktailscout4_production_queue CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
    CREATE DATABASE IF NOT EXISTS cocktailscout4_production_cable CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;

    -- Grant privileges
    GRANT ALL PRIVILEGES ON cocktailscout4_production.* TO 'cocktailscout4'@'%';
    GRANT ALL PRIVILEGES ON cocktailscout4_production_cache.* TO 'cocktailscout4'@'%';
    GRANT ALL PRIVILEGES ON cocktailscout4_production_queue.* TO 'cocktailscout4'@'%';
    GRANT ALL PRIVILEGES ON cocktailscout4_production_cable.* TO 'cocktailscout4'@'%';

    FLUSH PRIVILEGES;
EOSQL

echo "Production databases and user created successfully"
