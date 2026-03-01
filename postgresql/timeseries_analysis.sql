-- timeseries analysisの準備
DROP table if exists retail_sales;
CREATE table retail_sales
(
sales_month date
,naics_code varchar
,kind_of_business varchar
,reason_for_null varchar
,sales decimal
);
COPY retail_sales
FROM '/Users/ryotabannai/dev/github.com/RyotaBannai/sql/postgresql/data/us_retail_sales.csv'
DELIMITER ','
CSV HEADER
;


-- datagrip上でgroupごとの推移を可視化するには、
-- x axisをgroup and sortする必要がある。
select
    date_part('year', sales_month) sales_year,
    kind_of_business,
    sum(sales) sales
from retail_sales
where kind_of_business in (
    'Book stores',
    'Sporting goods stores',
    'Hobby, toy, and game stores')
group by 1, 2
order by 1, 2;

-- datagrip上でgroupごとの推移の可視化にx axisをgroup and sortするしなくとも良い方法。
-- ただ、group分new series を追加する必要があるため、やや手間である。
SELECT *
FROM crosstab(
    $$
        select
            date_part('year', sales_month)::int sales_year,
            kind_of_business,
            sum(sales) sales
        from retail_sales
        where kind_of_business in (
            'Book stores',
            'Sporting goods stores',
            'Hobby, toy, and game stores')
        group by 1, 2
        order by 1, 2
    $$
) AS ct (
    sales_year int,
    book_stores numeric,
    sporting_goods_stores numeric,
    hobby_stores numeric
);

-- 月毎のkind of businessでの小売売上高データ。
select a.sales_month, a.kind_of_business, a.sales
from retail_sales a
where a.kind_of_business in (
    'Men''s clothing stores', 'Women''s clothing stores')
group by 1,2,3
order by 1,2,3;


-- 全体対部分で構成比計算するSQL
-- 女性衣料品、男性衣料品のレコードに対して、女性衣料品、男性衣料品が作られる（部分クロス結合）。
-- その上で倍に複製されたレコードを集約して合計値を求める。
select a.sales_month, a.kind_of_business, a.sales,
sum(b.sales) total_sales
from retail_sales a
join retail_sales b
on a.sales_month = b.sales_month
and b.kind_of_business in (
    'Men''s clothing stores', 'Women''s clothing stores')
where a.kind_of_business in (
    'Men''s clothing stores', 'Women''s clothing stores')
group by 1,2,3
order by 1,2,3;

-- 女性衣料品、男性衣料品の月毎の売り上げ割合をその年全体の部分として比率を求める
select
    sales_month,
    sales,
    kind_of_business,
    sum(sales) over(partition by
        date_part('year', sales_month),
        kind_of_business) as yearly_sales, -- 年間の売り上げ高
    sales * 100 / sum(sales) over(partition by
        date_part('year', sales_month),
        kind_of_business) as pct_yearly -- 部分の割合
from retail_sales
where kind_of_business in (
    'Men''s clothing stores', 'Women''s clothing stores')
and sales_month >= '2019-01-01' and sales_month < '2020-01-01'
order by 1,2
;

-- Window関数を使わないで指標化する
with
    b as (
    select
        min(date_part('year', sales_month)) as first_year
    from retail_sales
    where kind_of_business = 'Women''s clothing stores'
), -- 初年度の年度を取り出す（スカラー値）
    bb as (
    select
        first_year,
        sum(a.sales) as index_sales
    from retail_sales a
    join b on date_part('year', a.sales_month) = b.first_year
    where a.kind_of_business = 'Women''s clothing stores'
    group by 1
), -- 初年度の小売売上高の合計値を求める（スカラー値とその合計の行）
    bbb as (
    select
        sales_year, sales, index_sales
    from (
        select
            date_part('year', sales_month) as sales_year,
            sum(sales) as sales
        from retail_sales
        where kind_of_business =  'Women''s clothing stores'
        group by 1
        order by 1
    ) aa
    join bb
    on 1=1 -- 単に一つの行を、各行に追加したい（列を追加したい）。クロス結合
) --- 各年度の売上高と初年度の売上高を各行で持ったテーブルを作成
select
    sales_year,
    sales,
    (sales/index_sales -1)*100 as pct_from_index --- 初年度に対する各年の指標を計算（指標化）
from bbb
;


-- 移動平均
select
    sales_month,
    sales,
    avg(sales) over (order by sales_month rows between 11 preceding and current row ) as moving_avg,
    count(sales) over (order by sales_month rows between 11 preceding and current row ) as row_count
from retail_sales
where kind_of_business =  'Women''s clothing stores'
;



-- 日付ディメンジョン
DROP table if exists public.date_dim;

CREATE table public.date_dim
as
SELECT date::date
,to_char(date,'yyyymmdd')::int as date_key
,date_part('day',date)::int as day_of_month
,date_part('doy',date)::int as day_of_year
,date_part('dow',date)::int as day_of_week
,trim(to_char(date, 'Day')) as day_name
,trim(to_char(date, 'Dy')) as day_short_name
,date_part('week',date)::int as week_number
,to_char(date,'W')::int as week_of_month
,date_trunc('week',date)::date as week
,date_part('month',date)::int as month_number
,trim(to_char(date, 'Month')) as month_name
,trim(to_char(date, 'Mon')) as month_short_name
,date_trunc('month',date)::date as first_day_of_month
,(date_trunc('month',date) + interval '1 month' - interval '1 day')::date as last_day_of_month
,date_part('quarter',date)::int as quarter_number
,trim('Q' || date_part('quarter',date)::int) as quarter_name
,date_trunc('quarter',date)::date as first_day_of_quarter
,(date_trunc('quarter',date) + interval '3 months' - interval '1 day')::date as last_day_of_quarter
,date_part('year',date)::int as year
,date_part('decade',date)::int * 10 as decade
,date_part('century',date)::int as centurys
FROM generate_series('1770-01-01'::date, '2030-12-31'::date, '1 day') as date
;

select *
from date_dim
;

-- 疎なデータ、欠損のあるデータが存在-> クロス結合
-- 日付に欠損値がある場合に日付ディメンジョンがあると
-- 欠損した日付に対応するデータポイントをがあるかどうかにかかわらず全ての日付の結果が得られる。
with b as (
    select
        sales_month,
        sales
    from retail_sales
    where kind_of_business = 'Women''s clothing stores'
    and date_part('month', sales_month) in (1,7) -- 欠損状況を再現..
)
select
    a.date,
    b.sales_month,
    b.sales
from date_dim a
join b on b.sales_month between a.date - interval '11 months' and a.date -- 過去12ヶ月分の行のみ外部結合。
where a.date = a.first_day_of_month -- a.dateには日も含む。月データにしたい
and a.date between '2020-01-01' and '2020-12-01'
order by 1
;

-- 累積値
-- ORDER BYのウィンドウフレーム：RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW。
-- ORDER BYを削除するとウィンドウフレームも消えるため、PARTITION BYのグループ内の全行が対応。
select
    sales_month,
    sales,
    sum(sales) over (partition by date_part('year', sales_month) order by sales_month) sales_ytd
from retail_sales
where kind_of_business = 'Women''s clothing stores'
;


-- 動的にテーブルを使って、列をマージするのはsqlでは難しい
-- sqlで列をマージするにはpivotを用いるのが良いが、selectの要素ごとを管理する手間が残る。
-- BI/可視化やアプリ側（Tableau/PowerBI/pandas）などdownstreamでpivotできるかどうかを検討する。
--
-- with sales_1992 as (
--     select
--         sales,
--         date_part('month', sales_month) as month
--     from retail_sales
--     where kind_of_business = 'Book stores'
--     and date_part('year',sales_month) = 1992
-- ),
-- sales_1993 as (
--     select
--         sales,
--         date_part('month', sales_month) as month
--     from retail_sales
--     where kind_of_business = 'Book stores'
--     and date_part('year',sales_month) = 1993
-- )
-- select *
-- from sales_1992
-- join sales_1993
-- on sales_1992.month = sales_1993.month
-- ;