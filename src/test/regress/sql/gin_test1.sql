-- gin 创建 修改 重建 删除 测试

-- Set GUC paramemter
SET ENABLE_SEQSCAN=OFF;
SET ENABLE_INDEXSCAN=OFF;
SET ENABLE_BITMAPSCAN=ON;


--
-- Test GIN indexes.
--
-- There are other tests to test different GIN opclassed. This is for testing
-- GIN itself.

-- Create and populate a test table with a GIN index.
drop table if exists gin_test_tbl;
create table gin_test_tbl(id int, i int4[]);
create index gin_test_idx on gin_test_tbl using gin (i) with (fastupdate = on);
insert into gin_test_tbl select g, array[1, 2, g] from generate_series(1, 200) g;
insert into gin_test_tbl select g, array[1, 3, g] from generate_series(1, 100) g;

vacuum gin_test_tbl; -- flush the fastupdate buffers

-- Test vacuuming
delete from gin_test_tbl where i @> array[2];
vacuum gin_test_tbl;

-- Disable fastupdate, and do more insertions. With fastupdate enabled, most
-- insertions (by flushing the list pages) cause page splits. Without
-- fastupdate, we get more churn in the GIN data leaf pages, and exercise the
-- recompression codepaths.
alter index gin_test_idx set (fastupdate = off);

insert into gin_test_tbl select g, array[1, g % 2, g] from generate_series(1, 100) g;
insert into gin_test_tbl select g, array[1, g % 3, g] from generate_series(1, 100) g;

delete from gin_test_tbl where i @> array[2];
vacuum gin_test_tbl;

drop table gin_test_tbl;

-- create table
DROP TABLE IF EXISTS test_gin_3;

CREATE TABLE test_gin_3(id int, info1 int[], info2 text[], info3 date[]);
INSERT INTO test_gin_3 VALUES (1, '{1,2,3}', '{abc, cbd, bcd, defg}', '{2010-01-01, 2011-01-01, 2012-01-01}');
INSERT INTO test_gin_3 VALUES (2, '{2,3,4}', '{abd, cbd, bcd, ccd}', '{2001-01-01,2002-01-01,2003-01-01}');
INSERT INTO test_gin_3 VALUES (3,'{3,4,5}','{bcd,def,ccf}','{2013-01-01}');
INSERT INTO test_gin_3 VALUES (4,'{4,5,6}','{aaa,bbb,ccc}','{2011-01-01,2012-01-02,2013-01-03}');
ANALYZE test_gin_3;
-- create index
CREATE INDEX test_gin_3_info1_idx ON test_gin_3 USING gin(info1);
CREATE INDEX test_gin_3_info2_idx ON test_gin_3 USING gin(info2);
CREATE INDEX test_gin_3_info3_idx ON test_gin_3 USING gin(info3);
-- set bitmap plan
SET enable_seqscan=off;
-- select query
SELECT * FROM test_gin_3 WHERE info1 @> '{1}'::int[] ORDER BY id, info1, info2, info3;
SELECT * FROM test_gin_3 WHERE info1 && '{1}'::int[] ORDER BY id, info1, info2, info3;
SELECT * FROM test_gin_3 WHERE info2 @> '{abc}'::text[] ORDER BY id, info1, info2, info3;
SELECT * FROM test_gin_3 WHERE info2 && '{abc}'::text[] ORDER BY id, info1, info2, info3;
SELECT * FROM test_gin_3 WHERE info3 @> '{2011-01-01}'::date[] ORDER BY id, info1, info2, info3;
SELECT * FROM test_gin_3 WHERE info3 && '{2011-01-01}'::date[] ORDER BY id, info1, info2, info3;
-- insert data and update index
INSERT INTO test_gin_3 VALUES (1, '{1,2,3}', '{abc, cbd, bcd, defg}', '{2010-01-01, 2011-01-01, 2012-01-01}');
INSERT INTO test_gin_3 VALUES (2, '{2,3,4}', '{abd, cbd, bcd, ccd}', '{2001-01-01,2002-01-01,2003-01-01}');
INSERT INTO test_gin_3 VALUES (3,'{3,4,5}','{bcd,def,ccf}','{2013-01-01}');
INSERT INTO test_gin_3 VALUES (4,'{4,5,6}','{aaa,bbb,ccc}','{2011-01-01,2012-01-02,2013-01-03}');
-- select query
SELECT * FROM test_gin_3 WHERE info1 @> '{1}'::int[] ORDER BY id, info1, info2, info3;
SELECT * FROM test_gin_3 WHERE info2 @> '{abc}'::text[] ORDER BY id, info1, info2, info3;
SELECT * FROM test_gin_3 WHERE info3 @> '{2011-01-01}'::date[] ORDER BY id, info1, info2, info3;

DROP TABLE test_gin_3;

create unlogged table gin_unlogged_tbl(id int, info int[]) ;
create index gin_unlogged_idx on gin_unlogged_tbl using gin(info);
checkpoint;
drop table gin_unlogged_tbl;

RESET ENABLE_SEQSCAN;
RESET ENABLE_INDEXSCAN;
RESET ENABLE_BITMAPSCAN;

