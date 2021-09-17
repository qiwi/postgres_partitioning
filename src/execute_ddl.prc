create or replace procedure partitioning.execute_ddl(
  p_schema     text,
  p_table_name text,
  p_ddl        text)
language plpgsql
as
$BODY$
declare
begin

  execute p_ddl;
  insert into partitioning.map_by_datetime_ddl
(
    pm_schema,
    pm_table_name,
    pm_ddl_date,
    pm_ddl
  )
  values (
    p_schema,
    p_table_name,
    current_timestamp,
    p_ddl
  );

end;
$BODY$;