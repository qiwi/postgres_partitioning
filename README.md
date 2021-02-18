# Postgres Partitioning

> A tiny and customizable partitioning solution for PostgreSQL 10+
Provides no need to stop the service for maintenance when you add partitioning.

Installs with start.sql

## Configuration:
```
cd postgres_partitioning

psql -h host -p port -U user -f ./start.sql

-- Configure it with the only one row in a service table
INSERT INTO partitioning.map_by_datetime (
 pm_schema,
 pm_partitions_schema,
 pm_table_name,
 pm_part_column,
 pm_part_interval,
 pm_part_name_tmpl,
 pm_create_next_from,
 pm_create_enabled,
 pm_create_forward,
 -- Optional columns if you need to drop old partitions
 pm_drop_enabled,
 pm_drop_retention
 )
VALUES (
 'app_schema', -- Application schema;
 'app_partitions', -- Schema to store partitions (may be equal to application schema);
 'parent_table', -- Partitioned table;
 'sys_created_dtime', -- Partitioned column;
 INTERVAL '7 days', -- Partition interval. Any interval allowed but choose partitione name template according to this;
 '"_p_"yyyymmW', -- Partition name template.
  -- In this case the partition will be parent_table_p_2017081 which means the first week of aug 2017;
 '2017-08-01', -- Create next from. Use it according to the minimum value of partitioned column in your parent table;
 TRUE, -- Create enabled;
 INTERVAL '28 days', -- Create next partitions for 28 days;

 -- Optional columns if you need to drop old partitions
 TRUE, -- Drop enabled;
 INTERVAL '3 months' -- Drop retention. Partitions older than 3 months would be dropped;
 );

```

### Partitions schema support

```
 -- Optional new schema for partitions.
CREATE SCHEMA IF NOT EXISTS app_partitions;
 -- Do not forget about grants.
ALTER SCHEMA app_partitions OWNER TO table_owner;
```

### Create new partitions.
```
-- PgAgent could do it automatically.
SELECT partitioning.create_by_datetime(now()::timestamp);
```

### Transfer data once
If the partitioning table is not empty use folowing to transfer data.
##### Notice!
This calls truncate parent table which is not transactional-safe. All updates of the "hot" data would be lost.
It may be better to wait some time if your application does updates of the recently inserted data.
When you are shure that updates do not affect parent table, call:
If there are much rows (10 millions +) then watch after your WAL disk space to ensure that data transfer will not crash the database.
```
SELECT partitioning.transfer_data_to_partitions('features', 'obj_feature_shows_log');
```
It does concurrently transfer data allowing read.
 crash the database.