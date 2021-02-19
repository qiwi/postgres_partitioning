create or replace function partitioning.transfer_data_to_partitions(
  p_schema     text,
  p_table_name text
)
  returns boolean as
$body$
declare
  v_table_full_name        text := p_schema || '.' || p_table_name;
  v_data_transfer_sql      text;
  v_clean_master_table_sql text;
begin
  v_data_transfer_sql = ' insert into ' || v_table_full_name || ' select * from only ' || v_table_full_name ||
                        ' on conflict do nothing;';
  v_clean_master_table_sql = 'truncate table only ' || v_table_full_name || ';';
  execute v_data_transfer_sql;
  execute v_clean_master_table_sql;

  return true;
end;
$body$
language 'plpgsql'
volatile
called on null input
security invoker
cost 1;