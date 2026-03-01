##

### Misc

- start server `brew services start postgresql` 
- replに入る：`psql postgres`
- stop `brew services stop postgresql`
- list databases `\list` or `\l`
- choose database `\c [database name]`
- create database `create database [database name];` (in repl)
- `createdb -O [username] [dbname]` -> create new db with owner. (from command line)
- create table `create table People (id char(4) NOT NULL, name text NOT NULL, age integer , primary key(id));` put all scheme inside () each data should be separated by comma and each set has column name, data type, and restrictin, such as NOT NULL.
- `\d [dbname]` -> check table scheme.
- `insert into people(id, name, age) values('0001', 'Jobs', 23);` -> insert data example.
- `insert into people values('0001', 'Jobs', 23);` -> omit columns for simplicity.
- SELECT 句には、テーブルから取り出したい列名を書き並べ, FROM 句には、データを取り出すテーブル名を指定.
- `update people set id='0004' where name='Jobs';` -> update data
- `UPDATE people SET age = 46;` -> CHANGE **ALL** ENTRIES!!!
- `delete from [table name] where [conditinal];` -> delete entry.
- `DELETE from people;` -> DELETE **ALL** ENTRIES!!!
- group by を使うときは取ってくるデータが単一の値になるようにする. データが数値とかなら sum()関数を使ったりする.(このような関数を使って複数のデータをまとめることを「集約式」と言う.)
- WHERE 句は、グループ化されていない列によって行を選択している（この式では最近の 4 週間の売上のみが真になります）のに対し、HAVING 句は出力を売上高が 5000 を超えるグループに制限しています。 集約式が、問い合わせ内で常に同じである必要がないことに注意してください。
