/* RetailTraining | 03 / 04
   Compare your executed results to the reference training dataset.
   The status counts and numeric totals below were checked separately against
   the original workbook; they are not an assertion this file ran on SQL Server.
*/
USE RetailTraining;
GO

-- A row-grain check should return one result: 68 total, 68 distinct keys.
SELECT COUNT(*) AS TotalRows,
       COUNT(DISTINCT SalesLineKey) AS DistinctSalesLineKeys,
       COUNT(DISTINCT CASE WHEN SalesLineKey IS NULL THEN NULL ELSE SalesLineKey END)
           AS NonNullDistinctSalesLineKeys,
       SUM(CASE WHEN OrderID IS NULL OR OrderLineID IS NULL THEN 1 ELSE 0 END)
           AS MissingKeyComponents
FROM dbo.vw_Sales_PowerBI;

-- Expected in this dataset: OK=63, NonPositiveQuantity=2,
-- OutOfRangeDiscount=2, InvalidQuantity=1.
SELECT RevenueQualityStatus,
       COUNT(*) AS NumberOfLines
FROM dbo.vw_Sales_PowerBI
GROUP BY RevenueQualityStatus
ORDER BY NumberOfLines DESC, RevenueQualityStatus;

-- Every order/line combination should be unique. Expected zero rows.
SELECT OrderID, OrderLineID, COUNT(*) AS NumberOfRecords
FROM dbo.vw_Sales_PowerBI
GROUP BY OrderID, OrderLineID
HAVING COUNT(*) > 1;

-- Reference values: Gross=10851.15; Net=10712.9215;
-- Cost=5181.85; Margin=5531.0715; Undated net=1299.00.
SELECT SUM(GrossRevenue) AS GrossRevenue,
       SUM(NetRevenue) AS NetRevenue,
       SUM(TotalCost) AS TotalCost,
       SUM(GrossMargin) AS GrossMargin,
       SUM(CASE WHEN OrderDate IS NULL THEN NetRevenue ELSE 0 END)
           AS UndatedNetRevenue
FROM dbo.vw_Sales_PowerBI;

-- Known L064 key reuse is legitimate: expected two different order keys.
SELECT SalesLineKey, OrderID, OrderLineID, ProductID,
       QuantityClean, UnitPriceClean, GrossRevenue, NetRevenue
FROM dbo.vw_Sales_PowerBI
WHERE OrderLineID = 'L064'
ORDER BY OrderID;

-- Check that joins have not inflated revenue by multiplying raw rows.
SELECT (SELECT COUNT(*) FROM dbo.OrderLines_staging) AS RawSalesLineRows,
       (SELECT COUNT(*) FROM dbo.vw_Sales_PowerBI) AS AnalyticalSalesLineRows;
