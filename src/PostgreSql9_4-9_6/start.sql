create schema if not exists partitioning;
set search_path to partitioning;
\i  ./map_by_datetime.tbl
\i  ./map_by_datetime_partitions.tbl
\i  ./map_by_datetime_ddl.tbl
\i  ./map_by_datetime_ddl_errors.tbl
\i  ./execute_ddl.fnc
\i  ./create_by_datetime.fnc
\i  ./drop_by_datetime.fnc
\i  ./inherit_insert_permissions.fnc
\i  ./inherit_indexes.fnc
\i  ./reinit_by_datetime.fnc
\i  ./transfer_data_to_partitions.fnc