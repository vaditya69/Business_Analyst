CREATE TABLE fact_sc (
    post_id BIGINT,
    post_date TIMESTAMP,
    post_type VARCHAR(50),
    campaign_type VARCHAR(100),
    hashtags TEXT,
    audience_emotion VARCHAR(50),
    engagement_source VARCHAR(50),
    impressions INTEGER,
    reach INTEGER,
    likes INTEGER,
    comments INTEGER,
    shares INTEGER,
    saves INTEGER,
    profile_visits INTEGER,
    follows INTEGER,
    hashtag_counts INTEGER,
    engagement_rate NUMERIC(10,4),
    day_of_week INTEGER,
    name_dow VARCHAR(20)
);

drop table fact_sc;
COPY fact_sc
FROM 'C:/Users/Adity/Desktop/Aditya/Projects/Sugar Cosmetics/sugar cosmetics.csv'
DELIMITER ','
CSV HEADER;

ALTER TABLE fact_sc
DROP COLUMN "day_of_week" ;

ALTER TABLE fact_sc
DROP COLUMN "name_dow" ;
---------------------------------

-- Campaign Type Table
CREATE TABLE dim_campaign_type AS
SELECT
    ROW_NUMBER() OVER (ORDER BY "Campaign Type") AS campaign_type_id,
    "Campaign Type"
FROM (
    SELECT DISTINCT "Campaign Type"
    FROM fact_sc
) t;

ALTER TABLE dim_campaign_type
ADD PRIMARY KEY (campaign_type_id);

ALTER TABLE dim_campaign_type
RENAME COLUMN "Campaign Type" TO "campaign_type";


-- Post Type Table
CREATE TABLE dim_post_type AS
SELECT
    ROW_NUMBER() OVER (ORDER BY "Post Type") AS post_type_id,
    "Post Type" AS post_type
FROM (
    SELECT DISTINCT "Post Type"
    FROM fact_sc
) t;
ALTER TABLE dim_post_type
ADD PRIMARY KEY (post_type_id);


-- Audience Emotion Table
CREATE TABLE dim_audience_emotion AS
SELECT
    ROW_NUMBER() OVER (ORDER BY "Audience Emotion") AS emotion_id,
    "Audience Emotion" AS audience_emotion
FROM (
    SELECT DISTINCT "Audience Emotion"
    FROM fact_sc
) t;
ALTER TABLE dim_audience_emotion
ADD PRIMARY KEY (emotion_id);


-- Engagement Source Table
CREATE TABLE dim_engagement_source AS
SELECT
    ROW_NUMBER() OVER (ORDER BY "Engagement Source") AS engagement_source_id,
    "Engagement Source" AS engagement_source
FROM (
    SELECT DISTINCT "Engagement Source"
    FROM fact_sc
) t;
ALTER TABLE dim_engagement_source
ADD PRIMARY KEY (engagement_source_id);


-- Hashtag Table
CREATE TABLE dim_hashtag AS
SELECT
    ROW_NUMBER() OVER (ORDER BY hashtag) AS hashtag_id,
    hashtag
FROM (
    SELECT DISTINCT hashtag
    FROM bridge_post_hashtag_raw
) t;

ALTER TABLE dim_hashtag
ADD PRIMARY KEY (hashtag_id);

SELECT * FROM bridge_post_hashtag_raw;

-- Post-Hashtag Table 
'''
CREATE TABLE bridge_post_hashtag_raw AS(
SELECT
    "post_id",
    TRIM(unnest(string_to_array("hashtags", ','))) AS hashtag
FROM fact_sc);

DROP TABLE bridge_post_hashtag_raw;
'''

CREATE TABLE bridge_post_hashtag AS (
SELECT 
	post_id,
	hashtag_id
FROM (
	SELECT * 
	FROM bridge_post_hashtag_raw
	JOIN dim_hashtag
	USING(hashtag)
))
;

SELECT * FROM bridge_post_hashtag;

SELECT * FROM dim_hashtag;

----------------------------
CREATE TABLE ffact_sc (
    post_id INT PRIMARY KEY,
    post_date DATE,
    post_type_id INT,
    campaign_id INT,
    emotion_id INT,
    engagement_type_id INT,
    impressions INT,
    reach INT,
    likes INT,
    comments INT,
    shares INT,
    saves INT,
    profile_visits INT,
    follows INT,
	hashtag_counts INT,
	engagement_rate NUMERIC(10, 4))
;

---------------------------
SELECT * FROM ffact_sc;


ALTER TABLE ffact_sc
ADD CONSTRAINT fk_audience
FOREIGN KEY (emotion_id)
REFERENCES dim_audience_emotion(emotion_id);

ALTER TABLE ffact_sc
ADD CONSTRAINT fk_post_type
FOREIGN KEY (post_type_id)
REFERENCES dim_post_type(post_type_id);

ALTER TABLE ffact_sc
ADD CONSTRAINT fk_campaign
FOREIGN KEY (campaign_id)
REFERENCES dim_campaign_type(campaign_type_id);

ALTER TABLE ffact_sc
ADD CONSTRAINT fk_engagement
FOREIGN KEY (engagement_type_id)
REFERENCES dim_engagement_source(engagement_source_id);

-------------------
INSERT INTO ffact_sc (
    post_id,
    post_date,
    post_type_id,
    campaign_id,
    emotion_id,
    engagement_type_id,
    impressions,
    reach,
    likes,
    comments,
    shares,
    saves,
    profile_visits,
    follows,
	hashtag_counts,
	engagement_rate
)
SELECT
    f."post_id",
    f."post_date",
    pt.post_type_id,
    ct.campaign_type_id,
    ae.emotion_id,
    es.engagement_source_id,
    f."impressions",
    f."reach",
    f."likes",
    f."comments",
    f."shares",
    f."saves",
    f."profile_visits",
    f."follows",
	f."hashtag_counts",
	f."engagement_rate"
FROM fact_sc f
JOIN dim_post_type pt
    ON f."post_type" = pt.post_type
JOIN dim_campaign_type ct
    ON f."campaign_type" = ct."Campaign Type"
JOIN dim_audience_emotion ae
    ON f."audience_emotion" = ae.audience_emotion
JOIN dim_engagement_source es
    ON f."engagement_source" = es.engagement_source;


--------------------------------

DROP table dim_date;

CREATE TABLE dim_date AS (
	SELECT
		DISTINCT post_date,
		EXTRACT(month FROM post_date) AS month,
		EXTRACT(day FROM post_date) AS day,
		EXTRACT(dow FROM post_date) AS dow
	FROM ffact_sc
	ORDER BY 1
);

ALTER TABLE dim_date
ADD PRIMARY KEY (post_date);

ALTER TABLE ffact_sc
ADD CONSTRAINT fk_date
FOREIGN KEY (post_date)
REFERENCES dim_date(post_date);
---------------------------------

SELECT * 
FROM ffact_sc;


-- Top Correlations Above 75%
SELECT
	'IR',
	CORR(impressions, reach)
FROM ffact_sc
UNION
SELECT
	'IP',
	CORR(impressions, profile_visits)
FROM ffact_sc
UNION
SELECT
	'IL',
	CORR(impressions, likes)
FROM ffact_sc
UNION
SELECT
	'RL',
	CORR(reach, likes)
FROM ffact_sc
UNION
SELECT
	'PF',
	CORR(profile_visits, follows)
FROM ffact_sc
UNION
SELECT
	'RP',
	CORR(reach, profile_visits)
FROM ffact_sc
UNION
SELECT
	'L,S',
	CORR(likes, shares)
FROM ffact_sc
UNION
SELECT
	'LS',
	CORR(likes, saves)
FROM ffact_sc
;

-- Metrics and Avg Engagement Rate Breakdown by Month 
SELECT
	EXTRACT(month FROM post_date) AS months,
	SUM(profile_visits) AS total_profile_visits,
	SUM(impressions) AS total_impressions,
	SUM(reach) AS total_reach,
	SUM(likes) AS total_likes,
	SUM(comments) AS total_comments,
	SUM(shares) AS total_shares,
	SUM(saves) AS total_saves,
	SUM(follows) AS total_follows,
	ROUND(AVG(engagement_rate), 4) AS avg_engagement_rate
FROM ffact_sc
GROUP BY 1
ORDER BY 1;

-- Finding the best performing Hashtags by each Campaign Type, Post Type, Engagement Type and Audience Emotion
WITH groupings AS(
SELECT
	campaign_type,
	post_type,
	engagement_source AS engagement_type,
	hashtag,
	audience_emotion,
	ROUND(AVG(engagement_rate), 4) AS avg_engagement_rate
FROM ffact_sc
LEFT JOIN dim_campaign_type
	ON campaign_id = campaign_type_id
LEFT JOIN bridge_post_hashtag
	USING(post_id)
LEFT JOIN dim_hashtag
	USING(hashtag_id)
LEFT JOIN dim_post_type
	USING(post_type_id)
LEFT JOIN dim_engagement_source
	ON engagement_type_id = engagement_source_id
LEFT JOIN dim_audience_emotion
	USING(emotion_id)
GROUP BY campaign_type, post_type, engagement_source, hashtag, audience_emotion
ORDER BY campaign_type, post_type, engagement_source, hashtag, audience_emotion
),
rankings AS(
SELECT
	*,
	DENSE_RANK() OVER(PARTITION BY campaign_type ORDER BY avg_engagement_rate DESC) AS top_performing
FROM groupings
)
SELECT * FROM rankings;

-- Finding Campaigns which hashtags have the highest Avg Engagement Rate
WITH groupings AS(
SELECT
	*
FROM ffact_sc
LEFT JOIN bridge_post_hashtag
	USING(post_id)
LEFT JOIN dim_campaign_type
	ON campaign_id = campaign_type_id 
LEFT JOIN dim_hashtag
	USING(hashtag_id)
),
campaign_grouping AS(
SELECT
	campaign_type,
	hashtag,
	COUNT(*) as total_hashtags,
	ROUND(AVG(engagement_rate), 4) AS avg_engagement_rate
FROM groupings
GROUP BY 1, 2
), 
rankings AS(
SELECT
	*,
	DENSE_RANK() OVER(PARTITION BY campaign_type ORDER BY avg_engagement_rate DESC) AS top_performing
FROM campaign_grouping
), 
-- Campaign Type, Engagement Type and Post Type  with Number of Hashtags used and Avg Engagement Rate
post_metrics AS(
SELECT
	campaign_type,
	engagement_source,
	post_type,
	hashtag_counts,
	ROUND(AVG(engagement_rate), 4) AS engagement_rate
FROM groupings
LEFT JOIN dim_post_type
	USING(post_type_id)
LEFT JOIN dim_engagement_source
	ON engagement_type_id = engagement_source_id
GROUP BY campaign_type, engagement_source, post_type, hashtag_counts
ORDER BY 1, 3 DESC
)
SELECT * FROM post_metrics;

-- Total Metrics by Post Type and Campaign Type
SELECT
	campaign_type,
	post_type,
	SUM(profile_visits) AS total_profile_visits,
	SUM(impressions) AS total_impressions,
	SUM(reach) AS total_reach,
	SUM(likes) AS total_likes,
	SUM(comments) AS total_comments,
	SUM(shares) AS total_shares,
	SUM(saves) AS total_saves,
	SUM(follows) AS total_follows,
	ROUND(AVG(engagement_rate), 4) AS avg_engagement_rate
FROM ffact_sc
LEFT JOIN dim_post_type
	USING(post_type_id)
LEFT JOIN dim_campaign_type
	ON campaign_id = campaign_type_id 
GROUP BY campaign_type, post_type;

-- Total Metrics by Hashtags and Post Type
SELECT
	hashtag,
	post_type,
	SUM(profile_visits) AS total_profile_visits,
	SUM(impressions) AS total_impressions,
	SUM(reach) AS total_reach,
	SUM(likes) AS total_likes,
	SUM(comments) AS total_comments,
	SUM(shares) AS total_shares,
	SUM(saves) AS total_saves,
	SUM(follows) AS total_follows,
	ROUND(AVG(engagement_rate), 4) AS avg_engagement_rate
FROM ffact_sc
LEFT JOIN dim_post_type
	USING(post_type_id)
LEFT JOIN bridge_post_hashtag
	USING(post_id) 
LEFT JOIN dim_hashtag
	USING(hashtag_id) 
GROUP BY hashtag, post_type
ORDER BY hashtag, post_type;

-- Post Type Breakdown
SELECT
	post_type,
	COUNT(*) AS total_posts
FROM ffact_sc
LEFT JOIN dim_post_type
	USING(post_type_id)
GROUP BY post_type;

-- Total Metrics and Avg Engagement rate by Audience Emotions and Hashtags
SELECT
	hashtag,
	audience_emotion,
	SUM(profile_visits) AS total_profile_visits,
	SUM(impressions) AS total_impressions,
	SUM(reach) AS total_reach,
	SUM(likes) AS total_likes,
	SUM(comments) AS total_comments,
	SUM(shares) AS total_shares,
	SUM(saves) AS total_saves,
	SUM(follows) AS total_follows,
	ROUND(AVG(engagement_rate), 4) AS avg_engagement_rate
FROM ffact_sc
LEFT JOIN bridge_post_hashtag
	USING(post_id)
LEFT JOIN dim_hashtag
	USING(hashtag_id) 
LEFT JOIN dim_audience_emotion
	USING(emotion_id)
GROUP BY 1, 2;

-- Total Metrics by Campaign Type and Hashtag
SELECT
	campaign_type,
	hashtag,
	SUM(profile_visits) AS total_profile_visits,
	SUM(impressions) AS total_impressions,
	SUM(reach) AS total_reach,
	SUM(likes) AS total_likes,
	SUM(comments) AS total_comments,
	SUM(shares) AS total_shares,
	SUM(saves) AS total_saves,
	SUM(follows) AS total_follows,
	ROUND(AVG(engagement_rate), 4) AS avg_engagement_rate
FROM ffact_sc
LEFT JOIN bridge_post_hashtag
	USING(post_id)
LEFT JOIN dim_hashtag
	USING(hashtag_id)
LEFT JOIN dim_campaign_type
	ON campaign_id = campaign_type_id 
GROUP BY campaign_type, hashtag;


-- Time Series Analysis
WITH groupings AS(
SELECT
	EXTRACT(YEAR from post_date) AS year,
	EXTRACT(month from post_date) AS month,
	EXTRACT(DOW from post_date) AS dow,
	campaign_type,
	post_type,
	engagement_source,
	audience_emotion,
	SUM(profile_visits) AS total_profile_visits,
	SUM(impressions) AS total_impressions,
	SUM(reach) AS total_reach,
	SUM(likes) AS total_likes,
	SUM(comments) AS total_comments,
	SUM(shares) AS total_shares,
	SUM(saves) AS total_saves,
	SUM(follows) AS total_follows,
	ROUND(AVG(engagement_rate), 4) AS avg_engagement_rate
FROM ffact_sc
LEFT JOIN dim_campaign_type
	ON campaign_id = campaign_type_id 
LEFT JOIN dim_post_type
	USING(post_type_id)
LEFT JOIN dim_engagement_source
	ON engagement_type_id = engagement_source_id
LEFT JOIN dim_audience_emotion
	USING(emotion_id)
GROUP BY year, month, dow, campaign_type, post_type, engagement_source, audience_emotion
ORDER BY year, month
)
SELECT * FROM groupings;

-- With Hashtags
SELECT
	EXTRACT(YEAR from post_date) AS year,
	EXTRACT(month from post_date) AS month,
	EXTRACT(DOW from post_date) AS dow,
	hashtag,
	SUM(profile_visits) AS total_profile_visits,
	SUM(impressions) AS total_impressions,
	SUM(reach) AS total_reach,
	SUM(likes) AS total_likes,
	SUM(comments) AS total_comments,
	SUM(shares) AS total_shares,
	SUM(saves) AS total_saves,
	SUM(follows) AS total_follows,
	ROUND(AVG(engagement_rate), 4) AS avg_engagement_rate	
FROM ffact_sc
LEFT JOIN bridge_post_hashtag
	USING(post_id)
LEFT JOIN dim_hashtag
	USING(hashtag_id)
GROUP BY year, month, dow, hashtag;

-- Tables
SELECT * FROM ffact_sc;
SELECT * FROM dim_date;
SELECT * FROM dim_campaign_type;
SELECT * FROM bridge_post_hashtag;
SELECT * FROM dim_hashtag;
SELECT * FROM dim_engagement_source;
SELECT * FROM dim_post_type;
SELECT * FROM dim_audience_emotion;