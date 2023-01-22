-- Cohort Analysis - User Retention (monthly)
-- assume the analysis is taken in 1997 period

USE Northwind;

WITH
-- 1. for each customer id, find their first time order (month)
first_buy AS(
	SELECT
		o.CustomerID
		, DATEPART(MONTH, MIN(o.OrderDate)) first_time_buy
	FROM Orders o
	WHERE o.OrderDate BETWEEN '1997-01-01' AND '1997-12-31'
	GROUP BY o.CustomerID),

-- 2. for each customer id, find all of their time order (month)
next_purchase AS(
	SELECT
		o.CustomerID
		, DATEPART(MONTH, o.OrderDate) - first_time_buy AS buy_interval 
	FROM Orders o
	JOIN first_buy f ON o.CustomerID = f.CustomerID
	WHERE o.OrderDate BETWEEN '1997-01-01' AND '1997-12-31'),

-- 3. for each first time buy (month), calculate the number of total distinct customer
initial_user AS(
	SELECT
		first_time_buy
		, COUNT(DISTINCT CustomerID) AS users
	FROM first_buy
	GROUP BY first_time_buy),

-- 4. calculate the retention for each first time buy (month) & for each buy interval (month)
retention AS(
	SELECT
		f.first_time_buy
		, buy_interval
		, COUNT(DISTINCT n.CustomerID) AS users_transacting
	FROM first_buy f
	JOIN next_purchase n ON f.CustomerID = n.CustomerID
	WHERE buy_interval IS NOT NULL
	GROUP BY f.first_time_buy, buy_interval)

-- 5. put it all together, convert the retention into percentage
SELECT
	r.first_time_buy,
	i.users ,
	r.buy_interval,
	r.users_transacting,
	100.0*r.users_transacting/i.users AS '%_user_transacting'
FROM retention r
LEFT JOIN initial_user i ON r.first_time_buy = i.first_time_buy
ORDER BY r.first_time_buy, r.buy_interval
;