create database superstore_us_new;

use superstore_us_new;

create table orders(
		row_id int primary key,
        order_priority char(20),
        customer_id int not null,
        customer_name char(30),
        ship_mode char(30),
        customer_segment char(30),
        product_category char(30),
        product_sub_category varchar(70),
        product_container varchar(100),
		product_name varchar(200),
        product_base_margin decimal(7,2),
        country char(30),
        region char(15),
        state_province char(30),
        city char(30),
        order_date date,
        ship_date date,
		discount decimal(7,2),
        unit_price decimal(7,2),
        shipping_cost decimal(7,2),
        profit decimal(7,2),
        quantity_ordered_new int,
        sales decimal(7,2),
        order_id int not null
	);
    
   select count(row_id) from orders;
    
    create table o_return( 
	order_id int primary key, 
    Order_status char(20)
);
    
    create table users( 
	region char(15) unique,
    manager char(30)
);

-- TO CHECK WHAT IS THE MOST USED SHIP MODE AND HOW MANY TIMES IT HAS BEEN USED  
SELECT  
    SHIP_MODE,  
    COUNT(SHIP_MODE)  
FROM ORDERS  
GROUP BY SHIP_MODE;  

-- TO CHECK THE MOST USED CUSTOMER SEGMENT ORDERS COMING FROM  
SELECT  
    CUSTOMER_SEGMENT,  
    COUNT(CUSTOMER_SEGMENT)  
FROM ORDERS  
GROUP BY CUSTOMER_SEGMENT  
ORDER BY COUNT(CUSTOMER_SEGMENT) ASC;  

-- MOST TO LEAST SOLD PRODUCT/SUB-PRODUCT CATEGORY ORDERED BY REGION  
SELECT  
    PRODUCT_CATEGORY AS PRODUCT,  
    COUNT(PRODUCT_CATEGORY) AS TOTAL_SOLD,  
    PRODUCT_SUB_CATEGORY AS SUB_CATEGORY,  
    REGION  
FROM ORDERS  
GROUP BY PRODUCT, REGION, SUB_CATEGORY  
ORDER BY REGION, TOTAL_SOLD DESC;

-- MOST AND LEAST SALES DONE BASED ON MONTH, STATE, REGION, PRODUCTS, AND SUB-PRODUCT  
WITH MAX_SALES AS (SELECT 
	REGION,
    STATE_PROVINCE,
	PRODUCT_CATEGORY,
    PRODUCT_SUB_CATEGORY,
    SUM(SALES) AS T_SALES,
    RANK() OVER(PARTITION BY PRODUCT_CATEGORY ORDER BY SUM(SALES) DESC) AS MAXIMUM
FROM ORDERS
GROUP BY 1,2,3,4 ),

LEAST_SALES AS (SELECT 
	REGION,
    STATE_PROVINCE,
	PRODUCT_CATEGORY,
    PRODUCT_SUB_CATEGORY,
    SUM(SALES) AS T_SALES,
    RANK() OVER(PARTITION BY PRODUCT_CATEGORY ORDER BY SUM(SALES)) AS MINIMUM
FROM ORDERS
GROUP BY 1,2,3,4)

SELECT * 
FROM MAX_SALES AS M
WHERE MAXIMUM = 1
UNION ALL
SELECT *
FROM 
LEAST_SALES AS L
WHERE MINIMUM = 1;



-- MONTH-WISE SALES DISTRIBUTION  
SELECT  
    MONTH(SALES) AS MONTHLY,  
    SUM(SALES) AS TOTAL  
FROM ORDERS  
GROUP BY MONTHLY  
ORDER BY MONTHLY;  

-- MOST AND LEAST ORDERING CUSTOMERS WITH QUANTITY, SALES, AND PROFIT  
SELECT  
    CUSTOMER_ID,  
    CUSTOMER_NAME,  
    SUM(QUANTITY_ORDERED_NEW) AS QUANTITY,  
    SUM(SALES) AS T_SALES,  
    SUM(PROFIT) AS T_PROFIT  
FROM ORDERS  
GROUP BY CUSTOMER_NAME, CUSTOMER_ID  
ORDER BY SUM(SALES) DESC;  

-- PERIOD WITH THE MOST RETURNED ORDERS REGION-WISE  
SELECT  
    ORDERS.ORDER_ID,  
    O_RETURN.ORDER_ID,  
    ORDERS.REGION,  
    MONTH(ORDERS.ORDER_DATE) AS MONTHLY  
FROM ORDERS  
NATURAL JOIN O_RETURN  
ORDER BY REGION, MONTHLY ASC;

-- ORDER PRIORITY BASED ON REGION AND STATE  
SELECT  
    REGION,  
    STATE_PROVINCE AS STATE, 
    ORDER_PRIORITY,
    COUNT(*) AS counts 
FROM ORDERS   
GROUP BY STATE_PROVINCE, REGION, ORDER_PRIORITY
ORDER BY REGION, STATE, COUNTS DESC;

-- DISTINCT ORDER PRIORITIES  
SELECT ORDER_PRIORITY, COUNT(*) 
FROM ORDERS
GROUP BY ORDER_PRIORITY;  

 

