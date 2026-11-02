/* RetailTraining | 02 / 03
   Purpose: validate candidate identifiers BEFORE deduplicating.
   P010 has duplicate product records. L064 is reused across two orders:
   both L064 transactions must be retained.
*/
USE RetailTraining;
GO

-- Product master key: should identify one product.
SELECT UPPER(LTRIM(RTRIM(ProductID))) AS ProductID,
       COUNT(*) AS NumberOfRecords
FROM dbo.Products_staging
GROUP BY UPPER(LTRIM(RTRIM(ProductID)))
HAVING COUNT(*) > 1;

-- Inspect conflicting product attributes before selecting a canonical record.
SELECT ProductID, ProductName, Category, UnitCost, ListPrice, Active
FROM dbo.Products_staging
WHERE UPPER(LTRIM(RTRIM(ProductID))) = 'P010';

-- OrderLineID alone is not sufficient as a unique key.
SELECT OrderLineID, COUNT(*) AS NumberOfRecords
FROM dbo.OrderLines_staging
GROUP BY OrderLineID
HAVING COUNT(*) > 1;

SELECT OrderLineID, OrderID, ProductID, Quantity, UnitPrice, DiscountPct
FROM dbo.OrderLines_staging
WHERE OrderLineID = 'L064';

-- The pair is the intended sales-line grain.
SELECT UPPER(LTRIM(RTRIM(OrderID))) AS OrderID,
       UPPER(LTRIM(RTRIM(OrderLineID))) AS OrderLineID,
       COUNT(*) AS NumberOfRecords
FROM dbo.OrderLines_staging
GROUP BY UPPER(LTRIM(RTRIM(OrderID))),
         UPPER(LTRIM(RTRIM(OrderLineID)))
HAVING COUNT(*) > 1;

-- Orders can be duplicated, even when the sales-line grain is unique.
SELECT UPPER(LTRIM(RTRIM(OrderID))) AS OrderID,
       COUNT(*) AS NumberOfOrderRecords
FROM dbo.Orders
GROUP BY UPPER(LTRIM(RTRIM(OrderID)))
HAVING COUNT(*) > 1;
