/* RetailTraining | 03 / 03
   Read-only business analysis. Only calculated, eligible sales lines have
   non-null revenue. Returns and cancellations have NOT been netted out.
*/
USE RetailTraining;
GO

-- Revenue, margin, and selected-line coverage across the entire dataset.
SELECT COUNT(*) AS TotalSalesLines,
       SUM(CASE WHEN RevenueQualityStatus = 'OK' THEN 1 ELSE 0 END) AS ValidSalesLines,
       SUM(CASE WHEN RevenueQualityStatus <> 'OK' THEN 1 ELSE 0 END) AS FlaggedSalesLines,
       SUM(GrossRevenue) AS TotalGrossRevenue,
       SUM(NetRevenue) AS TotalNetRevenue,
       SUM(TotalCost) AS TotalCost,
       SUM(GrossMargin) AS TotalGrossMargin,
       CAST(100.0 * SUM(GrossMargin) / NULLIF(SUM(NetRevenue), 0)
            AS DECIMAL(10, 2)) AS MarginRatePct
FROM dbo.vw_Sales_PowerBI;

-- Revenue and gross margin by category.
SELECT Category,
       COUNT(CASE WHEN RevenueQualityStatus = 'OK' THEN 1 END) AS ValidSalesLines,
       SUM(CASE WHEN RevenueQualityStatus = 'OK' THEN QuantityClean END) AS TotalUnitsSold,
       SUM(NetRevenue) AS TotalNetRevenue,
       SUM(GrossMargin) AS TotalGrossMargin,
       CAST(100.0 * SUM(GrossMargin) / NULLIF(SUM(NetRevenue), 0)
            AS DECIMAL(10, 2)) AS MarginRatePct
FROM dbo.vw_Sales_PowerBI
WHERE RevenueQualityStatus = 'OK'
GROUP BY Category
ORDER BY TotalGrossMargin DESC;

-- Product comparison: high unit volume does not imply high gross margin.
SELECT ProductID, ProductName, Category,
       SUM(QuantityClean) AS TotalUnitsSold,
       SUM(NetRevenue) AS TotalNetRevenue,
       SUM(GrossMargin) AS TotalGrossMargin,
       CAST(100.0 * SUM(GrossMargin) / NULLIF(SUM(NetRevenue), 0)
            AS DECIMAL(10, 2)) AS MarginRatePct
FROM dbo.vw_Sales_PowerBI
WHERE RevenueQualityStatus = 'OK'
GROUP BY ProductID, ProductName, Category
ORDER BY TotalGrossMargin DESC;

-- Quantify revenue with no date for time-based visuals.
SELECT SUM(NetRevenue) AS UndatedNetRevenue
FROM dbo.vw_Sales_PowerBI
WHERE RevenueQualityStatus = 'OK' AND OrderDate IS NULL;

-- The trend must exclude undated records *only from the monthly chart*.
SELECT CONVERT(CHAR(7), OrderDate, 120) AS YearMonth,
       SUM(NetRevenue) AS MonthlyNetRevenue
FROM dbo.vw_Sales_PowerBI
WHERE RevenueQualityStatus = 'OK' AND OrderDate IS NOT NULL
GROUP BY CONVERT(CHAR(7), OrderDate, 120)
ORDER BY YearMonth;
