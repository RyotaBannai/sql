# use sakila;
# select title, rating
# from film
# where rating in (select rating from film where title like '%PET%');
# desc film_actor;
# desc actor;
# desc film;
# desc address;
# desc city;

# 複合クエリ(compound query)
select a.first_name, a.last_name
from actor a
where a.first_name like 'J%' and a.last_name like 'D%'
except
select c.first_name, c.last_name
from customer c
where c.first_name like 'J%' and c.last_name like 'D%';

# 日付操作
select * from mysql.time_zone;
SELECT extract(year from current_time);

# 集計関数
select customer_id,
       max(amount),
       min(amount),
       avg(amount),
       sum(amount) tot_amt,
       count(amount)
from payment
group by customer_id
order by tot_amt desc ;

# 非相関サブクエリ（noncorrelated subquery）
# ・サブクエリの中に外側のクエリの列データが使われない
select customer_id, count(*)
from rental
group by customer_id
having count(*) > (
    select max(t.cnt)
    from (
        select r.customer_id, COUNT(*) AS cnt
        from rental r
            inner join customer c
            on r.customer_id = c.customer_id
            inner join address addr
            on addr.address_id = c.address_id
            inner join city ct
            on ct.city_id = addr.city_id
            inner join country co
            on co.country_id = ct.country_id
        where co.country in ('United States', 'Canada', 'Mexico')
        group by r.customer_id
        ) AS t
    );


# 相関サブクエリ（correlated subquery）
# ・サブクエリの中に外側のクエリの列データが使われる（サブクエリが外側のクエリの列データに依存する）
# ・サブクエリ単体で実行しても実行できない（[42S22][1054] Unknown column 'c.customer_id' in 'where clause'）
# ・サブクエリは外側のクエリの行ごとに実行されるため、外側のクエリが大量の行を返す場合はパフォーマンスの問題になる。
# ※先にサブクエリを作ってから、それをJOINすることで同様のことができる（CTEも使えるから可読性が良い？）。
select *
from customer c
where 20 = (select count(*)
            from rental r
            where r.customer_id = c.customer_id
    );


# 相関サブクエリ
# カテゴリがActionであるfilm

# desc film;
# desc category;
# desc film_category;
# show tables;
select *
from film f
where 'Action' = (
    select c.name
    from category c
    inner join film_category fc
    on fc.category_id = c.category_id
    where f.film_id = fc.film_id
    );


desc film_actor;


select a.first_name, a.last_name, lvl_t.level, cnt_t.cnt
from (
    select count(*) cnt, actor_id
    from film_actor fa
    group by fa.actor_id) cnt_t
inner join actor a
    on a.actor_id = cnt_t.actor_id
inner join  (
    select 'hollywood star' level, 30 min_roles, 99999 max_roles
    union all
    select 'prolific actor' level, 20 min_roles, 29 max_roles
    union all
    select 'newcomer' level, 0 min_roles, 19 max_roles) lvl_t
    on cnt_t.cnt between lvl_t.min_roles and lvl_t.max_roles;

select f.film_id, f.title, i.inventory_id
from film f
    inner join inventory i
    on f.film_id = i.film_id
where f.film_id between 13 and 15;


# select f.film_id, f.title
# from film f;


select tbl.table_name,
    (select count(*)
    from information_schema.STATISTICS sta
    where sta.table_schema = tbl.table_schema
      and sta.TABLE_NAME = tbl.TABLE_NAME) num_indexes
from information_schema.TABLES tbl
where tbl.TABLE_SCHEMA = 'sakila'
  and tbl.TABLE_TYPE = 'BASE TABLE'
ORDER BY 1;

# 動的SQL
set @qry = 'select customer_id, first_name, last_name from customer;'
prepare dynsql1 from @qry;
execute dynsql1;
deallocate prepare dynsql1;

# sakilaスキーマのインデックスを全てリストアップする
select sta.TABLE_NAME, sta.INDEX_NAME
from (select *
from information_schema.tables tbl
where tbl.TABLE_SCHEMA = 'sakila'
and tbl.TABLE_TYPE = 'BASE TABLE') tables
left join information_schema.STATISTICS sta
on sta.TABLE_NAME = tables.TABLE_NAME;


WITH idx_info AS (
  SELECT
    table_name,
    index_name,
    column_name,
    seq_in_index,
    MAX(seq_in_index) OVER (PARTITION BY table_name, index_name) AS num_columns
  FROM information_schema.statistics
  WHERE table_schema = 'sakila'
    AND table_name = 'customer'
)
SELECT CONCAT(
         CASE
           WHEN seq_in_index = 1 THEN
             CONCAT('ALTER TABLE ', table_name, ' ADD INDEX ', index_name, ' (', column_name)
           ELSE
             CONCAT(', ', column_name)
         END,
         CASE
           WHEN seq_in_index = num_columns THEN ');'
           ELSE ''
         END
       ) AS index_creation_statement
FROM idx_info
ORDER BY index_name, seq_in_index;


# 解析関数 in action
select monthname(payment_date) payment_month,
    sum(amount) month_total,
    round(sum(amount)/sum(sum(amount))  over () * 100,2) pct_of_total
from payment
group by monthname(payment_date)