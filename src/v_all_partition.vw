create or replace view partitioning.v_all_partition as
select nmsp_parent.nspname  as table_schema,
       parent.relname       as table_name,
       nmsp_child.nspname   as partition_schema,
       child.relname        as partition_name,
       mp.pm_partition_from as partition_from,
       mp.pm_partition_till as partition_till       
  from pg_inherits
  join pg_class parent on pg_inherits.inhparent = parent.oid
  join pg_class child on pg_inherits.inhrelid = child.oid
  join pg_namespace nmsp_parent on nmsp_parent.oid = parent.relnamespace
  join pg_namespace nmsp_child on nmsp_child.oid = child.relnamespace
  left join partitioning.map_by_datetime_partitions mp on mp.pm_schema = nmsp_child.nspname
                                     and mp.pm_table_name = parent.relname
                                     and mp.pm_partition_name = child.relname
 order by table_schema, table_name, partition_schema, partition_name;