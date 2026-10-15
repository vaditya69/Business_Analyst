-- Aggregated Transactions
CREATE TABLE aggregated_transaction (
    states VARCHAR(100),
    year INTEGER,
    quarter INTEGER,
    trans_type VARCHAR(100),
    trans_counts BIGINT,
    amount NUMERIC(18,3)
);

COPY aggregated_transaction
FROM 'C:\Users\Adity\Desktop\Aditya\Projects\Phone Pe\Dataset\aggregated_transaction.csv'
WITH (
    FORMAT CSV,
    HEADER TRUE,
    DELIMITER ','
);


-- Aggregated Users
CREATE TABLE aggregated_user (
    id INTEGER,
    states VARCHAR(100),
    year INTEGER,
    quarter INTEGER,
    brand VARCHAR(100),
    user_counts BIGINT,
    percentage NUMERIC(18,10)
);

COPY aggregated_user
FROM 'C:\Users\Adity\Desktop\Aditya\Projects\Phone Pe\Dataset\aggregated_user.csv'
WITH (
    FORMAT CSV,
    HEADER TRUE,
    DELIMITER ','
);

-- Map Transactions
CREATE TABLE map_transaction (
    id INTEGER,
    states VARCHAR(100),
    year INTEGER,
    quarter INTEGER,
    district VARCHAR(150),
    trans_counts BIGINT,
    amount NUMERIC(18,3)
);

COPY map_transaction
FROM 'C:\Users\Adity\Desktop\Aditya\Projects\Phone Pe\Dataset\map_transaction.csv'
WITH (
    FORMAT CSV,
    HEADER TRUE,
    DELIMITER ','
);

-- Map Users
CREATE TABLE map_user (
    id INTEGER,
    states VARCHAR(100),
    year INTEGER,
    quarter INTEGER,
    district VARCHAR(150),
    registered_user_counts BIGINT
);

COPY map_user
FROM 'C:\Users\Adity\Desktop\Aditya\Projects\Phone Pe\Dataset\map_user.csv'
WITH (
    FORMAT CSV,
    HEADER TRUE,
    DELIMITER ','
);

-- Top Transactions
CREATE TABLE top_transaction (
    id INTEGER,
    states VARCHAR(100),
    year INTEGER,
    quarter INTEGER,
    district VARCHAR(150),
    trans_counts BIGINT,
    amount NUMERIC(18,3)
);

COPY top_transaction
FROM 'C:\Users\Adity\Desktop\Aditya\Projects\Phone Pe\Dataset\top_transaction.csv'
WITH (
    FORMAT CSV,
    HEADER TRUE,
    DELIMITER ','
);

-- Top Users
CREATE TABLE top_user (
    id INTEGER,
    states VARCHAR(100),
    year INTEGER,
    quarter INTEGER,
    district VARCHAR(150),
    registered_user_counts BIGINT
);

COPY top_user
FROM 'C:\Users\Adity\Desktop\Aditya\Projects\Phone Pe\Dataset\top_user.csv'
WITH (
    FORMAT CSV,
    HEADER TRUE,
    DELIMITER ','
);


--- Checking
SELECT * FROM aggregated_transaction;
SELECT * FROM aggregated_user;
SELECT * FROM map_transaction;
SELECT * FROM map_user;
SELECT * FROM top_transaction;
SELECT * FROM top_user;


-- Checking Relation between Map and Aggregated Transaction
SELECT
	'mt',
	SUM(amount),
	SUM(trans_counts)
FROM map_transaction
UNION
SELECT
	'at',
	SUM(amount),
	SUM(trans_counts)
FROM aggregated_transaction;


-- Cheking User Counts between 2 Tables 
SELECT
	'mt',
	SUM(registered_user_counts)
FROM map_user
UNION
SELECT
	'at',
	SUM(user_counts)
FROM aggregated_user;

-- YoY Amount % Change
WITH year_grouping AS (
    SELECT
        year,
        SUM(amount) AS amount
    FROM map_transaction
    GROUP BY year
    ORDER BY year
), 
happy AS(
SELECT 
    *,
	LAG(amount) OVER (ORDER BY year) AS previous_amount
FROM year_grouping
)
SELECT
	Year,
	amount,
	ROUND(((amount - previous_amount) / previous_amount) * 100, 2)
FROM happy;

-- Top Transactions and User Table
SELECT * FROM top_transaction;
SELECT * FROM top_user;

-- Total Amount, Users and Transactions by States Rankings
WITH aggregating as (
	SELECT
		top_transaction.states AS states,
		SUM(registered_user_counts) AS user_counts,
		SUM(trans_counts) AS transaction_counts,
		ROUND(SUM(amount), 2) AS total_amount
	FROM top_transaction
	LEFT JOIN top_user
		USING(states, district, year, quarter)
	GROUP BY 1
)
SELECT
	states,
	user_counts,
	DENSE_RANK() OVER(ORDER BY user_counts DESC) AS user_ranking,
	transaction_counts,
	DENSE_RANK() OVER(ORDER BY transaction_counts DESC) AS transaction_ranking,
	total_amount,
	DENSE_RANK() OVER(ORDER BY total_amount DESC) AS amount_ranking
FROM aggregating
ORDER BY states;

-- Total Amount, Transactions and Users by States and District
WITH groupings AS (
    SELECT
        tt.states AS states,
        tt.district AS district,
        SUM(registered_user_counts) AS user_counts,
        SUM(trans_counts) AS transaction_counts,
        ROUND(SUM(amount), 2) AS total_amount
    FROM top_transaction tt
    LEFT JOIN top_user tu
        USING (states, district, year, quarter)
    GROUP BY CUBE (tt.states, tt.district)
)
SELECT
    states,
    district,
    user_counts,
    CASE
        WHEN district IS NOT NULL THEN
            ROUND(
                user_counts * 100.0 /
                NULLIF(
                    MAX(CASE WHEN district IS NULL THEN user_counts END)
                    OVER (PARTITION BY states), 0
                ), 2
            )
        ELSE NULL
    END AS user_contribution_pct,
    transaction_counts,
    CASE
        WHEN district IS NOT NULL THEN
            ROUND(
                transaction_counts * 100.0 /
                NULLIF(
                    MAX(CASE WHEN district IS NULL THEN transaction_counts END)
                    OVER (PARTITION BY states), 0
                ), 2
            )
        ELSE NULL
    END AS transaction_contribution_pct,
    total_amount,
    CASE
        WHEN district IS NOT NULL THEN
            ROUND(
                total_amount * 100.0 /
                NULLIF(
                    MAX(CASE WHEN district IS NULL THEN total_amount END)
                    OVER (PARTITION BY states), 0
                ), 2
            )
        ELSE NULL
    END AS amount_contribution_pct
FROM groupings
ORDER BY states, total_amount DESC NULLS LAST;

-- Map User and Transactions Table
SELECT * FROM map_transaction;
SELECT * FROM map_user;

-- PIVOT Table for analysing Amount, Transactions and Users By States, District, Year, Quarter
CREATE EXTENSION IF NOT EXISTS tablefunc;

WITH aggregation_amount AS (
    SELECT *
    FROM CROSSTAB(
        $$
        SELECT
            states || ' - ' || district AS locations,
            year || '- Q' || quarter AS periods,
            SUM(amount)::NUMERIC AS total_amount
        FROM map_transaction
        GROUP BY states, district, year, quarter
        ORDER BY 1, 2
        $$,
        $$
        VALUES
            ('2018- Q1'), ('2018- Q2'), ('2018- Q3'), ('2018- Q4'),
            ('2019- Q1'), ('2019- Q2'), ('2019- Q3'), ('2019- Q4'),
            ('2020- Q1'), ('2020- Q2'), ('2020- Q3'), ('2020- Q4'),
            ('2021- Q1'), ('2021- Q2'), ('2021- Q3'), ('2021- Q4'),
            ('2022- Q1'), ('2022- Q2'), ('2022- Q3'), ('2022- Q4')
        $$
    ) AS ct (
        locations VARCHAR,
        "2018- Q1" NUMERIC,
        "2018- Q2" NUMERIC,
        "2018- Q3" NUMERIC,
        "2018- Q4" NUMERIC,
        "2019- Q1" NUMERIC,
        "2019- Q2" NUMERIC,
        "2019- Q3" NUMERIC,
        "2019- Q4" NUMERIC,
        "2020- Q1" NUMERIC,
        "2020- Q2" NUMERIC,
        "2020- Q3" NUMERIC,
        "2020- Q4" NUMERIC,
        "2021- Q1" NUMERIC,
        "2021- Q2" NUMERIC,
        "2021- Q3" NUMERIC,
        "2021- Q4" NUMERIC,
        "2022- Q1" NUMERIC,
        "2022- Q2" NUMERIC,
        "2022- Q3" NUMERIC,
        "2022- Q4" NUMERIC
    )
),  -- Total Transaction
transaction_counts AS (
    SELECT *
    FROM CROSSTAB(
        $$
        SELECT
            states || ' - ' || district AS locations,
            year || '- Q' || quarter AS periods,
            SUM(trans_counts)::NUMERIC AS total_counts
        FROM map_transaction
        GROUP BY states, district, year, quarter
        ORDER BY 1, 2
        $$,
        $$
        VALUES
            ('2018- Q1'), ('2018- Q2'), ('2018- Q3'), ('2018- Q4'),
            ('2019- Q1'), ('2019- Q2'), ('2019- Q3'), ('2019- Q4'),
            ('2020- Q1'), ('2020- Q2'), ('2020- Q3'), ('2020- Q4'),
            ('2021- Q1'), ('2021- Q2'), ('2021- Q3'), ('2021- Q4'),
            ('2022- Q1'), ('2022- Q2'), ('2022- Q3'), ('2022- Q4')
        $$
    ) AS ct (
        locations VARCHAR,
        "2018- Q1" NUMERIC,
        "2018- Q2" NUMERIC,
        "2018- Q3" NUMERIC,
        "2018- Q4" NUMERIC,
        "2019- Q1" NUMERIC,
        "2019- Q2" NUMERIC,
        "2019- Q3" NUMERIC,
        "2019- Q4" NUMERIC,
        "2020- Q1" NUMERIC,
        "2020- Q2" NUMERIC,
        "2020- Q3" NUMERIC,
        "2020- Q4" NUMERIC,
        "2021- Q1" NUMERIC,
        "2021- Q2" NUMERIC,
        "2021- Q3" NUMERIC,
        "2021- Q4" NUMERIC,
        "2022- Q1" NUMERIC,
        "2022- Q2" NUMERIC,
        "2022- Q3" NUMERIC,
        "2022- Q4" NUMERIC
    )
), -- Total User Counts
user_counts AS (
    SELECT *
    FROM CROSSTAB(
        $$
        SELECT
            states || ' - ' || district AS locations,
            year || '- Q' || quarter AS periods,
            SUM(registered_user_counts)::NUMERIC AS total_users
        FROM map_transaction
        GROUP BY states, district, year, quarter
        ORDER BY 1, 2
        $$,
        $$
        VALUES
            ('2018- Q1'), ('2018- Q2'), ('2018- Q3'), ('2018- Q4'),
            ('2019- Q1'), ('2019- Q2'), ('2019- Q3'), ('2019- Q4'),
            ('2020- Q1'), ('2020- Q2'), ('2020- Q3'), ('2020- Q4'),
            ('2021- Q1'), ('2021- Q2'), ('2021- Q3'), ('2021- Q4'),
            ('2022- Q1'), ('2022- Q2'), ('2022- Q3'), ('2022- Q4')
        $$
    ) AS ct (
        locations VARCHAR,
        "2018- Q1" NUMERIC,
        "2018- Q2" NUMERIC,
        "2018- Q3" NUMERIC,
        "2018- Q4" NUMERIC,
        "2019- Q1" NUMERIC,
        "2019- Q2" NUMERIC,
        "2019- Q3" NUMERIC,
        "2019- Q4" NUMERIC,
        "2020- Q1" NUMERIC,
        "2020- Q2" NUMERIC,
        "2020- Q3" NUMERIC,
        "2020- Q4" NUMERIC,
        "2021- Q1" NUMERIC,
        "2021- Q2" NUMERIC,
        "2021- Q3" NUMERIC,
        "2021- Q4" NUMERIC,
        "2022- Q1" NUMERIC,
        "2022- Q2" NUMERIC,
        "2022- Q3" NUMERIC,
        "2022- Q4" NUMERIC
    )
)
SELECT *
FROM transaction_counts
ORDER BY locations;

-- YoY % Change by States and District
WITH groupings AS(
	SELECT
		states,
		district,
		year,
		SUM(amount) AS total_amount,
		SUM(trans_counts) AS total_transactions,
		SUM(registered_user_counts) as total_users
	FROM map_transaction
	LEFT JOIN map_user
		USING(states, district, year, quarter)
	GROUP BY 1, 2, 3
)
SELECT
    states,
    district,
    year,
    -- Total Amount and YoY % Change
    total_amount,
    ROUND(
        (total_amount - LAG(total_amount) OVER (
            PARTITION BY states, district
            ORDER BY year
        )) * 100.0
        / NULLIF(
            LAG(total_amount) OVER (
                PARTITION BY states, district
                ORDER BY year
            ), 0
        ),
        2
    ) AS amount_yoy_pct,
    -- Total Transactions and YoY % Change
    total_transactions,
    ROUND(
        (total_transactions - LAG(total_transactions) OVER (
            PARTITION BY states, district
            ORDER BY year
        )) * 100.0
        / NULLIF(
            LAG(total_transactions) OVER (
                PARTITION BY states, district
                ORDER BY year
            ), 0
        ),
        2
    ) AS transactions_yoy_pct,
    -- Total Users and YoY % Change
    total_users,
    ROUND(
        (total_users - LAG(total_users) OVER (
            PARTITION BY states, district
            ORDER BY year
        )) * 100.0
        / NULLIF(
            LAG(total_users) OVER (
                PARTITION BY states, district
                ORDER BY year
            ), 0
        ),
        2
    ) AS users_yoy_pct
FROM groupings
ORDER BY states, district, year;


-- Top Transaction Table
SELECT * FROM aggregated_transaction;
SELECT * FROM aggregated_user;


-- Brand Analysis
WITH groupings AS(
SELECT
	states,
	year,
	quarter,
	brand,
	SUM(user_counts) AS total_users,
	SUM(trans_counts) AS total_transactions,
	SUM(amount) AS total_amount
FROM aggregated_user
LEFT JOIN aggregated_transaction
	USING(states, year, quarter)
GROUP BY states, year, brand, quarter
ORDER BY states, year
),
brands_yearly AS(
SELECT
	brand,
	year,
	SUM(total_users) AS total_users,
	ROUND(
    (SUM(total_users) - LAG(SUM(total_users)) OVER (PARTITION BY brand ORDER BY year)) * 100.0
    / NULLIF(LAG(SUM(total_users)) OVER (PARTITION BY brand ORDER BY year), 0),
    2
	) AS yoy_users_change_pct,
	SUM(total_transactions) AS total_transactions,
	ROUND(
    (SUM(total_transactions) - LAG(SUM(total_transactions)) OVER (PARTITION BY brand ORDER BY year)) * 100.0
    / NULLIF(LAG(SUM(total_transactions)) OVER (PARTITION BY brand ORDER BY year), 0),
    2
	) AS yoy_txn_change_pct,
	SUM(total_amount) AS total_amount,
	ROUND(
    (SUM(total_amount) - LAG(SUM(total_amount)) OVER (PARTITION BY brand ORDER BY year)) * 100.0
    / NULLIF(LAG(SUM(total_amount)) OVER (PARTITION BY brand ORDER BY year), 0),
    2
	) AS yoy_amount_change_pct
FROM groupings
GROUP BY 1, 2
ORDER BY brand, year
),
states_brands AS(
	SELECT
	    states,
	    brand,
	    SUM(total_amount) AS total_amount,
	    SUM(total_users) AS total_users,
	    ROUND(
	        SUM(total_amount) * 100.0
	        / NULLIF(SUM(SUM(total_amount)) OVER (PARTITION BY states), 0),
	        2
	    ) AS brand_pct_contribution,
	    ROUND(
	        SUM(SUM(total_amount)) OVER (
	            PARTITION BY states
	            ORDER BY SUM(total_amount) DESC, brand
	            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
	        ) * 100.0
	        / NULLIF(SUM(SUM(total_amount)) OVER (PARTITION BY states), 0),
	        2
	    ) AS running_total_pct,
	    SUM(total_transactions) AS total_transactions
	FROM groupings
	GROUP BY states, brand
	ORDER BY states, SUM(total_amount) DESC, brand
)
SELECT * FROM states_brands;


-- Transaction Type 
WITH groupings AS (
    SELECT
        states,
        year,
        quarter,
        trans_type,
        SUM(user_counts) AS total_users,
        SUM(trans_counts) AS total_transactions,
        SUM(amount) AS total_amount
    FROM aggregated_user
    LEFT JOIN aggregated_transaction
        USING(states, year, quarter)
    GROUP BY states, year, trans_type, quarter
    ORDER BY states, year
),
trans_type_yearly AS (
    SELECT
        trans_type,
        year,
        SUM(total_users) AS total_users,
        ROUND(
            (SUM(total_users) - LAG(SUM(total_users)) OVER (
                PARTITION BY trans_type ORDER BY year
            )) * 100.0
            / NULLIF(LAG(SUM(total_users)) OVER (
                PARTITION BY trans_type ORDER BY year
            ), 0),
            2
        ) AS yoy_users_change_pct,
        SUM(total_transactions) AS total_transactions,
        ROUND(
            (SUM(total_transactions) - LAG(SUM(total_transactions)) OVER (
                PARTITION BY trans_type ORDER BY year
            )) * 100.0
            / NULLIF(LAG(SUM(total_transactions)) OVER (
                PARTITION BY trans_type ORDER BY year
            ), 0),
            2
        ) AS yoy_txn_change_pct,
        SUM(total_amount) AS total_amount,
        ROUND(
            (SUM(total_amount) - LAG(SUM(total_amount)) OVER (
                PARTITION BY trans_type ORDER BY year
            )) * 100.0
            / NULLIF(LAG(SUM(total_amount)) OVER (
                PARTITION BY trans_type ORDER BY year
            ), 0),
            2
        ) AS yoy_amount_change_pct
    FROM groupings
    GROUP BY trans_type, year
    ORDER BY trans_type, year
),
states_trans_types AS (
	SELECT
	    states,
	    trans_type,
	    SUM(total_amount) AS total_amount,
	    ROUND(
	        SUM(total_amount) * 100.0
	        / NULLIF(
	            SUM(SUM(total_amount)) OVER (PARTITION BY states), 0
	        ), 2
	    ) AS amount_pct_contribution,
	    ROUND(
	        SUM(SUM(total_amount)) OVER (
	            PARTITION BY states
	            ORDER BY SUM(total_amount) DESC, trans_type
	            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
	        ) * 100.0
	        / NULLIF(
	            SUM(SUM(total_amount)) OVER (PARTITION BY states), 0
	        ), 2
	    ) AS amount_running_total_pct,
	    SUM(total_users) AS total_users,
	    SUM(total_transactions) AS total_transactions,
	    ROUND(
	        SUM(total_transactions) * 100.0
	        / NULLIF(
	            SUM(SUM(total_transactions)) OVER (PARTITION BY states), 0
	        ), 2
	    ) AS txn_pct_contribution,
	    ROUND(
	        SUM(SUM(total_transactions)) OVER (
	            PARTITION BY states
	            ORDER BY SUM(total_amount) DESC, trans_type
	            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
	        ) * 100.0
	        / NULLIF(
	            SUM(SUM(total_transactions)) OVER (PARTITION BY states), 0
	        ), 2
	    ) AS txn_running_total_pct
	FROM groupings
	GROUP BY states, trans_type
	ORDER BY states, SUM(total_amount) DESC, trans_type
)
SELECT *
FROM states_trans_types;