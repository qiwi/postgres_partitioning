create or replace function partitioning.create_by_datetime(p_scan_date timestamp without time zone)
  returns integer as
$BODY$
declare
  v_list                record;
  v_partition_name      text;
  v_partition_name_full text;
  v_table_name_full     text;
  v_partition_postfix   text;
  v_begin_ts            timestamp;
  v_end_ts              timestamp;
begin
-- Делаем выборку таблиц которым нужно партиционирование
  for v_list in
  select
    pm_schema,
    pm_table_name,
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

    -- Собираем имя следующей партиции
    v_begin_ts = v_list.pm_create_next_from;
    v_partition_postfix = to_char(v_begin_ts, v_list.pm_part_name_tmpl);
    v_begin_ts = to_date(v_partition_postfix, v_list.pm_part_name_tmpl);
    v_end_ts = v_begin_ts + v_list.pm_part_interval;
    v_table_name_full = v_list.pm_schema || '.' || v_list.pm_table_name;

    -- Начинаем нарезать
    while (v_end_ts <= p_scan_date + v_list.pm_create_forward)
    loop

      v_partition_name = v_list.pm_table_name || v_partition_postfix;
      v_partition_name_full = v_list.pm_partitions_schema || '.' || v_partition_name;


      if not exists(select 1
                    from information_schema.tables
                    where table_schema = v_list.pm_partitions_schema
                          and table_name = v_partition_name)
      then

        -- Создаем запись как нарезать, выполняем и кладем map_by_datetime_ddl
        perform partitioning.execute_ddl(v_list.pm_schema, v_list.pm_table_name,
                                         'create table ' || v_partition_name_full
                                         || ' partition of ' || v_table_name_full || ' for values from ('''|| v_begin_ts
                                             ||''') to ('''||v_end_ts|| ''')');

        -- Вставляем в таблицу мониторинга партиций запись о создании новой пратиции
        insert into partitioning.map_by_datetime_partitions
        (pm_schema, pm_table_name, pm_partition_name, pm_partition_from, pm_partition_till, pm_partitions_schema)
        values
          (v_list.pm_schema, v_list.pm_table_name, v_partition_name, v_begin_ts, v_end_ts, v_list.pm_partitions_schema);

        v_begin_ts = v_end_ts;
        v_partition_postfix = to_char(v_begin_ts, v_list.pm_part_name_tmpl);
        v_begin_ts = to_date(v_partition_postfix, v_list.pm_part_name_tmpl);
        v_end_ts = v_begin_ts + v_list.pm_part_interval;

      end if;
    end loop;

    --Обновляем данные о дате новой нарезке партиций
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
