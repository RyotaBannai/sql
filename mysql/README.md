## Memo

- MySQL server起動：`mysql.server start`
- 初回ログイン：`mysql -u root`
- ログアウト：`quit;`

## sakila dbのデータ投入
- ログイン：`mysql -u root`
- スキーマ投入：`source {path to this repo}/mysql/sakila-db/sakila-schema.sql`
- データ投入：`source {path to this repo}/mysql/sakila-db/sakila-data.sql`


### MySQL で初めてinstallした後にrootのパスの設定や、ユーザーを作成するなど

- [mysqlに慣れる、を参照](https://qiita.com/yukibe/items/4ba2aa49510ab1f6b1f1)
- rootのパス設定方法. `SET PASSWORD FOR root@localhost='auth_string';` [こちらを参照](https://www.dbonline.jp/mysql/user/index2.html)
- もしすでに設定している場合等は、`ALTER USER root@localhost IDENTIFIED BY 'auth_string';`で変更.
- コマンドライン から変更 `mysqladmin password 'auth_string' -u root@localhost -p` : パスワードの指定にシングルクォーテーションがあってもなくても問題なし.
- 念のため、初めにroot でminitorに入って新しいユーザーを作成してパスワードをうまく設定できるか確かめてから、rootの設定を変更するようにしたほうがいい。

## Mysql でsettingsを確認したい場合

- `show variables like '%char%';`でsettingsでcharを含むkeyに関する情報を閲覧できる.
- この方法でほとんどのsettingsは見れる. `show variable like '%version%';` `show variables like '%port%';`

## characterに関して

- character_set_system はファイル名に使用. [こちらを参照](https://qiita.com/yukiyoshimura/items/d44a98021608c8f8a52a)
- `show create table [table name];` DEFAULT CHARSET, COLLSTE を確認.
- サーバ側の文字コードセットは、データベース、テーブル、カラム単位で指定可能。小さな単位での指定が有効となる。ここでいうと**カラムに指定した文字コードが優先される**ので、文字化けなどの調査を行う際は、テーブル定義も確認する必要がある。
