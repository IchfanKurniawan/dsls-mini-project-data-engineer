-- Customer Analysis - RFM
-- assume to make the analysis for the whole 1997 year & develop the analysis in 1998-01-07
-- REF: https://clevertap.com/blog/rfm-analysis/

USE Northwind;

-- 1. rfm score for each customer id
WITH 
base_rfm_score AS
	(SELECT
		o.CustomerID
		, COUNT(DISTINCT o.OrderID) as 'frequency_value'
		, DATEDIFF(DAY, MAX(o.OrderDate), '1998-01-07') as 'recency_value'
		, SUM((1-od.Discount)*(od.UnitPrice*od.Quantity)) as 'monetary_value'
		, NTILE(5) OVER(ORDER BY COUNT(DISTINCT o.OrderID) ASC) as 'frequency_score'
		, NTILE(5) OVER(ORDER BY DATEDIFF(DAY, MAX(o.OrderDate), '1998-01-07') DESC) as 'recency_score'
		, NTILE(5) OVER(ORDER BY SUM((1-od.Discount)*(od.UnitPrice*od.Quantity)) ASC) as 'monetary_score'
	FROM Orders o
	JOIN [Order Details] od ON o.OrderID = od.OrderID
	WHERE o.OrderDate BETWEEN '1997-01-01' AND '1997-12-31'
	GROUP BY o.CustomerID),

-- 2. from the rfm score, group each customer to rfm segment
rfm_segment_table AS
	(SELECT
		*
		, (monetary_score + recency_score + frequency_score)/3 as 'rfm_score'
		, CASE WHEN (recency_score = 5) AND ((frequency_score=5) OR (frequency_score=4)) THEN 'champion'
		WHEN ((recency_score = 3) OR (recency_score = 4)) AND ((frequency_score=5) OR (frequency_score=4)) THEN 'loyal customer'
		WHEN ((recency_score = 1) OR (recency_score = 2)) AND (frequency_score=5) THEN 'cant lose them'
		WHEN ((recency_score = 5) OR (recency_score = 4)) AND ((frequency_score=3) OR (frequency_score=2)) THEN 'potential loyalist'
		WHEN (recency_score = 3) AND (frequency_score=3) THEN 'need attention'
		WHEN ((recency_score = 1) OR (recency_score = 2)) AND ((frequency_score=3) OR (frequency_score=4)) THEN 'at risk'
		WHEN (recency_score = 5) AND (frequency_score=1) THEN 'new customer'
		WHEN (recency_score = 4) AND (frequency_score=1) THEN 'promising'
		WHEN (recency_score = 3) AND ((frequency_score=1) OR (frequency_score=2)) THEN 'about to sleep'
		ELSE 'hibernating' END AS 'rfm_segment'
	FROM base_rfm_score)

-- 3. for each customer segment, calcuate its proportion & avg monetary value
SELECT
	rfm_segment
	, 100.0*COUNT(CustomerID)/(SELECT COUNT(*) FROM rfm_segment_table) AS '%_segment'
	, AVG(monetary_value) AS 'avg_monetary'
FROM rfm_segment_table
GROUP BY rfm_segment
ORDER BY 100.0*COUNT(CustomerID)/(SELECT COUNT(*) FROM rfm_segment_table) DESC
;