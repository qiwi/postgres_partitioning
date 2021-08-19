create or replace function partitioning.get_full_partitions_drop_current_info()
    returns table (
                      schema                            varchar,
                      table_name                        varchar,
                      partitions_drop_enabled           boolean,
                      partitions_drop_last_date         timestamp,
                      partitions_drop_retention         interval,
                      outdated_partitions_current_count integer)
as
$body$
select sub.schema, sub.table_name, (sub.info_result).*
from (
         select settings.pm_schema as schema,
                settings.pm_table_name as table_name,
                partitioning.get_partitions_drop_current_info(
                        settings.pm_schema,
                        settings.pm_table_name
                    ) as info_result
         from partitioning.map_by_datetime settings
     ) sub;
$body$
    language 'sql'
    volatile;
