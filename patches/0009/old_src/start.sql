create schema if not exists partitioning;
set search_path to partitioning;
\i  ./partitioning_template.tbl
\i  ./map_by_datetime.tbl
\i  ./map_by_datetime_partitions.tbl
\i  ./map_by_datetime_ddl.tbl
\i  ./map_by_datetime_ddl_errors.tbl
\i  ./execute_ddl.prc
\i  ./create_by_datetime.prc
\i  ./drop_by_datetime.prc
\i  ./transfer_data_to_partitions.fnc
\i  ./v_all_partition.vw
\i  ./count_partitions_for_period_by_lower_bound.fnc
\i  ./get_partitions_forward_creation_current_info.fnc
\i  ./get_partitions_drop_current_info.fnc
\i  ./get_full_partitions_forward_creation_current_info.fnc
\i  ./get_full_partitions_drop_current_info.fnc
