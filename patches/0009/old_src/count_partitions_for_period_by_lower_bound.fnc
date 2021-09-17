create or replace function partitioning.count_partitions_for_period_by_lower_bound(
    in schema_name varchar,
    in table_name varchar,
    in start_date timestamp,
    in end_date timestamp
)
    returns integer
as
$body$
select count(*)
from partitioning.map_by_datetime_partitions partitions
where partitions.pm_schema = schema_name
  and partitions.pm_table_name = table_name
  and partitions.pm_partition_from between start_date and end_date;
$body$
language 'sql'
volatile;
