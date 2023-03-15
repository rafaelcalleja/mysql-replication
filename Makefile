PASSWORD ?= my-secret-pw

slave1: slave
slave:
	MYSQL_PWD=$(PASSWORD) mysql -uroot -P3602 -h127.0.0.1

lag: slaves-status
slaves-status:
	@MYSQL_PWD=$(PASSWORD) mysql -uroot -P3602 -h127.0.0.1 -e "SHOW SLAVE STATUS\G"| grep Seconds_Behind_Master
	@MYSQL_PWD=$(PASSWORD) mysql -uroot -P3603 -h127.0.0.1 -e "SHOW SLAVE STATUS\G"| grep Seconds_Behind_Master

slave2:
	MYSQL_PWD=$(PASSWORD) mysql -uroot -P3603 -h127.0.0.1

master:
	MYSQL_PWD=$(PASSWORD) mysql -uroot -P3601 -h127.0.0.1

master-create-schema:
	MYSQL_PWD=$(PASSWORD) mysql -uroot -P3601 -h127.0.0.1 -e "drop database if exists test; create database test \n; use test; CREATE TABLE t(id INT AUTO_INCREMENT PRIMARY KEY, v DOUBLE, d DATETIME); INSERT INTO t (v, d) SELECT 1, NOW() FROM information_schema.INNODB_METRICS LIMIT 10; INSERT INTO t (v, d) SELECT 1, NOW() FROM information_schema.INNODB_METRICS LIMIT 10;"

master-create-lag:
	@MYSQL_PWD=$(PASSWORD) mysql -uroot -P3601 -h127.0.0.1 -e "use test; SET binlog_format = STATEMENT; UPDATE t SET v = SLEEP(0.2), d = now() WHERE id < 20;"

master-show-clients:
	@MYSQL_PWD=$(PASSWORD) mysql -uroot -P3601 -h127.0.0.1 -e "SELECT tmp.ipAddress, COUNT( * ) AS numConnections, FLOOR( AVG( tmp.time ) ) AS timeAVG, MAX( tmp.time ) AS timeMAX, GROUP_CONCAT(tmp.info) FROM ( SELECT pl.id, pl.user, pl.host, pl.db, pl.command, pl.time, pl.state, pl.info, LEFT( pl.host, ( LOCATE( ':', pl.host ) - 1 ) ) AS ipAddress FROM INFORMATION_SCHEMA.PROCESSLIST pl WHERE user = 'root' ) AS tmp GROUP BY tmp.ipAddress, tmp.info ORDER BY numConnections DESC;"

master-script-lag:
	while sleep 1; do for i in $$(seq 1 10); do \
	mysql -uroot -pmy-secret-pw -P 3601 -h127.0.0.1 -e " \
	use test; SET binlog_format = STATEMENT; UPDATE t SET v = SLEEP(0.2), d = now() WHERE id = $$i" & \
	done; done

proxy:
	MYSQL_PWD=$(PASSWORD) mysql -uroot -P16033 -h127.0.0.1

proxy-admin:
	MYSQL_PWD=$(PASSWORD) mysql -uroot -P16032 -h127.0.0.1

proxy-logs:
	docker-compose logs -f proxysql

servers:
	 @echo "master=$(shell docker ps -aqf "name=mysql-replication_mysql-master_1")"
	 @echo "slave1=$(shell docker ps -aqf "name=mysql-replication_mysql-slave_1")"
	 @echo "slave2=$(shell docker ps -aqf "name=mysql-replication_mysql-slave-2_1")"

proxy-lock: servers
	@MYSQL_PWD=$(PASSWORD) mysql -uroot -P16033 -h127.0.0.1 -e "SELECT *, (SELECT @@hostname), (SELECT SLEEP(1)) from test.t FOR UPDATE"

proxy-lock-no-multiplex: servers
	@MYSQL_PWD=$(PASSWORD) mysql -uroot -P16033 -h127.0.0.1 -e "SET FOREIGN_KEY_CHECKS=0; SELECT *, (SELECT @@hostname), (SELECT SLEEP(1)) from test.t FOR UPDATE"

