DROP table if exists ufo;
CREATE table ufo
(
sighting_report varchar(1000)
,description text
)
;
-- change localpath to the directory where you saved the ufo .csv files
COPY ufo FROM '/Users/ryotabannai/dev/github.com/RyotaBannai/sql/postgresql/data/ufo/ufo1.csv' DELIMITER ',' CSV HEADER;
COPY ufo FROM '/Users/ryotabannai/dev/github.com/RyotaBannai/sql/postgresql/data/ufo/ufo2.csv' DELIMITER ',' CSV HEADER;
COPY ufo FROM '/Users/ryotabannai/dev/github.com/RyotaBannai/sql/postgresql/data/ufo/ufo3.csv' DELIMITER ',' CSV HEADER;
COPY ufo FROM '/Users/ryotabannai/dev/github.com/RyotaBannai/sql/postgresql/data/ufo/ufo4.csv' DELIMITER ',' CSV HEADER;
COPY ufo FROM '/Users/ryotabannai/dev/github.com/RyotaBannai/sql/postgresql/data/ufo/ufo5.csv' DELIMITER ',' CSV HEADER;


-- select * from ufo;
select right(left(sighting_report,25),14) occurred
from ufo;