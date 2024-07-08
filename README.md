---
title: High Availability Postgres
author: Hannan
---

## Overview


### Tools
Tools that are being used for this setup:

1. [repmgr](https://www.repmgr.org)
2. [nginx](https://nginx.org)
2. [docker](https://www.docker.com) (for demo only)


### Initial Setup
Change the configuration of the Postgres cluster by tweaking these following files:

- postgresql.conf
- pg_hba.conf

*changing some options may require restart*


#### Infrastructure

##### High Level Solution

![](./assets/infra.png)


#### PostgreSQL Cluster

In this setup, we are setting up two postgres cluster which serve as:

- master
- slave

##### Master

Initialize database with prerequisite data.

```sql
CREATE DATABASE einvoice;

CREATE ROLE admin_user WITH LOGIN PASSWORD 'securepassword';
CREATE ROLE beaconx_app WITH LOGIN PASSWORD 'securepassword';

GRANT ALL PRIVILEGES ON DATABASE einvoice TO admin_user;
GRANT ALL PRIVILEGES ON DATABASE einvoice TO beaconx_app;
```

(optional) Seed database for demo purposes.

```bash
cd master
./seeder/default.sql
```

##### Slave

No configuration needed as it will be managed by `repmgr`.


#### Repmgr

##### Master

The required configuration that need to be changed for master node:

*postgresql.conf*
```conf
shared_preload_libraries = 'repmgr'
wal_level = replica
archive_mode = on
archive_command = '/bin/true'
max_wal_senders = 10
max_replication_slots = 10
hot_standby = on
listen_addresses = '*'
```

#### Reverse Proxy

*nginx* was used to handle the routing of the stack.


##### Application

Configure typical reverse proxy for Laravel application.


##### Database

Below is nginx configuration set up to:

- register postgres intances for for reverse proxy.
- assign instance as standby in case of failover.

*pg.conf*
```conf
stream {
  upstream postgres_backend {
    server pg-0:5432 max_fails=3 fail_timeout=30s;           # replace with actual ip address
    server pg-1:5432 max_fails=3 fail_timeout=30s backup;    # replace with actual ip address
    hash $remote_addr consistent;
  }

  server {
    listen 5432 so_keepalive=on;

    proxy_pass postgres_backend;
  }
}
```

#### Application

Setup database is Laravel application environment variables:

```diff
+ DB_CONNECTION: pgsql
+ DB_HOST: reverse-proxy
+ DB_PORT: 5432
+ DB_USERNAME: postgres
+ DB_PASSWORD: password
+ DB_DATABASE: einvoice
```


### Using Docker

Image used for this demo is [bitnami/postgresql-repmgr](https://hub.docker.com/r/bitnami/postgresql-repmgr/). This image already packed with PostgreSQL and repmgr so no further installation needed.

*if deploying on bare server, installation of PostgreSQL and repmgr is required*

Creating docker network.
```bash
docker network create beaconx --driver bridge
```

Running master postgres cluster.
```bash
cd master
docker compose up -d
```

Running slave postgres cluster.
```bash
cd slave
docker compose up -d
```

Cleanup.
```bash
cd master
docker compose down

cd slave
docker compose down

docker network rm beaconx
```


## Known Issue

1. Upon recover the master from failover, the reverse proxy remain providing traffic to slave which cause an error of: *cannot execute INSERT in a read-only transaction*.

    **Expected:** repmgr should make the master as primary or reverse proxy should route traffic to primary.


## References

- [https://www.linode.com/docs/guides/manage-replication-failover-on-postgresql-cluster-using-repmgr](https://www.linode.com/docs/guides/manage-replication-failover-on-postgresql-cluster-using-repmgr/)
