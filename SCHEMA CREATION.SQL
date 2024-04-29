-- USE ROLE sysadmin;
-- USE WAREHOUSE compute_wh;

CREATE DATABASE IF NOT EXISTS CRICKET;

CREATE OR REPLACE SCHEMA CRICKET.LAND;
CREATE OR REPLACE SCHEMA CRICKET.RAW;
CREATE OR REPLACE SCHEMA CRICKET.CLEAN;
CREATE OR REPLACE SCHEMA CRICKET.CONSUMPTION;

USE SCHEMA CRICKET.LAND;

CREATE OR REPLACE FILE FORMAT CRICKET.LAND.MY_JSON_FORMAT
    type = JSON
    NULL_IF = ('\\n','NULL','')
    STRIP_OUTER_ARRAY = TRUE
    COMMENT = 'JSON FILE FORMAT WITH OUTER STIP ARRAY FLAG TRUE';

CREATE OR REPLACE STAGE CRICKET.LAND.MY_STG;


LIST @CRICKET.LAND.MY_STG;
LIST @CRICKET.LAND.MY_STG;

-- checking if data is loading correctly or not
SELECT
    t.$1:meta::variant as meta,
    t.$1:info::variant as info,
    t.$1:innings::array as innings,
    metadata$filename as file_name,
    metadata$file_row_number int,
    metadata$file_content_key text,
    metadata$file_last_modified stg_modified_ts
from @my_stg/cricket/json/1384403.json(file_format => 'my_json_format') t;
