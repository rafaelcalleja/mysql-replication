# MySQL Replication

Proxying write & read request to its intended master/slave MySQL instance using ProxySQL.

![diagram](img/diagram.jpg)

## How to use?

Run `docker-compose.yaml` and use the following credential to connect to ProxySQL:

- **port:** 16033
- **username:** root
- **password:** my-secret-pw

https://jfg-mysql.blogspot.com/2022/05/triggering-replication-lag-for-testing-a-script.html
create database test
CREATE TABLE t(id INT AUTO_INCREMENT PRIMARY KEY, v DOUBLE, d DATETIME);
INSERT INTO t (v, d) SELECT 1, NOW() FROM information_schema.INNODB_METRICS LIMIT 10;

SET GLOBAL binlog_group_commit_sync_delay = 50000;

#lag manual use test; SET binlog_format = STATEMENT; UPDATE t SET v = SLEEP(0.2), d = now() WHERE id < 20;
#lag script

while sleep 1; do for i in $(seq 1 10); do
mysql -uroot -pmy-secret-pw -P 3601 -h127.0.0.1 <<< "
use test;
SET binlog_format = STATEMENT;
UPDATE t SET v = SLEEP(0.2), d = now() WHERE id = $i" & done; done

#slave lock
mysql -uroot -pmy-secret-pw -P 16033 -h127.0.0.1 -e "SELECT *, (SELECT @@hostname), (SELECT SLEEP(1)) from test.t FOR UPDATE"

https://proxysql.com/documentation/multiplexing/

