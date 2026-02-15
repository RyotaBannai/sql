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

