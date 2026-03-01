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