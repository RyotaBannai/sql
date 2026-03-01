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