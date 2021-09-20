create or replace function partitioning.get_full_partitions_forward_creation_current_info()
    returns table (
                      schema                                  varchar,
                      table_name                              varchar,
                      partitions_create_enabled               boolean,
                      partitions_create_last_date             timestamp,
                      partitions_create_forward               interval,
                      partitions_create_forward_count         integer,
                      current_available_partitions_count      integer,
                      last_created_forward_partitions_count   integer)
as
$body$
select sub.schema, sub.table_name, (sub.info_result).*
from (
         select settings.pm_schema as schema,
                settings.pm_table_name as table_name,
                partitioning.get_partitions_forward_creation_current_info(
                        settings.pm_schema,
                        settings.pm_table_name
                    ) as info_result
         from partitioning.map_by_datetime settings
     ) sub;
$body$
    language 'sql'
    volatile;
