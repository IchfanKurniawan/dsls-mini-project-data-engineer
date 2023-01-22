--Untuk mereview kembali kemampuan dasar query, Anda diminta untuk dapat mengerjakan soal ini terlebih dahulu :

USE Northwind;

--1. Tulis query untuk mendapatkan jumlah customer tiap bulan yang melakukan order pada tahun 1997.
SELECT
	DATEPART(MONTH, OrderDate) AS month
	, COUNT(CustomerID) AS num_customer
FROM Orders
WHERE OrderDate BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY DATEPART(MONTH, OrderDate)
;

--2. Tulis query untuk mendapatkan nama employee yang termasuk Sales Representative.
SELECT
	CONCAT(FirstName, ' ', LastName) AS Name
FROM Employees
WHERE Title = 'Sales Representative'
;

--3. Tulis query untuk mendapatkan top 5 nama produk yang quantitynya paling banyak diorder pada bulan Januari 1997.
SELECT
	p.ProductName
	, SUM(d.Quantity) as tot_quantity
FROM Orders o
JOIN [Order Details] d ON o.OrderID = d.OrderID
JOIN Products p ON d.ProductID = p.ProductID
WHERE OrderDate BETWEEN '1997-01-01' AND '1997-01-31'
GROUP BY p.ProductName
ORDER BY SUM(d.Quantity) DESC
OFFSET 0 ROWS 
FETCH NEXT 5 ROWS ONLY;
;

--4. Tulis query untuk mendapatkan nama company yang melakukan order Chai pada bulan Juni 1997.
SELECT 
	DISTINCT c.CompanyName
FROM Orders o
JOIN [Order Details] d ON o.OrderID = d.OrderID
JOIN Products p ON d.ProductID = p.ProductID
JOIN Customers c ON o.CustomerID = c.CustomerID
WHERE (ProductName = 'Chai') AND 
		(OrderDate BETWEEN '1997-06-01' AND '1997-06-30')
ORDER BY 1
;

--5. Tulis query untuk mendapatkan jumlah OrderID yang pernah melakukan sales (unit_price dikali quantity) <=100, 100<x<=250, 250<x<=500, dan >500.
WITH sales_table(OrderID, sales) AS(
	SELECT
		OrderID
		, SUM(UnitPrice*Quantity)
	FROM [Order Details]
	GROUP BY OrderID)

SELECT
	COUNT(CASE WHEN sales<=100 THEN OrderID ELSE NULL END) AS 'sales<=100'
	, COUNT(CASE WHEN (sales>100) AND (sales<=250) THEN OrderID ELSE NULL END) AS '100< sales <=250'
	, COUNT(CASE WHEN (sales>250) AND (sales<=500) THEN OrderID ELSE NULL END) AS '250< sales <=500'
	, COUNT(CASE WHEN sales>500 THEN OrderID ELSE NULL END) AS 'sales>500'
FROM sales_table
;

--6. Tulis query untuk mendapatkan Company name yang melakukan sales di atas 500 pada tahun 1997.
WITH sales_table(OrderID, sales) AS(
	SELECT
		OrderID
		, SUM(UnitPrice*Quantity)
	FROM [Order Details]
	GROUP BY OrderID)

SELECT
	DISTINCT CompanyName
FROM sales_table s
JOIN Orders o ON s.OrderID = o.OrderID
JOIN Customers c ON o.CustomerID = c.CustomerID
WHERE (sales>500) AND (OrderDate BETWEEN '1997-01-01' AND '1997-12-31')
;


--7. Tulis query untuk mendapatkan nama produk yang merupakan Top 5 sales tertinggi tiap bulan di tahun 1997.
-- month | product | rank | (output looks like)
WITH sales_product(month, ProductName, sales, ranking) AS(
	SELECT
		MONTH(o.OrderDate)
		, ProductName
		, SUM(d.UnitPrice*d.Quantity)
		, ROW_NUMBER() OVER(PARTITION BY MONTH(o.OrderDate) ORDER BY SUM(d.UnitPrice*d.Quantity) DESC)
	FROM Orders o
	JOIN [Order Details] d ON o.OrderID = d.OrderID
	JOIN Products p ON d.ProductID = p.ProductID
	WHERE OrderDate BETWEEN '1997-01-01' AND '1997-12-31'
	GROUP BY MONTH(o.OrderDate), ProductName)

SELECT *
FROM sales_product
WHERE ranking <= 5
ORDER BY 'month', ranking
;

--8. Buatlah view untuk melihat Order Details yang berisi OrderID, ProductID, ProductName, UnitPrice, Quantity, Discount, Harga setelah diskon.

USE Northwind;

-- creating the view
CREATE VIEW v_order_details(OrderID, ProductID, ProductName, UnitPrice, Quantity, Discount, discounted_price)
AS
	SELECT
		o.OrderID
		, o.ProductID
		, ProductName
		, o.UnitPrice
		, o.Quantity
		, o.Discount
		, (1.0 - o.Discount)*o.UnitPrice
	FROM [Order Details] o
	JOIN Products p ON o.ProductID = p.ProductID
;

-- checking the view
SELECT *
FROM v_order_details;



-- 9. Buatlah procedure Invoice untuk memanggil CustomerID, CustomerName, OrderID, OrderDate, RequiredDate, ShippedDate jika terdapat inputan CustomerID tertentu.

-- Create the procedure
 CREATE PROCEDURE pr_invoice (@cust_id AS nchar(5))
 AS
 BEGIN
	SELECT
		o.CustomerID, 
		c.ContactName, 
		o.OrderID, 
		o.OrderDate, 
		o.RequiredDate, 
		o.ShippedDate
	FROM Orders o
	JOIN Customers c ON o.CustomerID = c.CustomerID
	WHERE o.CustomerID = @cust_id
END
;

-- Check the procedure
EXECUTE pr_invoice @cust_id = 'TOMSP';
EXECUTE pr_invoice @cust_id = 'VICTE';