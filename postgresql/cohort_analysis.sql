-- データ準備
DROP table if exists legislators_terms;
CREATE table legislators_terms
(
id_bioguide varchar
,term_number int
,term_id varchar primary key
,term_type varchar
,term_start date
,term_end date
,state varchar
,district int
,class int
,party varchar
,how varchar
,url varchar--terms_1_url
,address varchar --terms_1_address
,phone varchar --terms_1_phone
,fax varchar --terms_1_fax
,contact_form varchar --terms_1_contact_form
,office varchar--terms_1_office
,state_rank varchar --terms_1_state_rank
,rss_url varchar --terms_1_rss_url
,caucus varchar -- terms_1_caucus
)
;

COPY legislators_terms
FROM '/Users/ryotabannai/dev/github.com/RyotaBannai/sql/postgresql/data/legislators_terms.csv'
DELIMITER ','
CSV HEADER
;


DROP table if exists legislators;

CREATE table legislators
(
full_name varchar--name_official_full
,first_name varchar --name_first
,last_name varchar --name_last
,middle_name varchar --name_middle
,nickname varchar --name_nickname
,suffix varchar --name_suffix
,other_names_end date -- other_names_0_end date
,other_names_middle varchar -- other_names_0_middle
,other_names_last varchar -- other_names_0_last
,birthday date -- bio_birthday
,gender varchar-- bio_gender
,id_bioguide varchar primary key
,id_bioguide_previous_0 varchar
,id_govtrack int
,id_icpsr int
,id_wikipedia varchar
,id_wikidata varchar
,id_google_entity_id varchar
,id_house_history bigint
,id_house_history_alternate int
,id_thomas int
,id_cspan int
,id_votesmart int
,id_lis varchar
,id_ballotpedia varchar
,id_opensecrets varchar
,id_fec_0 varchar
,id_fec_1 varchar
,id_fec_2 varchar
)
;

COPY legislators
FROM '/Users/ryotabannai/dev/github.com/RyotaBannai/sql/postgresql/data/legislators.csv'
DELIMITER ','
CSV HEADER
;
-- データ終わり

-- 議員の最初の就任日から、再選挙も考えて、どれくらい就任してきたか
-- period=0年で、一回の任期で終わり。period=1以上で再当選を果たした（留任した）と考えられる。
select
    date_part('year', age(b.term_start, first_term)) period,
    count(distinct a.id_bioguide) cohort_retained
from (
    select
        id_bioguide,
        min(term_start) first_term
    from legislators_terms
    group by id_bioguide
    ) a -- 各議員が初めての就任日
join legislators_terms b on a.id_bioguide = b.id_bioguide
group by 1
;

-- 留任率（リテンション）
select
    period,
    first_value(cohort_retained) over (order by period) cohort_size,
    cohort_retained,
    cohort_retained * 100 / first_value(cohort_retained) over (order by period) pct_retained
from
(select
    date_part('year', age(b.term_start, first_term)) period,
    count(distinct a.id_bioguide) cohort_retained
from (
    select
        id_bioguide,
        min(term_start) first_term
    from legislators_terms
    group by id_bioguide
    ) a -- 各議員が初めての就任日
join legislators_terms b on a.id_bioguide = b.id_bioguide
group by 1
) aa
;


with retention_num_by_year as (
    select date_part('century', a.first_term) first_century,
           coalesce(date_part('year', age(c.date, a.first_term)), 0) period, -- 留任年数
           count(distinct a.id_bioguide) cohort_retained
    from (
        select
             id_bioguide,
            min(term_start) first_term
        from legislators_terms
        group by 1) a -- 議員ごとの最初の任期開始日
    join legislators_terms b on a.id_bioguide = b.id_bioguide
    left join date_dim c
        on c.date between b.term_start and b.term_end -- 任期開始日と終了日の年度を全てjoinする
        and c.month_name = 'December' and
           c.day_of_month = 31 -- ただし、その１年分は12/31だけ残す
   group by 1, 2
   )
select
    first_century,
    period,
    first_value(cohort_retained) over (partition by first_century order by period) cohort_size,
    cohort_retained,
    round(cohort_retained * 1.0 / first_value(cohort_retained) over (partition by first_century order by period),2) pct_retained
from retention_num_by_year
;



-- リテンショングラフをグラフ上の最終periodまで描画する。
-- （課題）リテンションが０になる前にデータポイントがnullになる場合の対策（リテンションが最後は０になるようにする）
with
    first_date_and_state as (
        select
            distinct id_bioguide,
            min(term_start) over (partition by id_bioguide) first_term,
            first_value(state) over (
                partition by id_bioguide
                order by term_start
                ) first_state
        from legislators_terms
    ), -- 議員ごとの最初の任期開始日とその州
    cohort_size_by_gender_state as (
        select
            b.gender,
            a.first_state,
            count(distinct a.id_bioguide) cohort_size
        from first_date_and_state a
        join legislators b on a.id_bioguide = b.id_bioguide
        where a.first_term between '1917-01-01' and '1999-12-31' -- 初期の任期が2000年以前の議員に絞る
        group by 1, 2
    ), -- 性別・州でコホート
    /*
    gender,first_state,cohort_size
    F,AL,3
    F,AR,5
    F,AZ,2
    ...
    */
    aaa as (
        select
            aa.gender,
            aa.first_state,
            cc.period,
            aa.cohort_size
        from cohort_size_by_gender_state aa
        join (
            select generate_series period
            from generate_series(0,20,1)
        ) cc
        on 1=1
    ) -- 性別・州の行に対して、1~20periodを外部結合。periodの欠損がなくなるような工夫。
    /*
    gender,first_state,period,cohort_size
    F,AL,0,3
    F,AR,0,5
    F,AZ,0,2
    ...
    */,
    ddd as (
        select
            d.first_state,
            g.gender,
            coalesce(date_part('year', age(f.date, d.first_term)), 0) period,
            count(distinct d.id_bioguide) cohort_retained
        from first_date_and_state d
        join legislators_terms e on d.id_bioguide = e.id_bioguide
        left join date_dim f
            on f.date between e.term_start and e.term_end -- 任期開始日と終了日の年度を全てjoinする
            and f.month_name = 'December' and f.day_of_month = 31 -- ただし、その１年分は12/31だけ残す
        join legislators g on d.id_bioguide = g.id_bioguide
        where d.first_term between '1917-01-01' and '1999-12-31'
        group by 1, 2, 3
    )
        -- state,gender,period でコホートリテンションを求める。
        -- 日付ディメンジョンで期間の欠損値補完ができるが、
        -- 期間外に対してはperiodに欠損が発生。
        -- 例えば、2periodが最長の行しかない場合は3periodのデータポイント以降は欠損になるため、
        -- retentionグラフが途中で途絶える。
    /*
    first_state,gender,period,cohort_retained
    AL,F,0,3
    AL,F,1,1
    ...
    */
-- select *
-- from ddd
-- where ddd.first_state = 'AL' and ddd.gender = 'F'
select
    aaa.first_state,
    aaa.gender,
    aaa.period,
    aaa.cohort_size,
    coalesce(ddd.cohort_retained,0) cohort_retained,
    coalesce(cohort_retained,0) * 1.0 / aaa.cohort_size pct_retained
from aaa
left join ddd
on aaa.first_state = ddd.first_state
    and aaa.gender = ddd.gender
    and aaa.period = ddd.period
where aaa.first_state = 'AL' and aaa.gender = 'F'
order by 1,2,3
;

-- debug
-- select *
-- from legislators_terms a
-- join legislators b on a.id_bioguide = b.id_bioguide
-- join (select
--             distinct id_bioguide,
--             min(term_start) over (partition by id_bioguide) first_term,
--             first_value(state) over (
--                 partition by id_bioguide
--                 order by term_start
--                 ) first_state
--         from legislators_terms) c on c.id_bioguide = a.id_bioguide
-- where c.first_term between '1917-01-01' and '1999-12-31'
-- and c.first_state = 'AL' and b.gender = 'F'


-- 開始値以外の値をコホートにするコホート分析（ここでは、在籍途中からコホートにする。ミッドターム分析）
-- 本例以外にも、あるエンティティがある閾値（ある購入回数やある消費額など）に達した後のリテンションを分析する、など考えられる。
with all_legislators_2000 as (
    -- legislators_termsには同じ議員が複数存在。
    -- 同じ議員が複数行ある場合は、いずれかが条件を満たしていれば取り出す。
    select
        distinct id_bioguide,
                 term_type,
                 date('2000-01-01') as first_term,
                 min(term_start) as min_start -- いつから在任しているか
    from legislators_terms
    where term_start <= '2000-12-31'
      and term_end >= '2000-01-01'
        -- 初めはレンジの日付設定が逆では？と考えたが、
        -- 2000年台に就任しているかどうかをみたいため、正しい。
        -- またterm_start<=term_endであることが前提。
    group by 1,2,3
/*
id_bioguide,term_type,first_term,min_start
H001014,rep,2000-01-01,1999-01-06
K000259,rep,2000-01-01,1999-01-06
K000210,rep,2000-01-01,1999-01-06
B000944,rep,2000-01-01,1999-01-06
J000072,sen,2000-01-01,1995-01-04
*/
), aa as (
    select
        a.term_type,
        coalesce(date_part('year', age(c.date, a.first_term)), 0) period, -- 留任年数
        count(distinct a.id_bioguide) cohort_retained -- 在任数
    from all_legislators_2000 as a
    join legislators_terms b on a.id_bioguide = b.id_bioguide
        and b.term_start >= a.min_start
        -- ここ重要
        -- 「all_legislators_2000」におけるフィルタは2000年度に在任していた行のみ。
        -- 同議員であってもmin_startより前に就任していた期間はの行は集計対象外。
        -- 一方でmin_start以降の在任期間は全て主計対象に含める。
        -- これは「2000年台に在任」コホートを作ってmin_startから各議員の任期期間を計算したいためであり、min_start以降の在任については「いつまで在任していたか」を計算するために全て集計対象とする必要があるため。
    left join date_dim c
        on c.date between b.term_start and b.term_end -- 任期開始日と終了日の年度を全てjoinする(つまり人気期間中の年度分の行を作成する)
        and c.month_name = 'December' and c.day_of_month = 31 -- ただし、その１年分は12/31だけ残す
        and c.year >= 2000
    group by 1, 2
    )
/*
term_type,period,cohort_retained
rep,0,440
rep,1,392
rep,2,389
rep,3,340
rep,4,338
...
*/
-- select *
-- from aa;
select
    term_type,
    period,
    first_value(cohort_retained) over (partition by term_type order by period) cohort_size,
    cohort_retained,
    cohort_retained * 1.0 / first_value(cohort_retained) over (partition by term_type order by period) pct_retained
from aa;
/*
term_type,period,cohort_size,cohort_retained,pct_retained
rep,0,440,440,1
rep,1,440,392,0.89090909090909090909
rep,2,440,389,0.88409090909090909091
rep,3,440,340,0.77272727272727272727
rep,4,440,338,0.76818181818181818182
rep,5,440,308,0.7
*/


select
    first_century,
    count(distinct id_bioguide) cohort_size,
    count(distinct case when total_terms >= 5 then id_bioguide end) survived_5,
    count(distinct case when total_terms >= 5 then id_bioguide end) * 1.0 / count(distinct id_bioguide) pct_survived_t_terms -- 全体の中でどれくらいか
from (
    select
    id_bioguide,
    date_part('century',  min(term_start)) first_century,
    count(term_start) total_terms -- 単純に任期をカウントする
from legislators_terms
group by 1
     ) a
group by 1
;

-- 累積計算
with ten_years_from_first_term as (
    select
        distinct id_bioguide,
        first_value(term_type) over (partition by id_bioguide order by term_start) first_type,
        min(term_start) over (partition by id_bioguide) first_term,
        min(term_start) over (partition by id_bioguide) + interval '10 years' first_plus_10 -- 初期の任期開始から10年間のintervalを設ける
    from legislators_terms
)
select
    date_part('century', a.first_term) century, -- 世紀ごとに
    first_type, -- 上院or下院
    count(distinct a.id_bioguide) cohort,  -- ユニークな議員数
    count(b.term_start) terms -- 世紀ごとの行数
from ten_years_from_first_term a
left join legislators_terms b on a.id_bioguide = b.id_bioguide
and b.term_start between a.first_term and a.first_plus_10 -- 同じ議員について10年以内の行を集計対象にする
group by 1,2 -- どのようにコホートにしたいかはグループで決定する。
;


-- date_dim自体にnullなし。
select * from date_dim where date is null;

-- 下記sqlでdateになるが発生。最終的な結果にもdateがnullで集計される事象発生->結果セットの歪み。
select distinct a.id_bioguide, a.term_start, a.term_end,
                b.date orig_date,
                coalesce(b.date, date_trunc('year', a.term_start) + interval '1 year - 1 day') date
from legislators_terms a
left join date_dim b
    on b.date between a.term_start and a.term_end -- 任期開始日と終了日の年度を全てjoin
    and b.month_name = 'December' and b.day_of_month = 31 -- ただし、その１年分は12/31だけ残す
    and b.year <= 2019
where b.date is null
order by 1,2;
-- 下記のように年末まで就任してないand1年未満の条件下で、left joinなのでnullが発生。
-- このような場合はビジネス上どのように対応するか決まっていればそれで対応。除外or1年とみなす、orその他
-- 一年とみなすなら、その年の年末を設定してあげれば良い。
/*
id_bioguide,date,term_start,term_end
A000083,,1881-03-04,1881-10-04
A000130,,1889-03-04,1889-11-11
*/

-- 年度ごとの議員の任期年数の割合を出してみる
with all_years_by_each as (
    select distinct a.id_bioguide,
    coalesce(b.date, date_trunc('year', a.term_start) + interval '1 year - 1 day') date
from legislators_terms a
left join date_dim b
    on b.date between a.term_start and a.term_end -- 任期開始日と終了日の年度を全てjoin
    and b.month_name = 'December' and b.day_of_month = 31 -- ただし、その１年分は12/31だけ残す
    and b.year <= 2019
order by 1,2
),

-- all_years_by_eachは任期のstartとendした見ないため、任期間に空白等がある場合は考慮しない点に注意。
-- 例えば、id_bioguide=A000014

cume_years_t as (
    select
    id_bioguide, date,
    count(date) over (
        partition by id_bioguide
        order by date
        rows between unbounded preceding and current row
        ) cume_years
from all_years_by_each
),
/*
id_bioguide,date,cume_years
A000001,1951-12-31,1
A000001,1952-12-31,2
A000002,1947-12-31,1
A000002,1948-12-31,2
...
*/
n_legislators_t as (
    select
        id_bioguide,
        date,
        count(distinct id_bioguide) n_legislators
    from cume_years_t
    group by 1,2
),
-- コホートに分ける前にカウントすると連続値のカテゴリ数が膨大になってわかりにくい。
-- 下記のように扱い切れるカテゴリに分類するとよい。
/*
date,cume_years,n_legislators
1996-12-31,20,18
1996-12-31,21,1
1996-12-31,22,18
1996-12-31,23,2
1996-12-31,24,19
...
*/
n_legislators_t2 as (
    select
        date,
        case when cume_years <= 4 then '1 to 4'
             when cume_years <= 10 then '5 to 10'
             when cume_years <= 20 then '11 to 20'
             else '21+' end tenure,
        count(distinct id_bioguide) legislators
        from cume_years_t
    group by 1,2
    )
select
    date,tenure,
    legislators / sum(legislators) over (partition by date) pct_legislators
from n_legislators_t2
order by 1 desc
;

-- 任期が連続してない議員を特定する
-- 特に任期に空白が出ているdateを特定
with all_years_by_each as (
    select distinct a.id_bioguide, b.date
    from legislators_terms a
    left join date_dim b
        on b.date between a.term_start and a.term_end -- 任期開始日と終了日の年度を全てjoin
        and b.month_name = 'December' and b.day_of_month = 31 -- ただし、その１年分は12/31だけ残す
        and b.year <= 2019
    order by 1,2
),
with_continuous_flag as (
    select
        id_bioguide,date,
        coalesce(
            age(date, lag(date) over (partition by id_bioguide order by date)) = interval '1 year',true
        ) continuous_flag
    from all_years_by_each
),
with_flag as (
    select
        id_bioguide, date,
        coalesce (
            not continuous_flag or
            not lead(continuous_flag) over (partition by id_bioguide order by date), false
        ) flag
    from with_continuous_flag
)
select id_bioguide,date
from with_flag
where flag
;