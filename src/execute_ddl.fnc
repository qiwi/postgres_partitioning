CREATE OR REPLACE FUNCTION partitioning.execute_ddl(
    p_schema text,
    p_table_name text,
    p_ddl text)
  RETURNS void AS
$BODY$
declare
 
begin

 execute p_ddl;

 insert into   partitioning.map_by_datetime_ddl
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
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 1;