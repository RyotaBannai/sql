-- 型変換
-- １日ごとの期間を取り出す
select  *
from generate_series('2001-01-01'::timestamp, '2030-12-31', '1 day');

-- 一時的なpivotテーブル(国ごとの人口推移)/ 横持ち
DROP TABLE IF EXISTS pivot_population;
CREATE TABLE pivot_population (
    country   text,
    year_1980     text,
    year_1990     text,
    year_2000     text,
    year_2010     text,
    population    int
);
INSERT INTO pivot_population(country, year_1980, year_1990, year_2000, year_2010) VALUES
('Canada', 24593, 27791, 31100, 34207),
('Mexico', 68347,84643, 99775, 114061),
('US', 227225,249623, 282162, 309326);

-- select *
-- from pivot_population;

-- country,year,populationにunpivotする/縦持ち
select
    country,
    '1980' as year,
    year_1980 as population
from pivot_population union
select
    country,
    '1990',
    year_1990
from pivot_population union
select
    country,
    '2000',
    year_2000
from pivot_population union
select
    country,
    '2010',
    year_2010
from pivot_population;

-- unnestを使ってunpivotする/縦持ち
select
    country,
    unnest(array['1980','1990','2000','2010']),
    unnest(array[year_1980,year_1990,year_2000,year_2010])
from pivot_population;

SELECT * FROM pg_available_extensions WHERE name = 'tablefunc';
CREATE EXTENSION tablefunc;

-- crosstabを使ってunpivot-> pivotへ変換
-- crosstabは「最初の3列だけ使う」前提なので、列順がズレると壊れる。
-- 必ず SELECT country, year, value のように明示した方が安全。
SELECT *
FROM crosstab(
    $$
    with unpivot_population as (
        select
            country,
            unnest(array['1980','1990','2000','2010']) as year,
         unnest(array[year_1980,year_1990,year_2000,year_2010]) as value
        from pivot_population
    )
  SELECT country, year, value
  FROM unpivot_population
  order by 1,2
  $$
) AS ct (
    country text,
    year_1980 text,
    year_1990 text,
    year_2000 text,
    year_2010 text
);















