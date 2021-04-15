set search_path = stop_frisk, public;


                                     -- Using the date_trunc Function to Segment Data by Units of Time --


-- What's the total number of stops that occured each year for the entire period of 2018- March 2021

select date_trunc('year', datetime) as year, count(*)
from stops
group by year
order by year;


-- What's the total number of stops that occured each month for the entire period of 2018- March 2021

select date_trunc('month', datetime) as month, count(*)
from stops
group by month
order by month;



-- What's the total number of stops that took place each week over the entire period of 2018- March 2021

select date_trunc('week', datetime) as week, count(*)
from stops
group by week
order by week;



-- What's the total number of stops that that took place each hour for the entire period of 2018- March 2021

select date_trunc('hour', datetime) as hour, count(*)
from stops
group by hour
order by hour;


-- Brief 1-3 minute exercise using time date_truncate function

-- What's the total number of stops that took place each day in April 2020? Group and the order the result by day.



                                                     -- Other general queries --
                                                     



-- How many stops occured for each race type in January 2019?

SELECT race, COUNT(*) AS num_stops
FROM stops
WHERE datetime < '2019-02-01 00:00:00'
GROUP BY race
ORDER BY (num_stops) desc;

-- More Detailed table with racial description 

SELECT race.description, COUNT(*) AS num_stops,
  RANK () OVER (ORDER BY COUNT(*) DESC) AS race_rank FROM stops
  JOIN race ON race.race = stops.race 
  where datetime < '2019-02-01 00:00:00'
  GROUP BY race.description;

--From this query we see that black indiviudals get stopped by police 4.21 times more than white individuals 

 
                                           -- Time Queries using Time Buckets --
 
 
 -- How many stops took place on May 30th 2019 in five minute intervals?
 
-- Complex query without using timescaledb

SELECT
  EXTRACT(hour from datetime) as hours,
  trunc(EXTRACT(minute from datetime) / 5)*5 AS five_mins,
  COUNT(*)
FROM stops
WHERE datetime between '2019-05-30 00:00:00' and '2019-05-30 23:59:00'
GROUP BY hours, five_mins;

-- Same Query using Timescaledb 

SELECT time_bucket('5 minute', datetime) AS five_min, count(*)
FROM stops
WHERE datetime between '2019-05-30 00:00:00' and '2019-05-30 23:59:00'
GROUP BY five_min
ORDER BY five_min;



                                                       -- Spatial Temporal Queries --


-- Create posgis extension for spatial queries

CREATE EXTENSION postgis;

-- Add geometry column to main stops table

ALTER TABLE stops ADD COLUMN stops_geom geometry(POINT,6347);

-- Insert newly created geometry into geometry column

UPDATE stops SET stops_geom = ST_Transform(ST_SetSRID(ST_MakePoint(lon,lat),4326),6347);


           -- Examining Police Stop and Frisk during BLM protest during George Floyd and Walter Wallace Jr Protests --

-- How many stops occured on May 30th to June 6th originated from within 487.68m (4 city blocks) of City Hall, in 30 minute buckets?

--Before

SELECT time_bucket('30 minutes', datetime) AS thirty_min, COUNT(*) AS num_stops, stops_geom 
FROM stops
WHERE ST_Distance(stops_geom, ST_Transform(ST_SetSRID(ST_MakePoint(-75.16352621534354,39.953425054848935),4326),6347)) < 487.68
AND datetime between '2020-05-23 00:00:00' and '2020-05-29 23:59:00'
GROUP BY thirty_min, stops_geom 
ORDER BY thirty_min;

--During

SELECT time_bucket('30 minutes', datetime) AS thirty_min, COUNT(*) AS num_stops, stops_geom 
FROM stops
WHERE ST_Distance(stops_geom, ST_Transform(ST_SetSRID(ST_MakePoint(-75.16352621534354,39.953425054848935),4326),6347)) < 487.68
AND datetime between '2020-05-30 00:00:00' and '2020-06-06 23:59:00'
GROUP BY thirty_min, stops_geom 
ORDER BY thirty_min;


-- After 

SELECT time_bucket('30 minutes', datetime) AS thirty_min, COUNT(*) AS num_stops, stops_geom 
FROM stops
WHERE ST_Distance(stops_geom, ST_Transform(ST_SetSRID(ST_MakePoint(-75.16352621534354,39.953425054848935),4326),6347)) < 487.68
AND datetime between '2020-06-07 00:00:00' and '2020-06-14 23:59:00'
GROUP BY thirty_min, stops_geom 
ORDER BY thirty_min;


-- How many stops occured on May 30th originated from within 1609.344m (1 mile) of Art Museum, in 30 minute buckets?

-- Week before 

SELECT time_bucket('30 minutes', datetime) AS thirty_min, COUNT(*) AS num_stops, stops_geom 
FROM stops
WHERE ST_Distance(stops_geom, ST_Transform(ST_SetSRID(ST_MakePoint(-75.1810519306871,39.966227529457264),4326),6347)) < 1609.344
AND datetime between '2020-05-23 00:00:00' and '2020-05-29 23:59:00'
GROUP BY thirty_min, stops_geom 
ORDER BY thirty_min;



-- During 

SELECT time_bucket('30 minutes', datetime) AS thirty_min, COUNT(*) AS num_stops, stops_geom 
FROM stops
WHERE ST_Distance(stops_geom, ST_Transform(ST_SetSRID(ST_MakePoint(-75.1810519306871,39.966227529457264),4326),6347)) < 1609.344
AND datetime between '2020-05-30 00:00:00' and '2020-06-06 23:59:00'
GROUP BY thirty_min, stops_geom 
ORDER BY thirty_min;


-- Week after

SELECT time_bucket('30 minutes', datetime) AS thirty_min, COUNT(*) AS num_stops, stops_geom 
FROM stops
WHERE ST_Distance(stops_geom, ST_Transform(ST_SetSRID(ST_MakePoint(-75.1810519306871,39.966227529457264),4326),6347)) < 1609.344
AND datetime between '2020-06-07 00:00:00' and '2020-06-14 23:59:00'
GROUP BY thirty_min, stops_geom 
ORDER BY thirty_min;


-- How many stop occured between oct 26th and Nov 1st 2020 (Walter Wallace Jr. protests)

--Week before

SELECT time_bucket('12 hours', datetime) AS twelvehours, COUNT(*) AS num_stops, stops_geom 
FROM stops
WHERE ST_Distance(stops_geom, ST_Transform(ST_SetSRID(ST_MakePoint(-75.221568086892,39.97514562111139),4326),6347)) < 1609.344
AND datetime between '2020-10-19 00:00:00' and '2020-10-25 23:59:00'
GROUP BY twelvehours, stops_geom 
ORDER BY twelvehours;


-- During

create temp table wwduring as
SELECT time_bucket('12 hours', datetime) AS twelvehours, COUNT(*) AS num_stops, stops_geom 
FROM stops
WHERE ST_Distance(stops_geom, ST_Transform(ST_SetSRID(ST_MakePoint(-75.221568086892,39.97514562111139),4326),6347)) < 1609.344
AND datetime between '2020-10-26 00:00:00' and '2020-10-30 23:59:00'
GROUP BY twelvehours, stops_geom 
ORDER BY twelvehours;


-- Week after

SELECT time_bucket('12 hours', datetime) AS twelvehours, COUNT(*) AS num_stops, stops_geom 
FROM stops
WHERE ST_Distance(stops_geom, ST_Transform(ST_SetSRID(ST_MakePoint(-75.221568086892,39.97514562111139),4326),6347)) < 1609.344
AND datetime between '2020-11-02 00:00:00' and '2020-11-08 23:59:00'
GROUP BY twelvehours, stops_geom 
ORDER BY twelvehours;


 -- Exercise 2: Examine police pedestrian stops that occur every 12 hours at Temple University during the fall, 
 -- spring and summer semesters during the 2018-2019 academic year? 
--  coordinates: 39.98135053704874, -75.15586634603065
--  distance: 1609.34 (.5 Miles)
--  fall: Aug 27 - Dec 19
--  Spring Jan 14 - May 8th
--  Summer May 13 - Aug 11




