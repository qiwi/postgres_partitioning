-- Function: partitioning.create_by_datetime(timestamp without time zone)

-- DROP FUNCTION partitioning.create_by_datetime(timestamp without time zone);

create or replace function partitioning.create_by_datetime(p_scan_date timestamp without time zone)
  returns integer as
$BODY$
declare
  v_list                record;
  v_grants              record;
  v_partition_name      text;
  v_partition_name_full text;
  v_pattern             text;
  v_begin_ts            timestamp;
  v_end_ts              timestamp;
  v_date_from           text;
  v_date_to             text;
begin
  for v_list in
  select
    pm_schema,
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
  where pm_create_enabled = true
        and pm_create_next_from < p_scan_date + pm_create_forward
  loop

    v_begin_ts = v_list.pm_create_next_from;
    v_end_ts = v_begin_ts + v_list.pm_part_interval;
    v_pattern = v_list.pm_schema || '.' || v_list.pm_table_name;

    while (v_end_ts <= p_scan_date + v_list.pm_create_forward)
    loop

      v_partition_name = v_list.pm_table_name || to_char(v_begin_ts, v_list.pm_part_name_tmpl);
      v_partition_name_full = v_list.pm_partitions_schema || '.' || v_partition_name;


      if not exists(select 1
                    from information_schema.tables
                    where table_schema = v_list.pm_partitions_schema
                          and table_name = v_partition_name)
      then

        perform partitioning.execute_ddl(v_list.pm_schema, v_list.pm_table_name,
                                         'create table ' || v_partition_name_full
                                         || ' ( like ' || v_pattern || ' including all ) inherits (' || v_pattern
                                         || ') tablespace ' || v_list.pm_tablespace);


        v_date_from = to_char(v_begin_ts, 'yyyy-mm-dd hh24:mi:ss');
        v_date_to = to_char(v_end_ts, 'yyyy-mm-dd hh24:mi:ss');

        perform partitioning.execute_ddl(v_list.pm_schema, v_list.pm_table_name,
                                         'alter  table ' || v_partition_name_full ||
                                         ' add constraint ' || v_partition_name || '_part_ck check
                  (' || v_list.pm_part_column || ' >= timestamp''' || v_date_from || ''' and
                   ' || v_list.pm_part_column || ' <  timestamp''' || v_date_to || ''')');


        perform partitioning.execute_ddl(v_list.pm_schema, v_list.pm_table_name,
                                         'alter  table ' || v_partition_name_full || ' owner to ' || v_list.pm_owner);

        -- inserts are'nt inherited
        for v_grants in
        select grantee
        from information_schema.role_table_grants
        where table_schema = v_list.pm_schema
              and table_name = v_list.pm_table_name
              and privilege_type = upper('insert')
        loop
          perform partitioning.execute_ddl(v_list.pm_schema, v_list.pm_table_name,
                                           'grant insert on  ' || v_partition_name_full || ' to "' || v_grants.grantee
                                           || '"');
        end loop;

        insert into partitioning.map_by_datetime_partitions
        (pm_schema, pm_table_name, pm_partition_name, pm_partition_from, pm_partition_till, pm_partitions_schema)
        values
          (v_list.pm_schema, v_list.pm_table_name, v_partition_name, v_begin_ts, v_end_ts, v_list.pm_partitions_schema);

        v_begin_ts = v_end_ts;
        v_end_ts = v_end_ts + v_list.pm_part_interval;


      end if;
    end loop;

    update partitioning.map_by_datetime
    set pm_create_next_from = v_begin_ts
      , pm_create_last_date = current_timestamp
    where pm_schema = v_list.pm_schema
          and pm_table_name = v_list.pm_table_name;
  end loop;

  return 1;

end;
$BODY$
language plpgsql volatile strict
cost 100;
