CREATE TABLE flights_import (
    YEAR INT,
    MONTH INT,
    DAY INT,
    DAY_OF_WEEK INT,
    AIRLINE TEXT,
    FLIGHT_NUMBER INT,
    TAIL_NUMBER TEXT,
    ORIGIN_AIRPORT TEXT,
    DESTINATION_AIRPORT TEXT,
    SCHEDULED_DEPARTURE INT,
    DEPARTURE_TIME INT,
    DEPARTURE_DELAY INT,
    TAXI_OUT INT,
    WHEELS_OFF INT,
    SCHEDULED_TIME INT,
    ELAPSED_TIME INT,
    AIR_TIME INT,
    DISTANCE INT,
    WHEELS_ON INT,
    TAXI_IN INT,
    SCHEDULED_ARRIVAL INT,
    ARRIVAL_TIME INT,
    ARRIVAL_DELAY INT,
    DIVERTED INT,
    CANCELLED INT,
    CANCELLATION_REASON TEXT,
    AIR_SYSTEM_DELAY INT,
    SECURITY_DELAY INT,
    AIRLINE_DELAY INT,
    LATE_AIRCRAFT_DELAY INT,
    WEATHER_DELAY INT
);

COPY flights_import
FROM 'C:/Users/Adity/Desktop/Aditya/Fly Emirates/Dataset/flights.csv'
DELIMITER ','
CSV HEADER;

CREATE TABLE airports (
    iata_code VARCHAR(10) PRIMARY KEY,
    airport VARCHAR(255),
    city VARCHAR(100),
    state VARCHAR(50),
    country VARCHAR(50),
    latitude DECIMAL(9,6),
    longitude DECIMAL(9,6)
);

CREATE TABLE airlines (
	iata_code VARCHAR(10) PRIMARY KEY,	
	airline VARCHAR(100)
);


COPY airports
FROM 'C:/Users/Adity/Desktop/Aditya/Fly Emirates/Dataset/airports.csv'
DELIMITER ','
CSV HEADER;
COPY airlines
FROM 'C:/Users/Adity/Desktop/Aditya/Fly Emirates/Dataset/airlines.csv'
DELIMITER ','
CSV HEADER;



-- Creating Custom Columns
-- Date Column
ALTER TABLE flights_import
ADD COLUMN date DATE;

UPDATE flights_import
SET date = MAKE_DATE(year, month, day);


SELECT * FROM flights_import
LIMIT 1000;

-- KPI's
-- total_flights
SELECT COUNT(*) AS total_flights
FROM flights_import;

-- total_cancelled_flights
SELECT COUNT(*) AS total_cancelled_flights
FROM flights_import
WHERE cancelled = 1;

-- total_distance
SELECT SUM(distance) AS total_distance
FROM flights_import;

-- total_air_time
SELECT SUM(air_time) AS total_air_time
FROM flights_import;

-- Avg Arrival Delay 
SELECT
    AVG(arrival_delay) AS avg_arrival_delay
FROM flights_import
WHERE arrival_delay IS NOT NULL;

-- Avg Departure Delay
SELECT
    AVG(departure_delay) AS avg_departure_delay
FROM flights_import
WHERE departure_delay IS NOT NULL;

-- Total Flights Diverted
SELECT
    COUNT(*) AS total_diverted
FROM flights_import
WHERE diverted = 1;

-- Flights by Airline and Month
SELECT
    airline,
    month,
    COUNT(*) AS total_flights
FROM flights_import
GROUP BY airline, month
ORDER BY month;

-- Flights by Airport
SELECT
    destination_airport AS airport,
    COUNT(*) AS total_flights
FROM flights_import
GROUP BY destination_airport
ORDER BY total_flights DESC;

-- Departure Delay Breakdown
SELECT
    SUM(airline_delay) AS airline_delay,
    SUM(weather_delay) AS weather_delay,
    SUM(nas_delay) AS nas_delay,
    SUM(security_delay) AS security_delay,
    SUM(late_aircraft_delay) AS late_aircraft_delay
FROM flights_import;

-- Arrival Delay Breakdown
SELECT
    SUM(arrival_delay) AS total_arrival_delay,
    SUM(airline_delay) AS airline_delay,
    SUM(weather_delay) AS weather_delay,
    SUM(nas_delay) AS nas_delay,
    SUM(security_delay) AS security_delay
FROM flights_import
WHERE arrival_delay IS NOT NULL;


-- Arrival Delay in each State
SELECT
    destination_airport,
    SUM(arrival_delay) AS total_arrival_delay
FROM flights_import
GROUP BY destination_airport
ORDER BY total_arrival_delay DESC;

-- Cancellation Breakdown according to distance travelled
SELECT
    CASE
        WHEN distance <= 500 THEN '0-500'
        WHEN distance <= 1000 THEN '500-1000'
        WHEN distance <= 2000 THEN '1000-2000'
        WHEN distance <= 3000 THEN '2000-3000'
        ELSE '3000+'
    END AS distance_group,
    COUNT(*) AS total_flights,
    SUM(cancelled) AS cancelled_flights,
    ROUND(SUM(cancelled)::numeric / COUNT(*) * 100,2) AS cancellation_rate
FROM flights_import
GROUP BY distance_group
ORDER BY distance_group;

-- Number of Diverted flights by Departure Delay Groups
SELECT
    CASE
        WHEN departure_delay <= 15 THEN '0-15'
        WHEN departure_delay <= 30 THEN '16-30'
        WHEN departure_delay <= 45 THEN '31-45'
        WHEN departure_delay <= 60 THEN '46-60'
        WHEN departure_delay <= 75 THEN '61-75'
        WHEN departure_delay <= 90 THEN '76-90'
        WHEN departure_delay <= 105 THEN '91-105'
        WHEN departure_delay <= 120 THEN '106-120'
        ELSE '120+'
    END AS dd_group,
    COUNT(*) AS total_flights,
    SUM(diverted) AS diverted_flights,
    ROUND(SUM(diverted)::numeric / COUNT(*) * 100,2) AS diversion_rate
FROM flights_import
WHERE departure_delay IS NOT NULL
GROUP BY dd_group
ORDER BY dd_group;

-- Arrival Delay by State 
SELECT
    destination_state,
    SUM(arrival_delay) AS total_arrival_delay
FROM flights_import
GROUP BY destination_state
ORDER BY total_arrival_delay DESC;

-- Diverted Flights by Month
SELECT
    month,
    COUNT(*) AS diverted_flights
FROM flights_import
WHERE diverted = 1
GROUP BY month
ORDER BY month;

-- Cancellation by Month
SELECT
    origin_state,
    COUNT(*) AS cancelled_flights
FROM flights_import
WHERE cancelled = 1
GROUP BY origin_state
ORDER BY cancelled_flights DESC;

-- Cancellation by Reasons
SELECT
    cancellation_reason,
    COUNT(*) AS total_cancellations
FROM flights_import
WHERE cancelled = 1
GROUP BY cancellation_reason
ORDER BY total_cancellations DESC;

-- Cancellation by Airlines
SELECT
    airline,
    COUNT(*) AS total_cancellations
FROM flights_import
WHERE cancelled = 1
GROUP BY airline
ORDER BY total_cancellations DESC;

-- Cancellation by Month
SELECT
    month,
    COUNT(*) AS total_cancellations
FROM flights_import
WHERE cancelled = 1
GROUP BY month
ORDER BY month;

-- Cancellation by Day of the Week
SELECT
    day_of_week,
    COUNT(*) AS total_cancellations
FROM flights_import
WHERE cancelled = 1
GROUP BY day_of_week
ORDER BY day_of_week;

-- Cancelled Flights by Airport
SELECT
    origin_airport,
    COUNT(*) AS cancelled_flights
FROM flights_import
WHERE cancelled = 1
GROUP BY origin_airport
ORDER BY cancelled_flights DESC;

-- Diverted Flights by Airport
SELECT
    origin_airport,
    COUNT(*) AS diverted_flights
FROM flights_import
WHERE diverted = 1
GROUP BY origin_airport
ORDER BY diverted_flights DESC;

-- Security Delay by Airport
SELECT
    origin_airport,
    SUM(security_delay) AS total_security_delay
FROM flights_import
GROUP BY origin_airport
ORDER BY total_security_delay DESC;

-- Distance Vs Cancellation & Diversion
SELECT
    distance,
    SUM(cancelled) AS total_cancelled,
    SUM(diverted) AS total_diverted
FROM flights_import
GROUP BY distance
ORDER BY distance;



-- Corellations
SELECT 
    CORR(departure_delay, arrival_delay) AS dep_arr_delay_corr
FROM flights_import
WHERE departure_delay IS NOT NULL
AND arrival_delay IS NOT NULL;

SELECT
    CORR(airline_delay, arrival_delay) AS airline_arrival_corr
FROM flights_import
WHERE airline_delay IS NOT NULL
AND arrival_delay IS NOT NULL;

SELECT
    airline,
    CORR(arrival_delay, departure_delay) AS delay_correlation
FROM flights_import
WHERE arrival_delay IS NOT NULL
AND departure_delay IS NOT NULL
GROUP BY airline;

SELECT
    origin_airport,
    CORR(arrival_delay, departure_delay) AS delay_correlation
FROM flights_import
WHERE arrival_delay IS NOT NULL
AND departure_delay IS NOT NULL
GROUP BY origin_airport;
