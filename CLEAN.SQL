USE DATABASE CRICKET;
USE SCHEMA CRICKET.CLEAN;


-- THE META COLUMN HAS NO REAL DOMAIN VALUE,AND IT JUST CAPTURE THE JSON FILE VERSION,SINCE IT IS AN OBJECT DATA TYPE
-- HERE IS THE SELECT STATEMENT THAT CAN EXTRACT EACH ELEMENT
-- EXTRACT ELEMENT FROM OBJECT DATA TYPE

SELECT 
    meta['data_version']::text as data_version,
    meta['created']::date as created,
    meta['revision']::number as revision
FROM
    CRICKET.RAW.MATCH_RAW_TBL;

--INFO
SELECT 
    info:match_type_number::int as match_type_number,
    info:match_type::text as match_type,
    info:season::text as season,
    info:team_type::text as team_type,
    info:overs::text as overs,
    info:city::text as city,
    info:venue::text as venue
from
    cricket.raw.match_raw_tbl;

--table creation
CREATE OR REPLACE TRANSIENT TABLE CRICKET.CLEAN.MATCH_DETAIL_CLEAN AS
    SELECT
        info:match_type_number::int as match_type_number,
        info:event.name::text as match_event_name,
        case
        when info:event.match_number::text is not null then info:event.match_number
        when info:event.stage::text is not null then info:event.stage
        else
            'NA'
        end as match_stage,
        info:dates[0] as event_date,
        date_part('year',info:dates[0]::date) as event_year,
        date_part('month',info:dates[0]::date) as event_month,
        date_part('day',info:dates[0]::date) as event_day,
        info:match_type::text as match_type,
        info:season::text as season,
        info:team_type::text as team_type,
        info:overs::text as overs,
        info:city::text as city,
        info:venue::text as venue,
        info:gender::text as gender,
        info:teams[0]::text as first_team,
        info:teams[1]::text as second_team,
        case 
            when info:outcome.winner is not null then 'Result Declared'
            when info:outcome.result = 'tie' then 'Tie'
            when info:outcome.result = 'no result' then 'No Result'
            else info:outcome.result
        end as match_result,
        case 
            when info:outcome.winner is not null then info:outcome.winner
            else 'NA'
        end as winner,

        info:toss.winner::text as toss_winner,
        initcap(info:toss.decision::text) as toss_decision,
        --
        stg_file_name,
        stg_file_row_number,
        stg_file_hashkey,
        stg_modified_ts
        from 
            cricket.raw.match_raw_tbl;

SELECT * FROM CRICKET.CLEAN.MATCH_DETAIL_CLEAN LIMIT 5;

--CREATE TABLE FOR TEAM AND PLAYERS
CREATE OR REPLACE TABLE CRICKET.CLEAN.PLAYER_CLEAN_TBL AS
    SELECT
        raw.info:match_type_number::int as match_type_number,
        p.key::text as country,
        team.value::text as player_name,
        stg_file_name,
        stg_file_row_number,
        stg_file_hashkey,
        stg_modified_ts
    from cricket.raw.match_raw_tbl raw,
    lateral flatten(input=>raw.info:players) p,
    lateral flatten(input=>p.value) team;

select * from CRICKET.CLEAN.PLAYER_CLEAN_TBL limit 5

--add not null and fk relationships
ALTER TABLE CRICKET.CLEAN.PLAYER_CLEAN_TBL
MODIFY COLUMN match_type_number SET NOT NULL;

ALTER TABLE CRICKET.CLEAN.PLAYER_CLEAN_TBL
MODIFY COLUMN player_name SET NOT NULL;

ALTER TABLE CRICKET.CLEAN.PLAYER_CLEAN_TBL
MODIFY COLUMN country SET NOT NULL;

ALTER TABLE CRICKET.CLEAN.MATCH_DETAIL_CLEAN
ADD CONSTRAINT PK_MATCH_TYPE_NUMBER PRIMARY KEY(match_type_number);

ALTER TABLE CRICKET.CLEAN.PLAYER_CLEAN_TBL
ADD CONSTRAINT FK_MATCH_ID
FOREIGN KEY (match_type_number)
REFERENCES CRICKET.CLEAN.MATCH_DETAIL_CLEAN (match_type_number);

DESC TABLE CRICKET.CLEAN.PLAYER_CLEAN_TBL;
SELECT GET_DDL('TABLE','CRICKET.CLEAN.PLAYER_CLEAN_TBL')



        