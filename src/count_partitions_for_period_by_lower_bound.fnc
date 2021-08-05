create or replace function pg_temp.count_partitions_for_period_by_lower_bound(
    in schema_name varchar,
    in table_name varchar,
    in start_interval interval,
    in end_interval interval
)
    returns integer
as
$body$
select count(*)
from (select inh.inhrelid::regclass,
             split_part(partition_bound, '''', 2)::timestamp as lower_bound
      from pg_inherits inh
        join pg_class c on c.oid = inh.inhrelid,
        pg_get_expr(c.relpartbound, inh.inhrelid) as partition_bound
      where inhparent = (schema_name || '.' || table_name)::regclass) partition
where partition.lower_bound between now()::date - start_interval and now()::date + end_interval
$body$
language 'sql'
volatile;