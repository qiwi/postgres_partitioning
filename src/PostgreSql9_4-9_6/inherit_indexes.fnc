create or replace function partitioning.inherit_indexes(
  p_schema         text,
  p_table_name     text,
  p_partition_name text = '' :: text
)
  returns boolean as
$body$
declare
  v_indexes record;
begin
  for v_indexes
  in
  select regexp_replace(indexdef, '[a-z0-9_]+ ON ' || pm_schema || '\.' || pm_table_name,
                        'ON ' || pm_partitions_schema || '.' || pm_partition_name) as part_index_ddl
  from (
         select
           regexp_matches(
               indexdef
               , '\(([a-z0-9_,\s]+)\)'
           ) as match,
           indexdef,
           map_by_datetime.pm_schema,
           map_by_datetime.pm_table_name,
           map_by_datetime.pm_partitions_schema,
           map_by_datetime_partitions.pm_partition_name
         from partitioning.map_by_datetime
           inner join partitioning.map_by_datetime_partitions
             on map_by_datetime.pm_table_name = map_by_datetime_partitions.pm_table_name
                and map_by_datetime.pm_schema = map_by_datetime_partitions.pm_schema
                and (p_partition_name = '' or pm_partition_name = p_partition_name)
           inner join pg_indexes on tablename = map_by_datetime.pm_table_name and schemaname = map_by_datetime.pm_schema
         where map_by_datetime.pm_schema = p_schema and map_by_datetime.pm_table_name = p_table_name
       ) as indexes
  where not EXISTS(
      select *
      from
        pg_indexes
      where
        schemaname = pm_partitions_schema and tablename = pm_partition_name
        and indexdef like '%(' || match [1] || ')%'
  )
  loop
    perform partitioning.execute_ddl(p_schema, p_table_name, v_indexes.part_index_ddl);
  end loop;

  return true;

end;
$body$
language 'plpgsql'
volatile
called on null input
security invoker
cost 100;