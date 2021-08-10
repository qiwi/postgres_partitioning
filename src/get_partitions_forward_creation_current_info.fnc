create or replace function partitioning.get_partitions_forward_creation_current_info(
    in schema_name varchar,
    in table_name varchar
)
    returns table (
        partitions_create_enabled boolean,
        partitions_create_last_date timestamp,
        partitions_create_forward interval,
        reserve_partitions_current_count integer,
        last_created_partitions_count integer)
as
$body$
select settings.pm_create_enabled partitions_create_enabled,
       settings.pm_create_last_date partitions_create_last_date,
       settings.pm_create_forward partitions_create_forward,
       partitioning.count_partitions_for_period_by_lower_bound(
               settings.pm_schema,
               settings.pm_table_name,
               now()::date,
               now()::date + settings.pm_create_forward
       ) reserve_partitions_current_count,
       partitioning.count_partitions_for_period_by_lower_bound(
               settings.pm_schema,
               settings.pm_table_name,
               settings.pm_create_last_date,
               settings.pm_create_last_date + settings.pm_create_forward
       ) last_created_partitions_count
from partitioning.map_by_datetime settings
where settings.pm_schema = schema_name
  and settings.pm_table_name = table_name;
$body$
    language 'sql'
    volatile;