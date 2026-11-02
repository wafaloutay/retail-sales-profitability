/* RetailTraining | 03 / 03
   Purpose: flag raw data problems without deleting source records.
*/
USE RetailTraining;
GO

-- Nulls, blanks, malformed quantities, zeros and negatives.
SELECT OrderLineID, OrderID, ProductID, Quantity
FROM dbo.OrderLines_staging
WHERE Quantity IS NULL
   OR LTRIM(RTRIM(CONVERT(NVARCHAR(100), Quantity))) = ''
   OR TRY_CONVERT(INT, LTRIM(RTRIM(CONVERT(NVARCHAR(100), Quantity)))) <= 0
   OR TRY_CONVERT(INT, LTRIM(RTRIM(CONVERT(NVARCHAR(100), Quantity)))) IS NULL;
-- 'one' and 'two' appear here; see the documented cleaning rules.

-- Discount and price formatting must be inspected before arithmetic.
SELECT DISTINCT UnitPrice, DiscountPct
FROM dbo.OrderLines_staging
ORDER BY UnitPrice, DiscountPct;

-- Missing direct costs may block margin calculation (not necessarily revenue).
SELECT ProductID, ProductName, UnitCost
FROM dbo.Products_staging
WHERE UnitCost IS NULL
   OR NULLIF(LTRIM(RTRIM(CONVERT(NVARCHAR(100), UnitCost))), '') IS NULL;

-- Inspect missing or unparseable dates, plus duplicate/conflicting order states.
SELECT OrderID, OrderDate, OrderStatus
FROM dbo.Orders
WHERE OrderDate IS NULL
   OR LTRIM(RTRIM(CONVERT(NVARCHAR(100), OrderDate))) = ''
   OR LOWER(LTRIM(RTRIM(CONVERT(NVARCHAR(100), OrderDate)))) = 'not provided'
ORDER BY OrderID;

-- Unmatched order keys after trimming: use LEFT JOIN so missing parents remain visible.
SELECT ol.OrderLineID, ol.OrderID, ol.ProductID
FROM dbo.OrderLines_staging AS ol
LEFT JOIN (SELECT DISTINCT UPPER(LTRIM(RTRIM(OrderID))) AS OrderID
           FROM dbo.Orders) AS o
  ON UPPER(LTRIM(RTRIM(ol.OrderID))) = o.OrderID
WHERE o.OrderID IS NULL;
