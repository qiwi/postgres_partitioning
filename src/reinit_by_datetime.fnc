create or replace function partitioning.reinit_by_datetime (
  p_schema text,
  p_table_name text
)
returns integer as
$body1$
declare
  v_tab         record;
  v_ddl         text;
  v_trg_name    text;
  v_tab_name    text;
  v_fun_name    text;
  v_part_pref   text;
begin



  for v_tab in
     select pm_schema,
              pm_table_name,
              pm_owner,
              pm_tablespace,
              pm_part_column,
              pm_part_interval,
              pm_part_name_tmpl,
              pm_create_next_from,
              pm_create_enabled,
              pm_create_forward,
              pm_create_last_date,
              pm_partitions_schema
         from partitioning.map_by_datetime
        where pm_schema     = p_schema
          and pm_table_name = p_table_name
  loop

    v_tab_name  = v_tab.pm_schema||'.'||v_tab.pm_table_name;
    v_part_pref = v_tab.pm_partitions_schema ||'.'||v_tab.pm_table_name;
    v_trg_name  = v_tab.pm_table_name||'_partitioning_tr';
    v_fun_name  = v_tab.pm_schema||'.'||v_trg_name||'_fn ()';

    perform partitioning.execute_ddl(v_tab.pm_schema, v_tab.pm_table_name,
'create or replace function '||v_fun_name||'
returns trigger as
$body$
declare
  v_table text;
begin
    v_table       = '''||v_part_pref||''' || to_char(new.'||v_tab.pm_part_column||','''||v_tab.pm_part_name_tmpl||''');
    execute ''insert into  ''|| v_table || '' values ( ($1).* )'' using new;
  return null;
end;
$body$
language ''plpgsql''
volatile
returns null on null input
security invoker
cost 100;
');

    perform partitioning.execute_ddl(v_tab.pm_schema, v_tab.pm_table_name,
    'ALTER FUNCTION '||v_fun_name||' OWNER TO "'|| v_tab.pm_owner ||'"');

    perform partitioning.execute_ddl(v_tab.pm_schema, v_tab.pm_table_name,
    'drop trigger if exists  '||v_trg_name||' on '||v_tab_name);

    perform partitioning.execute_ddl(v_tab.pm_schema, v_tab.pm_table_name,
    'create  trigger '||v_trg_name||'   before insert   on '||v_tab_name||' for each row
     execute procedure  '||v_fun_name);

  end loop;

  return 1;
end;
$body1$
language 'plpgsql'
volatile
called on null input
security invoker
cost 1;
