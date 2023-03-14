create database tmp;
use tmp;
START TRANSACTION; DROP TABLE IF EXISTS tmp.test3; create table tmp.test3 as select RAND() as r1 ,RAND() as r2 ,RAND() as r3,RAND() r4,RAND() as r5,RAND() as r6,RAND() as r7,RAND() as r8; COMMIT;

create index a4 ON test3 (r1,r2,r3,r4);
create index a5 ON test3 (r1,r2,r3,r4,r5);
create index a6 ON test3 (r1,r2,r3,r4,r5,r6);
create index a7 ON test3 (r1,r2,r3,r4,r5,r6);
create index a8 ON test3 (r1,r2,r3,r4,r5,r6,r7);
create index a9 ON test3 (r1,r2,r3,r4,r5,r6,r7,r8);


mysql -uroot -pmy-secret-pw -P16033 -h127.0.0.1 -e "SELECT SLEEP(100)"
while true; do mysql -uroot -pmy-secret-pw -P 3601 -h127.0.0.1 -e "insert into tmp.test3(r1,r2,r3,r4,r5,r6,r7,r8) values(RAND(),RAND(),RAND(),RAND(),RAND(),RAND(),RAND(),RAND());"; done
start transaction;DROP TABLE IF EXISTS tmp.test10; create table tmp.test10 as select * from tmp.test3; insert into tmp.test3 select * from tmp.test10; COMMIT;

