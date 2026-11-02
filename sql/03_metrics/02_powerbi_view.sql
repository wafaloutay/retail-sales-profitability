/* RetailTraining | 03 / 02
   Final flat fact view for Power BI (18 columns).
   Use OrderID + OrderLineID as the composite key; L064 occurs twice.
*/
USE RetailTraining;
GO

CREATE OR ALTER VIEW dbo.vw_Sales_PowerBI
AS
SELECT
    CONCAT(OrderID, '-', OrderLineID) AS SalesLineKey,
    OrderLineID, OrderID, ProductID,
    QuantityClean, UnitPriceClean, DiscountRateClean,
    ProductName, Category, UnitCostClean,
    OrderDate, OrderStatus, NumberOfOrderRecords,
    RevenueQualityStatus,
    GrossRevenue, NetRevenue, TotalCost, GrossMargin
FROM dbo.vw_Sales_Analysis;
GO

SELECT TOP (15) *
FROM dbo.vw_Sales_PowerBI
ORDER BY SalesLineKey;
