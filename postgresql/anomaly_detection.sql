DROP table if exists public.earthquakes;
CREATE table public.earthquakes
(
time timestamp
,latitude decimal
,longitude decimal
,depth decimal
,mag decimal
,magType varchar
,nst decimal
,gap decimal
,dmin decimal
,rms decimal
,net varchar
,id varchar
,updated timestamp
,place varchar
,type varchar
,horizontalError decimal
,depthError decimal
,magError decimal
,magNst decimal
,status varchar
,locationSource varchar
,magSource varchar
)
;

-- PL/pgSQL の DO + EXECUTE
DO $$
DECLARE
    num int;
    path text;
BEGIN
    FOR num IN 1..15 LOOP
        path := '/Users/ryotabannai/dev/github.com/RyotaBannai/sql/postgresql/data/earthquake/earthquakes'
                || num
                || '.csv';
        EXECUTE format(
            'COPY public.earthquakes FROM %L DELIMITER '','' CSV HEADER',
            path
        );
    END LOOP;
END $$;

select mag,
       count(id) as count,
       round(count(id) * 100.0 / sum(count(id)) over (), 8) as pct_earthquakes
from earthquakes
where mag is not null
group by 1
order by 1 desc
;