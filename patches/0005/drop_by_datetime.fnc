create or replace function partitioning.drop_by_datetime(p_scan_date timestamp without time zone) returns integer
    strict
    language plpgsql
as
$BODY$
declare
  v_list        record;
  v_parts       record;
  v_retention   timestamp;
begin
  -- Делаем выборку таблиц у которых включенно удаление партиционирования
  for v_list in
  select
    pm_schema,
    pm_table_name,
    pm_drop_retention
  from partitioning.map_by_datetime
  where pm_drop_enabled = true
  loop
    v_retention = (p_scan_date - v_list.pm_drop_retention);
    for v_parts in
    select
      pmp.pm_schema,
      pmp.pm_partition_name,
      pm_partitions_schema
    from pg_inherits
      join pg_class c on (inhrelid = c.oid)
      join pg_class p on (inhparent = p.oid)
      join pg_namespace cn on c.relnamespace = cn.oid
      join pg_namespace pn on p.relnamespace = pn.oid
      join partitioning.map_by_datetime_partitions pmp
        on pmp.pm_partition_name = c.relname
           and pmp.pm_schema = pn.nspname
    where pn.nspname = v_list.pm_schema
          and p.relname = v_list.pm_table_name
          and pmp.pm_partition_till < v_retention
    loop
      -- Создаем команду об удалении, выполняем и кладем map_by_datetime_ddl
      perform partitioning.execute_ddl(v_list.pm_schema, v_list.pm_table_name,
                                       'drop table ' || v_parts.pm_partitions_schema || '.' ||
                                       v_parts.pm_partition_name);
      -- Удаляем запись из мониторинга партиций
      delete from partitioning.map_by_datetime_partitions pmp
      where pmp.pm_partition_name = v_parts.pm_partition_name
            and pmp.pm_schema = v_parts.pm_schema
            and pmp.pm_partitions_schema = v_parts.pm_partitions_schema;
    end loop;

     --Обновляем данные о дате нового удаления партиций
    update partitioning.map_by_datetime
    set pm_drop_last_date = current_timestamp
    where pm_schema = v_list.pm_schema
          and pm_table_name = v_list.pm_table_name;
  end loop;

  return 1;

end;
$BODY$
language plpgsql volatile strict
cost 100;