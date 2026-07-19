COPY main
FROM 'C:/Users/Adity/Desktop/Aditya/Ola Cabs/Book1(csv).csv'
DELIMITER ','
CSV HEADER
NULL 'null';

ALTER TABLE main 
DROP COLUMN "vehicle images";

SELECT * FROM main;


-- All Successful Orders
SELECT 
	*
FROM main
WHERE booking_status = 'Success';

-- Avg ride_distance for each Vehical type
SELECT
	vehical_type,
	ROUND(avg(ride_distance), 2) AS avg_ride_distance
FROM main
GROUP BY 1
ORDER BY 2 DESC;

-- Total Canceled Rides by Customer
SELECT 
	COUNT(*) AS total_canceled_rides
FROM main
WHERE booking_status = 'Canceled by Customer';

-- top 5 customers who booked the highest number of rides
SELECT
	customer_id,
	count(*) AS total_number_of_rides
FROM main
GROUP BY 1
ORDER BY 2 DESC
LIMIT 5;

-- Number of rides cancelled by drivers due to personal & car-related issues.
SELECT
	COUNT(*) AS total_rides
FROM main
WHERE canceled_rides_by_driver = 'Personal & Car related issue';


-- Maximum and Minimum driver ratings for Prime Sedan bookings
SELECT
	MAX(driver_ratings) AS max_driver_rating,
	MIN(driver_ratings) AS min_driver_rating
FROM main
WHERE vehical_type = 'Prime Sedan';

-- Rides where payment was made using UPI
SELECT
	*
FROM main
WHERE payment_method = 'UPI';

-- Average Customer Rating per Vehicle Type.
SELECT
	vehical_type,
	ROUND(AVG(customer_rating), 2) AS avg_customer_rating
FROM main
GROUP BY 1
ORDER BY 2 DESC;

-- Total Booking Value of rides completed successfully.
SELECT
	SUM(booking_value) AS total_booking_value
FROM main
WHERE booking_status = 'Success';

-- All Incomplete Rides along with the Reason.  
SELECT
	*
FROM main
WHERE incomplete_rides_reason IS NOT NULL;

SELECT * FROM main;