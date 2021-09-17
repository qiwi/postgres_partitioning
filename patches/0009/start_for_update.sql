set search_path to partitioning;
drop function if exists partitioning.execute_ddl(p_schema text, p_table_name text, p_ddl text);
\i  ./src/execute_ddl.prc
\i  ./src/create_by_datetime.prc
\i  ./src/drop_by_datetime.prc