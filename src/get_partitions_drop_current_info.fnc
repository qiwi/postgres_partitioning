create or replace function partitioning.get_partitions_drop_current_info(
    in schema_name varchar,
    in table_name varchar
)
    returns table (
        partitions_drop_enabled boolean,
        partitions_drop_last_date timestamp,
        partitions_drop_retention interval,
        outdated_partitions_current_count integer)
as
$body$
select settings.pm_drop_enabled   partitions_drop_enabled,
       settings.pm_drop_last_date partitions_drop_last_date,
       settings.pm_drop_retention partitions_drop_retention,
       partitioning.count_partitions_for_period_by_lower_bound(
               settings.pm_schema,
               settings.pm_table_name,
               pm_drop_last_date,
               now()::date - settings.pm_drop_retention
       ) outdated_partitions_current_count
from partitioning.map_by_datetime settings
where settings.pm_schema = schema_name
  and settings.pm_table_name = table_name;
$body$
    language 'sql'
    volatile;