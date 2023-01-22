use Northwind;

-- BASE TABLE
SELECT
	o.OrderID
	, o.CustomerID
	, o.EmployeeID
	, o.OrderDate
	, o.ShipCity
	, o.ShipRegion
	, o.ShipCountry
	, sh.CompanyName AS 'shipper_company_name'
	, cs.CompanyName AS 'customer_company_name'
	, cs.ContactTitle AS 'customer_title'
	, cs.City AS 'customer_city'
	, cs.Region AS 'customer_region'
	, cs.Country AS 'customer_country'
	, CONCAT(e.FirstName, '' ,e.LastName) AS 'emp_full_name'
	, e.Title AS 'emp_title'
	, t.TerritoryDescription AS 'sales_territory'
	, r.RegionDescription AS 'sales_region'
	, od.ProductID
	, od.Quantity
	, od.UnitPrice
	, od.Discount
	, p.ProductName
	, p.QuantityPerUnit
	, p.UnitsInStock
	, p.UnitsOnOrder
	, p.Discontinued
	, c.CategoryName
	, s.CompanyName AS 'supplier_company'
	, s.City AS 'supplier_city'
	, s.Country AS 'supplier_country'
	, s.Region AS 'supplier_region'
	, s.SupplierID
FROM Orders o
JOIN Employees e ON o.EmployeeID = e.EmployeeID
JOIN EmployeeTerritories et ON e.EmployeeID = et.EmployeeID
JOIN Territories t ON et.TerritoryID = t.TerritoryID
JOIN Region r ON t.RegionID = t.RegionID
JOIN Shippers sh ON o.ShipVia = sh.ShipperID
JOIN Customers cs ON o.CustomerID = cs.CustomerID
JOIN [Order Details] od ON o.OrderID = od.OrderID
JOIN Products p ON od.ProductID = p.ProductID
JOIN Categories c ON p.CategoryID = c.CategoryID
JOIN Suppliers s ON p.SupplierID = s.SupplierID
ORDER BY o.OrderDate
;


-- 1. PRODUCT ANALYSIS
-- overall picture of sales
SELECT

	YEAR(o.OrderDate) AS 'year'
	, MONTH(o.OrderDate) AS 'month'
	, SUM(od.UnitPrice * od.Quantity) AS 'sum_sales'
	, ROUND(100.0*(SUM(od.UnitPrice * od.Quantity) - LAG(SUM(od.UnitPrice * od.Quantity), 1) OVER(ORDER BY YEAR(o.OrderDate), MONTH(o.OrderDate))) / 
			LAG(SUM(od.UnitPrice * od.Quantity), 1) OVER(ORDER BY YEAR(o.OrderDate), MONTH(o.OrderDate)), 2) AS '%_chg_sum_sales'
	
	, AVG(od.UnitPrice * od.Quantity) AS 'avg_sales'
	, COUNT(od.UnitPrice * od.Quantity) AS 'vol_sales'

	, SUM(od.Quantity) AS 'sum_qty'
	, ROUND(100.0*(SUM(od.Quantity) - LAG(SUM(od.Quantity), 1) OVER(ORDER BY YEAR(o.OrderDate), MONTH(o.OrderDate))) / 
			LAG(SUM(od.Quantity), 1) OVER(ORDER BY YEAR(o.OrderDate), MONTH(o.OrderDate)), 2) AS '%_chg_sum_qty'

	, AVG(od.UnitPrice) AS 'avg_u_price'
	, ROUND(100.0*(AVG(od.UnitPrice) - LAG(AVG(od.UnitPrice), 1) OVER(ORDER BY YEAR(o.OrderDate), MONTH(o.OrderDate))) / 
			LAG(AVG(od.UnitPrice), 1) OVER(ORDER BY YEAR(o.OrderDate), MONTH(o.OrderDate)), 2) AS '%_chg_avg_u_price'

FROM Orders o
JOIN [Order Details] od ON o.OrderID = od.OrderID
GROUP BY YEAR(o.OrderDate), MONTH(o.OrderDate)
ORDER BY YEAR(o.OrderDate), MONTH(o.OrderDate)
;

-- because only in 1997 that capture the full date -> focusing analysis in 1997 only
-- pareto customer's company on sales in 1997
WITH company_sales AS
	(SELECT
		c.CompanyName
		, SUM(od.UnitPrice*od.Quantity) as 'sum_sales'
	FROM Orders o
	JOIN Customers c ON o.CustomerID = c.CustomerID
	JOIN [Order Details] od ON o.OrderID = od.OrderID
	WHERE o.OrderDate BETWEEN '1997-01-01' AND '1997-12-31'
	GROUP BY c.CompanyName)

SELECT 
	*
	, 100.0 * sum_sales / (SELECT SUM(sum_sales) FROM company_sales) AS '%_sales'
	, 100.0 * SUM(sum_sales) OVER(ORDER BY sum_sales DESC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) / (SELECT SUM(sum_sales) FROM company_sales) as '%_cumsum_sales'
FROM company_sales
;

-- pareto product name on sales
WITH product_sales AS
	(SELECT
		p.ProductName
		, SUM(od.UnitPrice*od.Quantity) as 'sum_sales'
	FROM Orders o	
	JOIN [Order Details] od ON o.OrderID = od.OrderID
	JOIN Products p ON od.ProductID = p.ProductID
	WHERE o.OrderDate BETWEEN '1997-01-01' AND '1997-12-31'
	GROUP BY p.ProductName)

SELECT 
	*
	, 100.0 * sum_sales / (SELECT SUM(sum_sales) FROM product_sales) AS '%_sales'
	, 100.0 * SUM(sum_sales) OVER(ORDER BY sum_sales DESC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) / (SELECT SUM(sum_sales) FROM product_sales) as '%_cumsum_sales'
FROM product_sales
;

-- pareto category name on sales
WITH category_sales AS
	(SELECT
		c.CategoryName
		, SUM(od.UnitPrice*od.Quantity) as 'sum_sales'
	FROM Orders o	
	JOIN [Order Details] od ON o.OrderID = od.OrderID
	JOIN Products p ON od.ProductID = p.ProductID
	JOIN Categories c ON p.CategoryID = c.CategoryID
	WHERE o.OrderDate BETWEEN '1997-01-01' AND '1997-12-31'
	GROUP BY c.CategoryName)

SELECT 
	*
	, 100.0 * sum_sales / (SELECT SUM(sum_sales) FROM category_sales) AS '%_sales'
	, 100.0 * SUM(sum_sales) OVER(ORDER BY sum_sales DESC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) / (SELECT SUM(sum_sales) FROM category_sales) as '%_cumsum_sales'
FROM category_sales
;

-- pareto sales's teritory on sales
WITH teritory_sales AS
	(SELECT
		t.TerritoryDescription
		, SUM(od.UnitPrice*od.Quantity) as 'sum_sales'
	FROM Orders o	
	JOIN [Order Details] od ON o.OrderID = od.OrderID
	JOIN Employees e ON e.EmployeeID = o.EmployeeID
	JOIN EmployeeTerritories et ON et.EmployeeID = o.EmployeeID
	JOIN Territories t ON et.TerritoryID = t.TerritoryID
	WHERE o.OrderDate BETWEEN '1997-01-01' AND '1997-12-31'
	GROUP BY t.TerritoryDescription)

SELECT 
	*
	, 100.0 * sum_sales / (SELECT SUM(sum_sales) FROM teritory_sales) AS '%_sales'
	, 100.0 * SUM(sum_sales) OVER(ORDER BY sum_sales DESC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) / (SELECT SUM(sum_sales) FROM teritory_sales) as '%_cumsum_sales'
FROM teritory_sales
;

-- pareto sales's region on sales
WITH region_sales AS
	(SELECT
		r.RegionDescription
		, SUM(od.UnitPrice*od.Quantity) as 'sum_sales'
	FROM Orders o	
	JOIN [Order Details] od ON o.OrderID = od.OrderID
	JOIN Employees e ON e.EmployeeID = o.EmployeeID
	JOIN EmployeeTerritories et ON et.EmployeeID = o.EmployeeID
	JOIN Territories t ON et.TerritoryID = t.TerritoryID
	JOIN Region r ON r.RegionID = t.RegionID
	WHERE o.OrderDate BETWEEN '1997-01-01' AND '1997-12-31'
	GROUP BY r.RegionDescription)

SELECT 
	*
	, 100.0 * sum_sales / (SELECT SUM(sum_sales) FROM region_sales) AS '%_sales'
	, 100.0 * SUM(sum_sales) OVER(ORDER BY sum_sales DESC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) / (SELECT SUM(sum_sales) FROM region_sales) as '%_cumsum_sales'
FROM region_sales
;

-- pareto territory name on sales in eastern region
-- territory in eastern with the highest sales
WITH territory_sales AS
	(SELECT
		t.TerritoryDescription
		, SUM(od.UnitPrice*od.Quantity) as 'sum_sales'
	FROM Orders o	
	JOIN [Order Details] od ON o.OrderID = od.OrderID
	JOIN Employees e ON e.EmployeeID = o.EmployeeID
	JOIN EmployeeTerritories et ON et.EmployeeID = o.EmployeeID
	JOIN Territories t ON et.TerritoryID = t.TerritoryID
	JOIN Region r ON r.RegionID = t.RegionID
	WHERE (o.OrderDate BETWEEN '1997-01-01' AND '1997-12-31') AND (RegionDescription = 'Eastern')
	GROUP BY t.TerritoryDescription)

SELECT 
	*
	, 100.0 * sum_sales / (SELECT SUM(sum_sales) FROM territory_sales) AS '%_sales'
	, 100.0 * SUM(sum_sales) OVER(ORDER BY sum_sales DESC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) / (SELECT SUM(sum_sales) FROM territory_sales) as '%_cumsum_sales'
FROM territory_sales
;


-- pareto category name on sales in eastern region
-- category name in eastern with the highest sales
WITH category_sales AS
	(SELECT
		c.CategoryName
		, SUM(od.UnitPrice*od.Quantity) as 'sum_sales'
	FROM Orders o	
	JOIN [Order Details] od ON o.OrderID = od.OrderID
	JOIN Products p ON od.ProductID = p.ProductID
	JOIN Categories c ON p.CategoryID = c.CategoryID
	JOIN Employees e ON e.EmployeeID = o.EmployeeID
	JOIN EmployeeTerritories et ON et.EmployeeID = o.EmployeeID
	JOIN Territories t ON et.TerritoryID = t.TerritoryID
	JOIN Region r ON r.RegionID = t.RegionID
	WHERE (o.OrderDate BETWEEN '1997-01-01' AND '1997-12-31') AND (RegionDescription = 'Eastern')
	GROUP BY c.CategoryName)

SELECT 
	*
	, 100.0 * sum_sales / (SELECT SUM(sum_sales) FROM category_sales) AS '%_sales'
	, 100.0 * SUM(sum_sales) OVER(ORDER BY sum_sales DESC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) / (SELECT SUM(sum_sales) FROM category_sales) as '%_cumsum_sales'
FROM category_sales
;

-- pareto product name on sales in eastern region
-- product name in eastern with the highest sales
WITH product_sales AS
	(SELECT
		p.ProductName
		, SUM(od.UnitPrice*od.Quantity) as 'sum_sales'
	FROM Orders o	
	JOIN [Order Details] od ON o.OrderID = od.OrderID
	JOIN Products p ON od.ProductID = p.ProductID
	JOIN Categories c ON p.CategoryID = c.CategoryID
	JOIN EmployeeTerritories et ON et.EmployeeID = o.EmployeeID
	JOIN Territories t ON et.TerritoryID = t.TerritoryID
	JOIN Region r ON r.RegionID = t.RegionID
	WHERE (o.OrderDate BETWEEN '1997-01-01' AND '1997-12-31') AND (RegionDescription = 'Eastern')
	GROUP BY p.ProductName)

SELECT 
	*
	, 100.0 * sum_sales / (SELECT SUM(sum_sales) FROM product_sales) AS '%_sales'
	, 100.0 * SUM(sum_sales) OVER(ORDER BY sum_sales DESC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) / (SELECT SUM(sum_sales) FROM product_sales) as '%_cumsum_sales'
FROM product_sales
;


-----
-----
-- Analyze the spike phenomena on Nov 97 to Apr 98 period

-- pareto sales's region on sales on Nov 97 to Apr 98 period
WITH region_sales AS
	(SELECT
		r.RegionDescription
		, SUM(od.UnitPrice*od.Quantity) as 'sum_sales'
	FROM Orders o	
	JOIN [Order Details] od ON o.OrderID = od.OrderID
	JOIN EmployeeTerritories et ON et.EmployeeID = o.EmployeeID
	JOIN Territories t ON et.TerritoryID = t.TerritoryID
	JOIN Region r ON r.RegionID = t.RegionID
	WHERE o.OrderDate BETWEEN '1997-11-01' AND '1998-04-30'
	GROUP BY r.RegionDescription)

SELECT 
	*
	, 100.0 * sum_sales / (SELECT SUM(sum_sales) FROM region_sales) AS '%_sales'
	, 100.0 * SUM(sum_sales) OVER(ORDER BY sum_sales DESC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) / (SELECT SUM(sum_sales) FROM region_sales) as '%_cumsum_sales'
FROM region_sales
;


-- pareto territory name on sales in eastern region
-- territory in eastern with the highest sales on Nov 97 to Apr 98 period
WITH territory_sales AS
	(SELECT
		t.TerritoryDescription
		, SUM(od.UnitPrice*od.Quantity) as 'sum_sales'
	FROM Orders o	
	JOIN [Order Details] od ON o.OrderID = od.OrderID
	JOIN Employees e ON e.EmployeeID = o.EmployeeID
	JOIN EmployeeTerritories et ON et.EmployeeID = o.EmployeeID
	JOIN Territories t ON et.TerritoryID = t.TerritoryID
	JOIN Region r ON r.RegionID = t.RegionID
	WHERE (o.OrderDate BETWEEN '1997-11-01' AND '1998-04-30') AND (RegionDescription = 'Eastern')
	GROUP BY t.TerritoryDescription)

SELECT 
	*
	, 100.0 * sum_sales / (SELECT SUM(sum_sales) FROM territory_sales) AS '%_sales'
	, 100.0 * SUM(sum_sales) OVER(ORDER BY sum_sales DESC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) / (SELECT SUM(sum_sales) FROM territory_sales) as '%_cumsum_sales'
FROM territory_sales
;

-- pareto category name on sales in eastern region
-- category name in eastern with the highest sales on Nov 97 to Apr 98 period
WITH category_sales AS
	(SELECT
		c.CategoryName
		, SUM(od.UnitPrice*od.Quantity) as 'sum_sales'
	FROM Orders o	
	JOIN [Order Details] od ON o.OrderID = od.OrderID
	JOIN Products p ON od.ProductID = p.ProductID
	JOIN Categories c ON p.CategoryID = c.CategoryID
	JOIN Employees e ON e.EmployeeID = o.EmployeeID
	JOIN EmployeeTerritories et ON et.EmployeeID = o.EmployeeID
	JOIN Territories t ON et.TerritoryID = t.TerritoryID
	JOIN Region r ON r.RegionID = t.RegionID
	WHERE (o.OrderDate BETWEEN '1997-11-01' AND '1998-04-30') AND (RegionDescription = 'Eastern')
	GROUP BY c.CategoryName)

SELECT 
	*
	, 100.0 * sum_sales / (SELECT SUM(sum_sales) FROM category_sales) AS '%_sales'
	, 100.0 * SUM(sum_sales) OVER(ORDER BY sum_sales DESC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) / (SELECT SUM(sum_sales) FROM category_sales) as '%_cumsum_sales'
FROM category_sales
;

-- pareto category name on sales in eastern region
-- product name in eastern with the highest sales on Nov 97 to Apr 98 period
WITH product_sales AS
	(SELECT
		p.ProductName
		, SUM(od.UnitPrice*od.Quantity) as 'sum_sales'
	FROM Orders o	
	JOIN [Order Details] od ON o.OrderID = od.OrderID
	JOIN Products p ON od.ProductID = p.ProductID
	JOIN Categories c ON p.CategoryID = c.CategoryID
	JOIN EmployeeTerritories et ON et.EmployeeID = o.EmployeeID
	JOIN Territories t ON et.TerritoryID = t.TerritoryID
	JOIN Region r ON r.RegionID = t.RegionID
	WHERE (o.OrderDate BETWEEN '1997-11-01' AND '1998-04-30') AND (RegionDescription = 'Eastern')
	GROUP BY p.ProductName)

SELECT 
	*
	, 100.0 * sum_sales / (SELECT SUM(sum_sales) FROM product_sales) AS '%_sales'
	, 100.0 * SUM(sum_sales) OVER(ORDER BY sum_sales DESC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) / (SELECT SUM(sum_sales) FROM product_sales) as '%_cumsum_sales'
FROM product_sales
;