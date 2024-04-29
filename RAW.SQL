USE DATABASE CRICKET;
USE SCHEMA CRICKET.RAW;

CREATE OR REPLACE TRANSIENT TABLE CRICKET.RAW.MATCH_RAW_TBL(
        META OBJECT NOT NULL,
        INFO VARIANT NOT NULL,
        INNINGS ARRAY NOT NULL,
        STG_FILE_NAME TEXT NOT NULL,
        STG_FILE_ROW_NUMBER INT NOT NULL,
        STG_FILE_HASHKEY TEXT NOT NULL,
        STG_MODIFIED_TS TIMESTAMP NOT NULL
)
COMMENT = 'THIS IS RAW TABLE TO STORE ALL THE JSON DATA FILE WITH ROOT 
ELEMENTS EXTRACTED';

LIST @CRICKET.LAND.MY_STG/CRICKET

copy into cricket.raw.match_raw_tbl from (
    select 
        t.$1:meta::object as meta,
        t.$1:info::variant as info,
        t.$1:innings::array as innings,
        metadata$filename,
        metadata$file_row_number,
        metadata$file_content_key,
        metadata$file_last_modified
    from @cricket.land.my_stg/cricket/json (file_format => 'cricket.land.my_json_format') t
)
on_error = continue; 


select count(*) from cricket.raw.match_raw_tbl

select * from cricket.raw.match_raw_tbl limit 5
