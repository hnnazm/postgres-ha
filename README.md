---
title: High Availability Postgres
author: Hannan
---

# Overview


## Tools
Tools that are being used for this demo

1. [repmgr](https://www.repmgr.org)
2. [docker](https://www.docker.com) (for demo only)

## Initial Setup
Change the configuration of the Postgres cluster by tweaking these following files:

- postgresql.conf
- pg_hba.conf

*changing some options may require restart*


### Infrastructure


#### Docker

Image used for this demo is [bitnami/postgresql-repmgr](https://hub.docker.com/r/bitnami/postgresql-repmgr/). This image already packed with PostgreSQL and repmgr so no further installation needed.

*if deploying on bare server, installation of PostgreSQL and repmgr is required*

Creating docker network
```bash
docker network create beaconx --driver bridge
```

Running master postgres cluster
```bash
cd master
docker compose up -d
```

Running slave postgres cluster
```bash
cd slave
docker compose up -d
```

Cleanup
```bash
cd master
docker compose down

cd slave
docker compose down

docker network rm beaconx
```

#### Bare Server
**TBC**


### Postgres Cluster

In this demo, we are setting up three postgres cluster which serve as:

* master
* slave
* witness (reside in same master's server)


#### Master

Initialize database with prerequisite data

```sql
CREATE DATABASE einvoice;

CREATE ROLE admin_user WITH LOGIN PASSWORD 'securepassword';
CREATE ROLE beaconx_app WITH LOGIN PASSWORD 'securepassword';

GRANT ALL PRIVILEGES ON DATABASE einvoice TO admin_user;
GRANT ALL PRIVILEGES ON DATABASE einvoice TO beaconx_app;
```

(optional) Seed database for demo purposes

```bash
./seeder.sh
```

#### Slave

 No configuration needed as it will be managed by `repmgr`


# Replication

## Master

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

# Failover

```diff
...
services:
  pg-0:
  ...
    environment:
-      - POSTGRESQL_PASSWORD=adminpassword
+      - POSTGRESQL_PASSWORD=password123
-      - REPMGR_PASSWORD=repmgrpassword
+      - REPMGR_PASSWORD=password123
  ...
  pg-1:
  ...
  environment:
-      - POSTGRESQL_PASSWORD=adminpassword
+      - POSTGRESQL_PASSWORD=password123
-      - REPMGR_PASSWORD=repmgrpassword
+      - REPMGR_PASSWORD=password123
...
```

# References

## Useful Links

- [https://www.linode.com/docs/guides/manage-replication-failover-on-postgresql-cluster-using-repmgr](https://www.linode.com/docs/guides/manage-replication-failover-on-postgresql-cluster-using-repmgr/)
