create or replace procedure partitioning.create_by_datetime(pi_scan_date timestamp without time zone)
as
$BODY$
declare
  v_list                record;
  v_partition_name      text;
  v_partition_name_full text;
  v_table_name_full     text;
  v_partition_postfix   text;
  v_ddl                 text;
  v_begin_ts            timestamp;
  v_end_ts              timestamp;
  v_message_text        text;
begin
  -- Делаем выборку таблиц которым нужно партиционирование
  << select_partioning_table >>
  for v_list in
      select pm_schema,
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
        and pm_create_next_from < pi_scan_date + pm_create_forward
      loop
          -- Собираем имя следующей партиции
          v_begin_ts = v_list.pm_create_next_from;
          v_partition_postfix = to_char(v_begin_ts, v_list.pm_part_name_tmpl);
          v_begin_ts = to_date(v_partition_postfix, v_list.pm_part_name_tmpl);
          v_end_ts = v_begin_ts + v_list.pm_part_interval;
          v_table_name_full = v_list.pm_schema || '.' || v_list.pm_table_name;

          -- Начинаем нарезать
          while (v_end_ts <= pi_scan_date + v_list.pm_create_forward)
              loop

                  v_partition_name = v_list.pm_table_name || v_partition_postfix;
                  v_partition_name_full = v_list.pm_partitions_schema || '.' || v_partition_name;

                  -- Проверяем по системным таблицам что такой партиции нет.
                  if not exists(select 1
                                from information_schema.tables
                                where table_schema = v_list.pm_partitions_schema
                                  and table_name = v_partition_name) then
                      -- Создаем ddl операцию
                      v_ddl = 'create table ' || v_partition_name_full || ' partition of '
                                  || v_table_name_full || ' for values from (''' || v_begin_ts || ''') to (''' ||
                              v_end_ts || ''')';

                      -- Выполняем ddl и кладем в map_by_datetime_ddl или в случае ошибки в map_by_datetime_ddl_errors
                      begin
                          perform partitioning.execute_ddl(v_list.pm_schema, v_list.pm_table_name, v_ddl);
                          -- Вставляем в таблицу мониторинга партиций запись о создании новой пратиции
                          insert into partitioning.map_by_datetime_partitions (pm_schema, pm_table_name,
                                                                               pm_partition_name, pm_partition_from,
                                                                               pm_partition_till,
                                                                               pm_partitions_schema)
                          values (v_list.pm_schema, v_list.pm_table_name, v_partition_name, v_begin_ts, v_end_ts,
                                  v_list.pm_partitions_schema);

                          v_begin_ts = v_end_ts;
                          v_partition_postfix = to_char(v_begin_ts, v_list.pm_part_name_tmpl);
                          v_begin_ts = to_date(v_partition_postfix, v_list.pm_part_name_tmpl);
                          v_end_ts = v_begin_ts + v_list.pm_part_interval;
                      exception
                          when others then
                              begin
                                  get stacked diagnostics v_message_text = message_text;
                                  insert into partitioning.map_by_datetime_ddl_errors (pm_schema, pm_table_name, pm_err_date, pm_ddl, pm_err_text)
                                       values (v_list.pm_schema, v_list.pm_table_name, now(), v_ddl, v_message_text);
                                  commit;
                                  continue select_partioning_table;
                              end;
                      end;
                      commit;
                  end if;
              end loop;

          --Обновляем данные о дате новой нарезке партиций
          update partitioning.map_by_datetime
          set pm_create_next_from = v_begin_ts,
              pm_create_last_date = current_timestamp
          where pm_schema = v_list.pm_schema
            and pm_table_name = v_list.pm_table_name;
      end loop;
  commit;
end;
$BODY$ language plpgsql;;
