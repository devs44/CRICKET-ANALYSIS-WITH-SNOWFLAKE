USE SCHEMA CRICKET.CONSUMPTION;

CREATE OR REPLACE TABLE DATE_DIM(
    date_id int primary key autoincrement,
    full_dt date,
    day int,
    month int,
    year int,
    quarter int,
    dayofweek int,
    dayofmonth int,
    dayofyear int,
    dayofweekname varchar(3), --to store day names(eg,"Mon")
    isweekend boolean   --to indicate if its a weekend(true/false sat/sun both falls under weekend)
);

CREATE  OR REPLACE TABLE REFEREE_DIM(
    referee_id int primary key autoincrement,
    referee_name text not null,
    referee_type text not null
);

CREATE OR REPLACE TABLE TEAM_DIM(
    team_id int primary key autoincrement,
    team_name text not null
);

CREATE OR REPLACE TABLE PLAYER_DIM(
    player_id INT PRIMARY KEY autoincrement,
    team_id int not null,
    player_name text not null
);

ALTER TABLE CRICKET.CONSUMPTION.PLAYER_DIM
ADD CONSTRAINT fk_team_player_id
foreign key(team_id)
references CRICKET.CONSUMPTION.TEAM_DIM(team_id);

CREATE OR REPLACE TABLE VENUE_DIM(
    venue_id int primary key autoincrement,
    venue_name text not null,
    city text not null,
    state text,
    country text,
    continent text,
    end_Names text,
    capacity number,
    pitch text,
    flood_light boolean,
    established_dt date,
    playing_area text,
    other_sports text,
    curator text,
    lattitude number(10,6),
    longitude number(10,6)
);

CREATE OR REPLACE TABLE MATCH_TYPE_DIM(
    match_type_id int primary key autoincrement,
    match_type text not null
);

CREATE or replace TABLE match_fact (
    match_id INT PRIMARY KEY,
    date_id INT NOT NULL,
    referee_id INT NOT NULL,
    team_a_id INT NOT NULL,
    team_b_id INT NOT NULL,
    match_type_id INT NOT NULL,
    venue_id INT NOT NULL,
    total_overs number(3),
    balls_per_over number(1),

    overs_played_by_team_a number(2),
    bowls_played_by_team_a number(3),
    extra_bowls_played_by_team_a number(3),
    extra_runs_scored_by_team_a number(3),
    fours_by_team_a number(3),
    sixes_by_team_a number(3),
    total_score_by_team_a number(3),
    wicket_lost_by_team_a number(2),

    overs_played_by_team_b number(2),
    bowls_played_by_team_b number(3),
    extra_bowls_played_by_team_b number(3),
    extra_runs_scored_by_team_b number(3),
    fours_by_team_b number(3),
    sixes_by_team_b number(3),
    total_score_by_team_b number(3),
    wicket_lost_by_team_b number(2),

    toss_winner_team_id int not null, 
    toss_decision text not null, 
    match_result text not null, 
    winner_team_id int not null,

    CONSTRAINT fk_date FOREIGN KEY (date_id) REFERENCES date_dim (date_id),
    CONSTRAINT fk_referee FOREIGN KEY (referee_id) REFERENCES referee_dim (referee_id),
    CONSTRAINT fk_team1 FOREIGN KEY (team_a_id) REFERENCES team_dim (team_id),
    CONSTRAINT fk_team2 FOREIGN KEY (team_b_id) REFERENCES team_dim (team_id),
    CONSTRAINT fk_match_type FOREIGN KEY (match_type_id) REFERENCES match_type_dim (match_type_id),
    CONSTRAINT fk_venue FOREIGN KEY (venue_id) REFERENCES venue_dim (venue_id),

    CONSTRAINT fk_toss_winner_team FOREIGN KEY (toss_winner_team_id) REFERENCES team_dim (team_id),
    CONSTRAINT fk_winner_team FOREIGN KEY (winner_team_id) REFERENCES team_dim (team_id)
);


--populate team_dim
INSERT INTO CRICKET.CONSUMPTION.TEAM_DIM(team_name)
SELECT DISTINCT team_name FROM (
    SELECT first_team as team_name from CRICKET.CLEAN.MATCH_DETAIL_CLEAN
    UNION ALL
    SELECT second_team as team_name from CRICKET.CLEAN.MATCH_DETAIL_CLEAN
)
order by team_name;

SELECT * FROM CRICKET.CONSUMPTION.TEAM_DIM

--TEAM PLAYER
INSERT INTO CRICKET.CONSUMPTION.PLAYER_DIM(team_id, player_name)
SELECT 
    T.team_id,
    P.player_name
FROM
    CRICKET.CLEAN.PLAYER_CLEAN_TBL P 
    JOIN
    CRICKET.CONSUMPTION.TEAM_DIM T
    ON 
    P.COUNTRY = T.TEAM_NAME
GROUP BY
    T.team_id,
    P.player_name;

SELECT * FROM CRICKET.CONSUMPTION.PLAYER_DIM

--VENUE DIM
INSERT INTO CRICKET.CONSUMPTION.VENUE_DIM(venue_name,city)
SELECT
    venue,city 
    FROM (
        SELECT 
            venue,
            case when city is null then 'NA'
            else city
            end as city
        FROM
            cricket.clean.match_detail_clean
    )
GROUP BY 
    venue,
    city;

SELECT * FROM CRICKET.CONSUMPTION.VENUE_DIM

--MATCH TYPE DIM
INSERT INTO CRICKET.CONSUMPTION.MATCH_TYPE_DIM(match_type)
SELECT match_type 
FROM
CRICKET.CLEAN.MATCH_DETAIL_CLEAN 
GROUP BY MATCH_TYPE;


--DATE DIM
INSERT INTO cricket.consumption.date_dim (Date_ID, Full_Dt, Day, Month, Year, Quarter, DayOfWeek, DayOfMonth, DayOfYear, DayOfWeekName, IsWeekend)
SELECT
    ROW_NUMBER() OVER (ORDER BY Date) AS DateID,
    Date AS FullDate,
    EXTRACT(DAY FROM Date) AS Day,
    EXTRACT(MONTH FROM Date) AS Month,
    EXTRACT(YEAR FROM Date) AS Year,
    CASE WHEN EXTRACT(QUARTER FROM Date) IN (1, 2, 3, 4) THEN EXTRACT(QUARTER FROM Date) END AS Quarter,
    DAYOFWEEKISO(Date) AS DayOfWeek,
    EXTRACT(DAY FROM Date) AS DayOfMonth,
    DAYOFYEAR(Date) AS DayOfYear,
    DAYNAME(Date) AS DayOfWeekName,
    CASE When DAYNAME(Date) IN ('Sat', 'Sun') THEN 1 ELSE 0 END AS IsWeekend
FROM cricket.consumption.date_range01;

