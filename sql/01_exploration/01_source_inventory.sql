/* RetailTraining | 01 / 03
   Purpose: understand the available source tables and data types.
   Read-only; select the RetailTraining database in SSMS first.
*/
USE RetailTraining;
GO

SELECT TABLE_SCHEMA, TABLE_NAME
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA = 'dbo'
  AND TABLE_NAME IN ('Orders', 'OrderLines_staging', 'Products_staging')
ORDER BY TABLE_NAME;

SELECT TABLE_NAME, COLUMN_NAME, DATA_TYPE, CHARACTER_MAXIMUM_LENGTH
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'dbo'
  AND TABLE_NAME IN ('Orders', 'OrderLines_staging', 'Products_staging')
ORDER BY TABLE_NAME, ORDINAL_POSITION;

SELECT 'OrderLines_staging' AS SourceTable, COUNT(*) AS RowCount
FROM dbo.OrderLines_staging
UNION ALL
SELECT 'Products_staging', COUNT(*) FROM dbo.Products_staging
UNION ALL
SELECT 'Orders', COUNT(*) FROM dbo.Orders;

SELECT TOP (12) OrderLineID, OrderID, ProductID, Quantity, UnitPrice, DiscountPct
FROM dbo.OrderLines_staging
ORDER BY OrderLineID;

SELECT TOP (12) ProductID, ProductName, Category, UnitCost, ListPrice, Active
FROM dbo.Products_staging
ORDER BY ProductID;
