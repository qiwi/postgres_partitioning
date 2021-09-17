create or replace function partitioning.inherit_insert_permissions(
  p_schema         text,
  p_table_name     text,
  p_partition_name text = '' :: text
)
  returns boolean as
$body$
declare
  v_grants record;
begin
  for v_grants
  in
  select 'grant insert on  ' || p.pm_partitions_schema || '.' || p.pm_partition_name
         || ' to "' || g.grantee || '"' as cmd
  from information_schema.role_table_grants g
    join partitioning.map_by_datetime_partitions p
      on p.pm_schema = g.table_schema
         and p.pm_table_name = g.table_name
  where g.table_schema = p_schema
        and g.table_name = p_table_name
        and (p_partition_name = ''
             or p.pm_partition_name = p_partition_name)
        and privilege_type = upper('insert')
  loop
    perform partitioning.execute_ddl(p_schema, p_table_name, v_grants.cmd);

  end loop;

  return true;

end;
$body$
language 'plpgsql'
volatile
called on null input
security invoker
cost 1;
