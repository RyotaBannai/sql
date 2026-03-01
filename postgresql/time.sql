select * from pg_timezone_names;

select
    timeofday(),
    current_time,
    current_timestamp,
    now(),
    localtime,
    localtimestamp
    ;
-- `時間間隔`からも取り出すことができる。
select date_part('day', interval '10 days');

-- 曜日（Thursdayなど）や月（Februaryなど）のテキスト値を取り出す
select to_char(current_timestamp, 'Day');
select to_char(current_timestamp, 'Month');


-- 時刻を減算して時間間隔を計算できる。
select  time '05:00' - interval  '05:00';
-- 時間間隔は乗算ができて、その結果は時間値になる。
select interval '1 second' * 2000 as interval_multiplied;