drop database if exists db_charmer_sandbox_test;
create database db_charmer_sandbox_test;

drop database if exists db_charmer_logs_test;
create database db_charmer_logs_test;

drop database if exists db_charmer_events_test_shard01;
create database db_charmer_events_test_shard01;

drop database if exists db_charmer_events_test_shard02;
create database db_charmer_events_test_shard02;

grant all privileges on db_charmer_sandbox_test.* to 'db_charmer_ro'@'localhost';
