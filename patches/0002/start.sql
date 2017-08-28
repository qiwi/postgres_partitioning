create schema if not exists partitioning;
set search_path to partitioning;
\i  ./transfer_data_to_partitions.fnc