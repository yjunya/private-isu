# 1

1. benchmarkerを実行する
```
benchmarker-benchmarker-1  | {"pass":true,"score":0,"success":122,"fail":66,"messages":["リクエストがタイムアウトしました (GET /)","リクエストがタイムアウトしました (GET /@cindy)","リクエストがタイムアウトしました (GET /@evangeline)","リクエストがタイムアウトしました (GET /@hollie)","リクエストがタイムアウトしました (GET /@jamie)","リクエストがタイムアウトしました (GET /@joanne)","リクエストがタイムアウトしました (GET /@kaitlin)","リクエストがタイムアウトしました (GET /@leslie)","リクエストがタイムアウトしました (GET /@lila)","リクエストがタイムアウトしました (GET /@reva)","リクエストがタイムアウトしました (GET /@samantha)","リクエストがタイムアウトしました (GET /@whitney)","リクエストがタイムアウトしました (GET /@wilda)","リクエストがタイムアウトしました (POST /login)","リクエストがタイムアウトしました (POST /register)"]}
```

2. `docker stats (top)`コマンドで何に負荷が掛かっているかを確認する
- app
```
CONTAINER ID   NAME                 CPU %     MEM USAGE / LIMIT     MEM %     NET I/O           BLOCK I/O        PIDS
6a3d18be9257   webapp-nginx-1       0.00%     6.184MiB / 3.841GiB   0.16%     35.2MB / 35.2MB   3.44MB / 4.1kB   5
996f76088247   webapp-app-1         2.52%     347.5MiB / 1GiB       33.93%    265MB / 42.6MB    336kB / 8.19kB   14
de49cf61874c   webapp-mysql-1       100.01%   612.7MiB / 1GiB       59.83%    11.4MB / 260MB    161MB / 7.26GB   82
96ebc9c57616   webapp-memcached-1   0.03%     6.324MiB / 3.841GiB   0.16%     166kB / 114kB     2.48MB / 0B      10
86f1757db5be   go_todo_app-app-1    0.00%     16.58MiB / 3.841GiB   0.42%     17.6MB / 234kB    2.54MB / 256MB   31
b14a1e92ead4   todo-db              0.42%     282.9MiB / 3.841GiB   7.19%     63kB / 160kB      1.3MB / 534MB    45
```
- mysqlにボトルネック

3. スロークエリログを出力するように
- `/etc/my.cnf` に追記．
```
 [mysqld]
 default_authentication_plugin=mysql_native_password
+slow_query_log = 1
+slow_query_log_file = /tmp/slow.log
+long_query_time = 0
```

4. スロークエリログをmysqldumpslowで解析
- ローカルにログを持ってくる
```
docker compose -f ./webapp/docker-compose.yml cp mysql:/tmp/slow.log .
```
- 解析
```
mysqldumpslow slow.log
```
```
Reading mysql slow query log from slow.log
Count: 1470  Time=3.32s (4873s)  Lock=0.00s (0s)  Rows=2.9 (4230), root[root]@webapp-app-1.webapp_default
  SELECT * FROM `comments` WHERE `post_id` = N ORDER BY `created_at` DESC LIMIT N

Count: 2  Time=1.95s (3s)  Lock=0.00s (0s)  Rows=1.0 (2), root[root]@webapp-app-1.webapp_default
  SELECT COUNT(*) AS count FROM `comments` WHERE `post_id` IN (N, N, N, N, N, N, N, N, N, N, N)

Count: 1  Time=1.93s (1s)  Lock=0.00s (0s)  Rows=1.0 (1), root[root]@webapp-app-1.webapp_default
  SELECT COUNT(*) AS count FROM `comments` WHERE `post_id` IN (N, N, N, N, N, N, N, N, N, N, N, N)

Count: 1  Time=1.91s (1s)  Lock=0.00s (0s)  Rows=1.0 (1), root[root]@webapp-app-1.webapp_default
  SELECT COUNT(*) AS count FROM `comments` WHERE `post_id` IN (N, N, N, N, N)

Count: 2  Time=1.84s (3s)  Lock=0.00s (0s)  Rows=1.0 (2), root[root]@webapp-app-1.webapp_default
  SELECT COUNT(*) AS count FROM `comments` WHERE `post_id` IN (N, N, N, N, N, N, N, N, N, N, N, N, N)

Count: 3  Time=1.70s (5s)  Lock=0.00s (0s)  Rows=1.0 (3), root[root]@webapp-app-1.webapp_default
  SELECT COUNT(*) AS count FROM `comments` WHERE `post_id` IN (N, N, N, N, N, N, N, N)

Count: 13  Time=1.55s (20s)  Lock=0.00s (0s)  Rows=1.0 (13), root[root]@webapp-app-1.webapp_default
  SELECT COUNT(*) AS count FROM `comments` WHERE `user_id` = N

...
```
- 明らかに commentのpost_idでの検索が遅い

5. commentsにindexを貼る
- `/docker-entrypoint-initdb.d`(mysqlの初期化時に実行するディレクトリ) に追加する
- 初期のdumpを`0000_dump.sql`に変更して，`0001_add_index.sql`を作成
```
USE `isuconp`;

ALTER TABLE comments ADD INDEX post_id_idx (post_id, created_at DESC);
```

6. benchmarkerを実行
```
benchmarker-benchmarker-1  | {"pass":true,"score":8111,"success":7763,"fail":0,"messages":[]}
```
- 上がった
