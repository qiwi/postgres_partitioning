create schema if not exists partitioning;
set search_path to partitioning;
\i  ./map_by_datetime.tbl
\i  ./map_by_datetime_partitions.tbl
\i  ./map_by_datetime_ddl.tbl
\i  ./map_by_datetime_ddl_errors.tbl
\i  ./execute_ddl.fnc
\i  ./create_by_datetime.prc
\i  ./drop_by_datetime.prc
\i  ./transfer_data_to_partitions.fnc
\i  ./v_all_partition.vw