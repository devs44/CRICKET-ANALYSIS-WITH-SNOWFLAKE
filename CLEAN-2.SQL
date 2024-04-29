
CREATE OR REPLACE TABLE DELIVERY_CLEAN_TBL AS
    SELECT
        rcm.info:match_type_number::int as match_type_number,
        i.value:team::text as team_name,
        o.value:over::int+1 as over,
        d.value:bowler::text as bowler,
        d.value:batter::text as batter,
        d.value:non_striker::text as non_striker,
        d.value:runs.batter::text as runs,
        d.value:runs.total::text as total,
        e.key::text as extra_type,
        e.value::number  as extra_runs,
        w.value:player_out::text as player_out,
        w.value:kind::text as player_out_kind,
        w.value:fielders::variant as player_out_fielders,
        rcm.stg_file_name,
        rcm.stg_file_row_number,
        rcm.stg_file_hashkey,
        rcm.stg_modified_ts
    FROM
        CRICKET.RAW.MATCH_RAW_TBL rcm,
        LATERAL FLATTEN( input => rcm.innings) i,
        LATERAL FLATTEN( input => i.value:overs) o,
        LATERAL FLATTEN( input => o.value:deliveries) d,
        LATERAL FLATTEN( input => d.value:extras, outer=> True) e,
        LATERAL FLATTEN( input => d.value:wickets, outer => True) w;

SELECT * FROM DELIVERY_CLEAN_TBL;

alter table cricket.clean.delivery_clean_tbl
modify column match_type_number set not null;

alter table cricket.clean.delivery_clean_tbl
modify column team_name set not null;

alter table cricket.clean.delivery_clean_tbl
modify column over set not null;

alter table cricket.clean.delivery_clean_tbl
modify column bowler set not null;

alter table cricket.clean.delivery_clean_tbl
modify column batter set not null;

alter table cricket.clean.delivery_clean_tbl
modify column non_striker set not null;

-- fk relationship
alter table cricket.clean.delivery_clean_tbl
add constraint fk_delivery_match_id
foreign key (match_type_number)
references cricket.clean.match_detail_clean (match_type_number);

SELECT GET_DDL('TABLE','DELIVERY_CLEAN_TBL');