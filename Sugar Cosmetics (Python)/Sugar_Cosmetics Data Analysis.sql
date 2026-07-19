SELECT * FROM fact_sc
ORDER BY "Likes" DESC;

-- Top Correlations Above 75%
SELECT
	'IR',
	CORR("Impressions", "Reach")
FROM fact_sc
UNION
SELECT
	'IP',
	CORR("Impressions", "Profile Visits")
FROM fact_sc
UNION
SELECT
	'IL',
	CORR("Impressions", "Likes")
FROM fact_sc
UNION
SELECT
	'RL',
	CORR("Reach", "Likes")
FROM fact_sc
UNION
SELECT
	'PF',
	CORR("Profile Visits", "Follows")
FROM fact_sc
UNION
SELECT
	'RP',
	CORR("Reach", "Profile Visits")
FROM fact_sc
UNION
SELECT
	'L,S',
	CORR("Likes", "Shares")
FROM fact_sc
UNION
SELECT
	'LS',
	CORR("Likes", "Saves")
FROM fact_sc
;

SELECT
	'LS',
	CORR("", "")
FROM fact_sc


SELECT
	EXTRACT(month FROM "Post Date") AS month,
	"Post Type",
	"Likes"
FROM fact_sc
WHERE EXTRACT(month FROM "Post Date") = 11
ORDER BY 3 DESC,2;