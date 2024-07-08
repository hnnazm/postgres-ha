#!/bin/bash

#!/bin/bash

# Paths
NGINX_UPSTREAM_CONF="/etc/nginx/conf.d/upstream_postgres.conf"
TEMP_CONF="/tmp/upstream_postgres.conf"
REPMGR_STATUS_CMD="repmgr cluster show"

# PostgreSQL instances
INSTANCES=("pg1.example.com:5432" "pg2.example.com:5432" "pg3.example.com:5432")

# Check which instance is the master
for instance in "${INSTANCES[@]}"; do
    status=$(psql -h ${instance%:*} -U your_username -d your_database -c "SELECT pg_is_in_recovery();" -t -A)
    if [[ $status == "f" ]]; then
        MASTER=$instance
        break
    fi
done

# Create new upstream configuration
cat <<EOF > $TEMP_CONF
stream {
    upstream postgres_backend {
        server $MASTER;
EOF

# Add backup servers
for instance in "${INSTANCES[@]}"; do
    if [[ $instance != $MASTER ]]; then
        echo "        server $instance backup;" >> $TEMP_CONF
    fi
done

cat <<EOF >> $TEMP_CONF
    }

    server {
        listen 5432;
        proxy_pass postgres_backend;
        proxy_timeout 1s;
        proxy_connect_timeout 1s;
    }
}
EOF

# Replace old configuration with new configuration
mv $TEMP_CONF $NGINX_UPSTREAM_CONF

# Reload Nginx to apply changes
nginx -s reload
